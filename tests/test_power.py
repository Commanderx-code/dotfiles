"""restore-power installs the turbo cap unit and picks the balanced profile without touching the system."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'home-manager/scripts/restore-power.sh'
SOURCE = ROOT / 'power/cpu-turbo-cap.service'


class RestorePowerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='restore-power-'))
        self.addCleanup(shutil.rmtree, self.tmp)
        binaries = self.tmp / 'bin'
        binaries.mkdir()
        self.log = self.tmp / 'calls.log'
        # sudo runs its command as this user; systemctl and powerprofilesctl record
        # their calls, and powerprofilesctl reports the profile kept in a file.
        (binaries / 'sudo').write_text('#!/bin/sh\nexec "$@"\n')
        (binaries / 'systemctl').write_text('#!/bin/sh\necho "systemctl $*" >> "$CALL_LOG"\n')
        (binaries / 'powerprofilesctl').write_text(
            '#!/bin/sh\necho "powerprofilesctl $*" >> "$CALL_LOG"\n'
            'case "$1" in get) cat "$PROFILE_FILE";; set) echo "$2" > "$PROFILE_FILE";; esac\n')
        for path in binaries.iterdir():
            path.chmod(0o755)
        self.units = self.tmp / 'etc/systemd/system'
        self.pstate = self.tmp / 'intel_pstate'
        self.pstate.mkdir()
        (self.pstate / 'max_perf_pct').write_text('80\n')
        self.profile = self.tmp / 'profile'
        self.profile.write_text('performance\n')
        self.env = dict(os.environ, PATH=f'{binaries}:{os.environ["PATH"]}', DOTFILES_DIR=str(ROOT),
                        SYSTEMD_SYSTEM_DIR=str(self.units), INTEL_PSTATE_DIR=str(self.pstate),
                        CALL_LOG=str(self.log), PROFILE_FILE=str(self.profile))

    def run_script(self, *args):
        return subprocess.run(['bash', str(SCRIPT), *args], env=self.env, capture_output=True, text=True, check=True)

    def test_unit_is_installed_enabled_and_profile_balanced(self):
        result = self.run_script()
        self.assertEqual((self.units / 'cpu-turbo-cap.service').read_text(), SOURCE.read_text())
        self.assertEqual(self.log.read_text().splitlines(), [
            'systemctl daemon-reload',
            'systemctl enable --now cpu-turbo-cap.service',
            'powerprofilesctl get',
            'powerprofilesctl set balanced',
        ])
        self.assertEqual(self.profile.read_text(), 'balanced\n')
        self.assertIn('Turbo cap in effect: max_perf_pct=80', result.stdout)
        self.assertEqual(result.stderr, '')
        # A second run changes nothing and says so.
        result = self.run_script()
        self.assertIn('already current', result.stdout)
        self.assertIn('already balanced', result.stdout)

    def test_a_machine_without_intel_pstate_is_told_not_failed(self):
        shutil.rmtree(self.pstate)
        result = self.run_script()
        self.assertIn('no intel_pstate driver', result.stderr)
        self.assertTrue((self.units / 'cpu-turbo-cap.service').is_file())
        with self.assertRaises(subprocess.CalledProcessError):
            self.run_script('now')

    def test_the_unit_caps_turbo_only_where_intel_pstate_exists(self):
        text = SOURCE.read_text()
        self.assertIn('ConditionPathExists=/sys/devices/system/cpu/intel_pstate/max_perf_pct', text)
        self.assertIn("echo 80 > /sys/devices/system/cpu/intel_pstate/max_perf_pct", text)
        self.assertIn('WantedBy=multi-user.target', text)


if __name__ == '__main__':
    unittest.main()
