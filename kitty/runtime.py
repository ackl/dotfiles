"""Optional theme and portable socket path, using Kitty's built-in Python."""
import os
import tempfile
from pathlib import Path

state_dir = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
theme = state_dir / "omarchy/current/theme/kitty.conf"
if theme.is_file():
    print(f"include {theme}")

runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir()
print(f"listen_on unix:{runtime_dir}/omarchy-kitty-{{kitty_pid}}")
