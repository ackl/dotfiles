"""Exercise lazy NVM wrappers without loading the user's shell configuration."""

from pathlib import Path
import os
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
NVM_SECTION = (REPO / "zshrc").read_text().split("# ---- lazy nvm", 1)[1]
NVM_SECTION = NVM_SECTION.split("\n", 1)[1].split("# ---- lazy jenv", 1)[0]


class NvmTests(unittest.TestCase):
    def run_zsh(self, script):
        with tempfile.TemporaryDirectory(prefix="dotfiles-nvm-") as directory:
            nvm_dir = Path(directory)
            # Model NVM's public deactivate operation, including failure.
            (nvm_dir / "nvm.sh").write_text('''
nvm() {
  if [[ $1 == deactivate ]]; then
    [[ $2 == --silent ]] || return 2
    [[ ${FAIL_DEACTIVATE:-0} == 0 ]] || return 42
    path=("${(@)path:#$NVM_BIN}")
    unset NVM_BIN NVM_INC
  fi
}
export NVM_BIN="$NVM_DIR/versions/node/v24/bin"
export NVM_INC="$NVM_DIR/versions/node/v24/include/node"
path=("$NVM_BIN" "${path[@]}")
''')
            env = dict(os.environ, NVM_DIR=directory)
            result = subprocess.run(
                ["zsh", "-f", "-c", NVM_SECTION + "\n" + script],
                env=env, text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_deactivate_preserves_later_path_changes_and_can_reload(self):
        self.run_zsh('''
nvm_on || exit 1
path=("/project/.venv/bin" "${path[@]}" "/extra/tools")
expected=("${(@)path:#$NVM_BIN}")
nvm_off || exit 2
[[ "$PATH" == "${(j.:.)expected}" ]] || exit 3
[[ -z ${NVM_BIN+x} && -z ${NVM_INC+x} ]] || exit 4
(( __NVM_LOADED == 0 )) || exit 5
nvm_off || exit 6
[[ "$PATH" == "${(j.:.)expected}" ]] || exit 7
nvm use default || exit 8
(( __NVM_LOADED == 1 )) || exit 9
nvm_off || exit 10
[[ "$PATH" == "${(j.:.)expected}" ]] || exit 11
''')

    def test_deactivate_failure_keeps_loaded_state(self):
        self.run_zsh('''
nvm_on || exit 1
before="$PATH"
FAIL_DEACTIVATE=1
nvm_off
[[ $? == 42 && "$PATH" == "$before" ]] || exit 2
(( __NVM_LOADED == 1 )) || exit 3
FAIL_DEACTIVATE=0
nvm_off || exit 4
''')


if __name__ == "__main__":
    unittest.main()
