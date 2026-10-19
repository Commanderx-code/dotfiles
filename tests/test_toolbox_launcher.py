"""Exercise the HelixForge launcher against a local stand-in for the release downloads."""
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
LAUNCHER = ROOT / 'home-manager/scripts/toolbox-launcher.sh'
ASSET = 'helixforge-linux-x86_64'
# Reports $MACHINE as the processor.
UNAME = '''#!/bin/sh
[ "$1" = -m ] && echo "$MACHINE"
'''
# Serves files from $RELEASE by the URL's last component and logs each request.
CURL = '''#!/bin/sh
for argument in "$@"; do
    [ "$previous" = -o ] && output=$argument
    previous=$argument
done
name=${argument##*/}
printf '%s\\n' "$name" >> "$RELEASE/requests"
[ -f "$RELEASE/$name" ] || exit 22
cp "$RELEASE/$name" "$output"
'''


class ToolboxLauncherTests(unittest.TestCase):
    def setUp(self):
        fixture = tempfile.TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name)
        self.release = self.root / 'release'
        self.home = self.root / 'home'
        tools = self.root / 'tools'
        for directory in (self.release, self.home, tools):
            directory.mkdir()
        for name, body in (('curl', CURL), ('uname', UNAME)):
            (tools / name).write_text(body)
            (tools / name).chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), XDG_DATA_HOME=str(self.home / 'data'),
                        RELEASE=str(self.release), MACHINE='x86_64',
                        PATH=str(tools) + os.pathsep + os.environ['PATH'])
        self.installed = self.home / 'data/helixforge' / ASSET

    def publish(self, version, checksum=None, asset=ASSET):
        body = f'#!/bin/sh\necho "toolbox {version} $*"\n'.encode()
        (self.release / asset).write_bytes(body)
        checksum = checksum or hashlib.sha256(body).hexdigest()
        with (self.release / 'SHA256SUMS').open('a') as sums:
            sums.write(f'{checksum}  {asset}\n')
        (self.release / 'requests').write_text('')

    def launch(self, *arguments):
        return subprocess.run(['bash', str(LAUNCHER), *arguments], env=self.env, text=True, capture_output=True)

    def requests(self):
        return (self.release / 'requests').read_text().split()

    def test_downloads_once_then_follows_new_releases(self):
        self.publish('one')
        result = self.launch('--theme', 'compatible')
        self.assertEqual((result.returncode, result.stdout), (0, 'toolbox one --theme compatible\n'), result.stderr)
        self.assertEqual(self.requests(), ['SHA256SUMS', ASSET])
        (self.release / 'requests').write_text('')
        self.assertEqual(self.launch().stdout, 'toolbox one \n')
        self.assertEqual(self.requests(), ['SHA256SUMS'])
        self.publish('two')
        self.assertEqual(self.launch().stdout, 'toolbox two \n')
        self.assertEqual(list(self.installed.parent.iterdir()), [self.installed])

    def test_keeps_installed_copy_when_release_is_unusable(self):
        self.publish('one')
        self.launch()
        self.publish('tampered', checksum='0' * 64)
        result = self.launch()
        self.assertEqual((result.returncode, result.stdout), (0, 'toolbox one \n'))
        self.assertIn('did not match', result.stderr)
        for name in (ASSET, 'SHA256SUMS'):
            (self.release / name).unlink()
        result = self.launch()
        self.assertEqual((result.returncode, result.stdout), (0, 'toolbox one \n'))
        self.assertIn('using the installed copy', result.stderr)

    def test_takes_the_build_for_this_processor(self):
        self.publish('x86', asset=ASSET)
        self.publish('arm', asset='helixforge-linux-aarch64')
        self.env['MACHINE'] = 'aarch64'
        result = self.launch()
        self.assertEqual((result.returncode, result.stdout), (0, 'toolbox arm \n'), result.stderr)
        self.assertEqual(self.requests(), ['SHA256SUMS', 'helixforge-linux-aarch64'])
        self.assertEqual([path.name for path in self.installed.parent.iterdir()], ['helixforge-linux-aarch64'])

    def test_refuses_a_processor_without_a_build(self):
        self.publish('one')
        self.env['MACHINE'] = 'riscv64'
        result = self.launch()
        self.assertEqual(result.returncode, 1)
        self.assertIn('no build for this processor (riscv64)', result.stderr)
        self.assertEqual(self.requests(), [])

    def test_fails_clearly_without_a_download(self):
        (self.release / 'requests').write_text('')
        result = self.launch()
        self.assertEqual(result.returncode, 1)
        self.assertIn('not downloaded yet', result.stderr)

    def test_personal_launcher_takes_precedence(self):
        self.publish('one')
        personal = self.home / '.local/bin/helixforge'
        personal.parent.mkdir(parents=True)
        personal.write_text('#!/bin/sh\necho "personal $*"\n')
        personal.chmod(0o755)
        result = self.launch('--mouse')
        self.assertEqual((result.returncode, result.stdout), (0, 'personal --mouse\n'), result.stderr)
        self.assertEqual(self.requests(), [])


if __name__ == '__main__':
    unittest.main()
