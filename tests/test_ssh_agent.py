"""The SSH agent snippet stays silent on machines without an agent socket or key."""
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SNIPPET = ROOT / 'configs/fish/conf.d/ssh-agent.fish'


class SshAgentTests(unittest.TestCase):
    def setUp(self):
        fixture = tempfile.TemporaryDirectory()
        self.addCleanup(fixture.cleanup)
        self.root = Path(fixture.name)
        self.runtime = self.root / 'runtime'
        self.home = self.root / 'home'
        tools = self.root / 'tools'
        for directory in (self.runtime, self.home / '.ssh', tools):
            directory.mkdir(parents=True)
        # Reports an empty agent, and records what it was asked to load.
        ssh_add = tools / 'ssh-add'
        ssh_add.write_text(f'#!/bin/sh\n[ "$1" = -l ] && exit 1\necho "$@" >> "{self.root}/loaded"\n')
        ssh_add.chmod(0o755)
        self.env = {key: value for key, value in os.environ.items() if key != 'SSH_AUTH_SOCK'}
        self.env.update(HOME=str(self.home), XDG_RUNTIME_DIR=str(self.runtime),
                        PATH=str(tools) + os.pathsep + os.environ['PATH'])

    def source(self):
        result = subprocess.run(['fish', '--no-config', '-i', '-c', 'source "$argv[1]"; echo "sock=$SSH_AUTH_SOCK"',
                                 str(SNIPPET)], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        loaded = self.root / 'loaded'
        return result.stdout + result.stderr, loaded.read_text() if loaded.exists() else ''

    def listen(self):
        agent = socket.socket(socket.AF_UNIX)
        self.addCleanup(agent.close)
        agent.bind(str(self.runtime / 'ssh-agent.socket'))

    def test_silent_without_agent_socket(self):
        (self.home / '.ssh/id_ed25519').write_text('key')
        self.assertEqual(self.source(), ('sock=\n', ''))

    def test_socket_without_key_only_exports_it(self):
        self.listen()
        self.assertEqual(self.source(), (f'sock={self.runtime}/ssh-agent.socket\n', ''))

    def test_loads_key_into_empty_agent(self):
        self.listen()
        (self.home / '.ssh/id_ed25519').write_text('key')
        output, loaded = self.source()
        self.assertEqual(output, f'sock={self.runtime}/ssh-agent.socket\n')
        self.assertEqual(loaded, f'{self.home}/.ssh/id_ed25519\n')


if __name__ == '__main__':
    unittest.main()
