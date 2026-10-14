import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('update_terminal_tools', ROOT / 'scripts/update-terminal-tools.py')
tools = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tools)

PINS = '''  one = binary {
    version = "1.2.3";
    url = "https://github.com/owner/one/releases/download/v1.2.3/one-linux.tar.gz";
    sha256 = "%s";
  };
  two = binary {
    version = "0.9.0";
    url = "https://github.com/owner/two/releases/download/v0.9.0/two.gz";
    sha256 = "%s";
  };
  three = {
    version = "0.3.0";
    url = "https://github.com/owner/three/releases/download/three-v0.3.0/three";
    sha256 = "%s";
  };
''' % ('a' * 64, 'b' * 64, 'd' * 64)
CURRENT = {'owner/one': 'v1.2.3', 'owner/two': 'v0.9.0', 'owner/three': 'three-v0.3.0'}


class TerminalToolPinTests(unittest.TestCase):
    def test_only_a_tool_with_a_newer_release_is_rewritten(self):
        downloads = []

        def digest(url):
            downloads.append(url)
            return 'c' * 64

        text, changes = tools.update(PINS, dict(CURRENT, **{'owner/one': 'v1.3.0'}).get, digest)
        self.assertEqual(changes, ['one 1.2.3 -> 1.3.0'])
        self.assertEqual(downloads, ['https://github.com/owner/one/releases/download/v1.3.0/one-linux.tar.gz'])
        self.assertIn('version = "1.3.0";\n    url = "' + downloads[0] + '";\n    sha256 = "' + 'c' * 64 + '";', text)
        # The current tool keeps its version, link and hash.
        self.assertEqual(text.split('two = binary')[1], PINS.split('two = binary')[1])

    def test_a_prefixed_release_tag_keeps_its_prefix(self):
        text, changes = tools.update(PINS, dict(CURRENT, **{'owner/three': 'three-v0.4.0'}).get, lambda url: 'c' * 64)
        self.assertEqual(changes, ['three 0.3.0 -> 0.4.0'])
        self.assertIn('version = "0.4.0";\n    url = "https://github.com/owner/three/releases/download/three-v0.4.0/three";', text)
        # A tag that drops the pinned prefix is not taken for a release of it.
        with self.assertRaises(ValueError):
            tools.update(PINS, dict(CURRENT, **{'owner/three': 'v0.4.0'}).get, self.fail)

    def test_current_pins_are_left_alone_without_downloading(self):
        text, changes = tools.update(PINS, CURRENT.get, self.fail)
        self.assertEqual((text, changes), (PINS, []))

    def test_unexpected_tags_and_download_hosts_are_refused(self):
        for tag in ('latest', 'v1.0; rm -rf', '1.0.0', None):
            with self.subTest(tag=tag), patch.object(tools, 'api', return_value={'tag_name': tag}), \
                    self.assertRaises(ValueError):
                tools.update(PINS)
        with self.assertRaises(ValueError):
            tools.digest('https://example.invalid/file')
        with self.assertRaises(ValueError):
            tools.update('nothing pinned here')

    def test_every_tool_in_the_real_file_is_recognised(self):
        pins = [pin for path in tools.PINS for pin in tools.PIN.finditer((ROOT / path).read_text())]
        self.assertEqual(sorted(pin['repository'].split('/')[1] for pin in pins),
                         ['cassette', 'harpoon', 'netwatch', 'tfm-tui', 'zesh', 'zjstatus'])
