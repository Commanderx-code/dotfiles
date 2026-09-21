"""GitHub checks shared by the import job and the local repository updater."""
import json
import re
import subprocess
from urllib.parse import urlencode

OWNER = 'Commanderx-code'
SOURCES = ('Myfish', 'dotfiles', 'commander-toolbox')


def api(path):
    return json.loads(subprocess.check_output(['gh', 'api', path], text=True, timeout=45))


def revision(value):
    if not isinstance(value, str) or not re.fullmatch('[0-9a-f]{40}', value):
        raise ValueError('Invalid Git revision')
    return value


def check_runs(source, head, request=api):
    if source not in SOURCES:
        raise ValueError('Unknown source repository')
    repo = f'{OWNER}/{source}'
    query = urlencode({'branch': 'main', 'head_sha': revision(head), 'per_page': 100})
    runs = request(f'repos/{repo}/actions/workflows/check.yml/runs?{query}')['workflow_runs']
    return [run for run in runs if run['head_sha'] == head
            and run['event'] in ('push', 'workflow_dispatch') and run['head_branch'] == 'main'
            and run['head_repository']['full_name'] == repo]


def tested(source, head, request=api):
    runs = check_runs(source, head, request)
    latest = max(runs, key=lambda r: (r['id'], r.get('run_attempt', 1)), default=None)
    return bool(latest and latest['status'] == 'completed' and latest['conclusion'] == 'success')


def eligible(source, request=api):
    head = revision(request(f'repos/{OWNER}/{source}/commits/main')['sha'])
    return head if tested(source, head, request) else None
