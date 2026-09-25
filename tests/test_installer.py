"""Exercise the real installer exclusively inside temporary HOME/XDG paths."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles tests ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.config = self.root / "config"
        self.state = self.root / "state"
        self.home.mkdir()
        self.config.mkdir()
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CONFIG_HOME=str(self.config), XDG_STATE_HOME=str(self.state))

    def install(self, *args, success=True):
        result = subprocess.run(
            # Use macOS's system Bash 3.2, even if Homebrew Bash is on PATH.
            ["/bin/bash", str(REPO / "link_configs.sh"), *map(str, args)],
            env=self.env, text=True, capture_output=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def backups(self):
        return sorted((self.state / "dotfiles" / "backups").glob("*"))

    def only_backup(self):
        backups = self.backups()
        self.assertEqual(len(backups), 1)
        return backups[0]

    def assert_link(self, target, source):
        self.assertTrue(target.is_symlink())
        self.assertEqual(target.resolve(), source.resolve())

    def test_replaces_and_restores_existing_directory_file_and_broken_symlink(self):
        git = self.config / "git"
        git.mkdir()
        (git / "personal").write_text("original directory")
        zsh = self.home / ".zshrc"
        zsh.write_text("original file")
        kitty = self.config / "kitty"
        kitty.symlink_to("missing-kitty")

        self.install("git", "zsh", "kitty")
        backup = self.only_backup()
        self.assert_link(git, REPO / "git")
        self.assert_link(zsh, REPO / "zshrc")
        self.assert_link(kitty, REPO / "kitty")
        self.assertEqual((backup / "git" / "personal").read_text(), "original directory")
        self.assertEqual((backup / "zshrc").read_text(), "original file")
        self.assertEqual(os.readlink(backup / "kitty"), "missing-kitty")

        self.install("--restore", backup)
        self.assertFalse(git.is_symlink())
        self.assertEqual((git / "personal").read_text(), "original directory")
        self.assertEqual(zsh.read_text(), "original file")
        self.assertEqual(os.readlink(kitty), "missing-kitty")

    def test_repeat_install_does_not_create_another_backup(self):
        self.install("git", "omarchy")
        backups = self.backups()
        self.install("git", "omarchy")
        self.assertEqual(self.backups(), backups)
        self.assert_link(self.config / "git", REPO / "git")

    def test_copy_mode_migrates_a_symlink_to_the_source(self):
        target = self.config / "omarchy" / "plugins" / "andrew.active-window"
        target.parent.mkdir(parents=True)
        source = REPO / "omarchy" / "plugins" / "andrew.active-window"
        target.symlink_to(source, target_is_directory=True)
        self.install("omarchy")
        self.assertTrue(target.is_dir())
        self.assertFalse(target.is_symlink())
        for original in source.rglob("*"):
            if original.is_file():
                self.assertEqual((target / original.relative_to(source)).read_bytes(), original.read_bytes())
        self.assert_link(self.only_backup() / "omarchy__plugins__andrew.active-window", source)

    def test_dry_run_makes_no_changes_or_backups(self):
        target = self.home / ".zshrc"
        target.write_text("keep me")
        self.install("--dry-run", "zsh", "omarchy")
        self.assertEqual(target.read_text(), "keep me")
        self.assertEqual(list(self.config.iterdir()), [])
        self.assertFalse(self.state.exists())

    def test_restore_removes_new_targets_and_preserves_post_install_edits(self):
        self.install("git")
        backup = self.only_backup()
        target = self.config / "git"
        target.unlink()
        target.mkdir()
        (target / "new-edit").write_text("keep this too")
        self.install("--restore", backup, "--dry-run")
        self.assertEqual((target / "new-edit").read_text(), "keep this too")
        self.assertEqual(list(backup.glob("restored-current*")), [])
        self.install("--restore", backup)
        self.assertFalse(os.path.lexists(target))
        saved = list(backup.glob("restored-current*/**/new-edit"))
        self.assertEqual(len(saved), 1)
        self.assertEqual(saved[0].read_text(), "keep this too")

    def test_failed_install_restores_the_original_target(self):
        target = self.config / "git"
        target.mkdir()
        (target / "personal").write_text("original")
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        fake_ln = bin_dir / "ln"
        fake_ln.write_text("#!/bin/sh\nexit 23\n")
        fake_ln.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]
        self.install("git", success=False)
        self.assertFalse(target.is_symlink())
        self.assertEqual((target / "personal").read_text(), "original")

    def test_interrupted_install_restores_the_original_target(self):
        target = self.config / "git"
        target.mkdir()
        (target / "personal").write_text("original")
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        fake_ln = bin_dir / "ln"
        # Terminate the installer after its backup but before the manifest record.
        fake_ln.write_text('#!/bin/sh\nkill -TERM "$PPID"\nexit 23\n')
        fake_ln.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]
        result = self.install("git", success=False)
        self.assertEqual(result.returncode, 143, result.stdout + result.stderr)
        self.assertFalse(target.is_symlink())
        self.assertEqual((target / "personal").read_text(), "original")
        backup = self.only_backup()
        self.assertEqual((backup / "manifest.tsv").read_text(), "dotfiles-backup-v1\n")
        self.assertFalse(os.path.lexists(backup / "git"))

    def test_repeated_restore_is_rejected_without_touching_current_files(self):
        target = self.config / "git"
        target.mkdir()
        (target / "personal").write_text("original")
        self.install("git")
        backup = self.only_backup()
        self.install("--restore", backup)
        (target / "personal").write_text("edited after restore")
        preserved = list(backup.glob("restored-current*"))

        self.install("--restore", backup, success=False)
        self.assertEqual((target / "personal").read_text(), "edited after restore")
        self.assertEqual(list(backup.glob("restored-current*")), preserved)

    def test_restore_validates_all_records_before_mutating_any_destination(self):
        target = self.config / "git"
        target.mkdir()
        (target / "personal").write_text("original")
        self.install("git")
        backup = self.only_backup()
        manifest = backup / "manifest.tsv"
        original_manifest = manifest.read_text()
        valid_record = original_manifest.splitlines()[1]
        outside = self.root / "unrecognized"
        outside.write_text("untouched")
        invalid_records = {
            "malformed": "not-a-valid-record",
            "unrecognized": "absent\tgit\t" + str(outside),
            "duplicate": valid_record,
        }

        for kind, invalid_record in invalid_records.items():
            with self.subTest(kind=kind):
                manifest.write_text(original_manifest + invalid_record + "\n")
                self.install("--restore", backup, success=False)
                self.assert_link(target, REPO / "git")
                self.assertEqual((backup / "git" / "personal").read_text(), "original")
                self.assertEqual(outside.read_text(), "untouched")
                self.assertEqual(list(backup.glob("restored-current*")), [])
                self.assertFalse((backup / "restored").exists())

    def test_failed_copy_preserves_partial_output_and_restores_original(self):
        target = self.config / "omarchy" / "plugins" / "andrew.active-window"
        target.mkdir(parents=True)
        (target / "personal").write_text("original")
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        fake_cp = bin_dir / "cp"
        fake_cp.write_text(
            '#!/bin/sh\n'
            'for destination do :; done\n'
            'mkdir -p "$destination"\n'
            'printf "unfinished copy" > "$destination/partial-file"\n'
            'exit 23\n'
        )
        fake_cp.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]

        self.install("omarchy", success=False)
        self.assertEqual((target / "personal").read_text(), "original")
        self.assertFalse((target / "partial-file").exists())
        partial = self.only_backup() / "omarchy__plugins__andrew.active-window.partial"
        self.assertEqual((partial / "partial-file").read_text(), "unfinished copy")
        self.assertFalse((self.config / "hypr" / "uk-mac.xkb").exists())

    def test_invalid_selection_is_rejected_before_changes(self):
        self.install("git", "unknown-config", success=False)
        self.assertEqual(list(self.config.iterdir()), [])
        self.assertFalse(self.state.exists())

    def test_linux_profile_can_be_previewed_and_installed(self):
        self.install("--linux", "--dry-run")
        self.assertEqual(list(self.config.iterdir()), [])
        self.assertFalse(self.state.exists())
        self.install("--linux")
        for name in ("nvim", "yazi", "git", "kitty"):
            self.assert_link(self.config / name, REPO / name)
        self.assert_link(self.home / ".zshrc", REPO / "zshrc")
        self.assertTrue((self.config / "omarchy" / "shell.json").is_file())
        self.assertFalse((self.home / ".skhdrc").exists())


if __name__ == "__main__":
    unittest.main()
