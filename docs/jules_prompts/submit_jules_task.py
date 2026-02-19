#!/usr/bin/env python3
"""
提交 Jules 任务 - 使用 requests 库
验证成功的版本

使用方法:
    python submit_jules_task.py --task-id P0-02 --prompt P0_02_taunt_aggro_system.md

环境变量:
    JULES_API_KEY - 从 https://jules.google.com/settings#api 获取
"""

import os
import sys
import json
import time
import requests
from pathlib import Path
from datetime import datetime

# 加载 .env
env_path = Path(__file__).parent / ".." / "secrets" / ".env"
if env_path.exists():
    with open(env_path, encoding='utf-8') as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                os.environ.setdefault(key, value)

API_KEY = os.getenv('JULES_API_KEY')
PROXY = os.getenv('HTTP_PROXY', 'http://127.0.0.1:10808')
API_URL = "https://jules.googleapis.com/v1alpha/sessions"


def submit_task(task_id: str, prompt_file: str, title: str = None):
    """Submit task to Jules"""

    if not API_KEY:
        print("Error: JULES_API_KEY not set")
        print("Set in docs/secrets/.env or export as environment variable")
        sys.exit(1)

    # Read prompt
    prompt_path = Path(prompt_file)
    if not prompt_path.is_absolute():
        prompt_path = Path(__file__).parent / prompt_path

    if not prompt_path.exists():
        print(f"Error: File not found {prompt_path}")
        sys.exit(1)

    with open(prompt_path, 'r', encoding='utf-8') as f:
        prompt_content = f.read()

    # Add task identifier
    prompt_content += f"\n\n## Task ID\n\nTask being executed: {task_id}\n"

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY
    }

    body = {
        "title": title or task_id,
        "prompt": prompt_content,
        "sourceContext": {
            "source": "sources/github/seekerzz/tower-html",
            "githubRepoContext": {"startingBranch": "main"}
        },
        "automationMode": "AUTO_CREATE_PR"
    }

    proxies = {"http": PROXY, "https": PROXY} if PROXY else None

    print("=" * 60)
    print(f"Submitting task: {task_id}")
    print("=" * 60)

    try:
        resp = requests.post(
            API_URL,
            json=body,
            headers=headers,
            proxies=proxies,
            timeout=30
        )
        resp.raise_for_status()
        result = resp.json()

        session_id = result.get('id')
        print(f"[OK] Success! Session ID: {session_id}")
        print(f"[OK] URL: https://jules.google.com/session/{session_id}")

        # Update progress
        update_progress(task_id, "submitted", f"Task submitted, Session: {session_id}")

        return session_id

    except Exception as e:
        print(f"[ERROR] {e}")
        sys.exit(1)


def update_progress(task_id: str, status: str, desc: str):
    """Update progress file"""
    progress_file = Path(__file__).parent / ".." / "progress.md"
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    content = ""
    if progress_file.exists():
        content = progress_file.read_text(encoding='utf-8')

    # Simple task line replacement
    lines = content.split('\n')
    new_lines = []
    found = False

    for line in lines:
        if f"| {task_id} " in line and line.startswith('|'):
            new_lines.append(f"| {task_id} | {status} | {desc} | {now} |")
            found = True
        else:
            new_lines.append(line)

    if not found:
        # Add to end of table
        for i, line in enumerate(new_lines):
            if line.startswith('| P0-') or line.startswith('| P1-') or line.startswith('| P2-'):
                new_lines.insert(i, f"| {task_id} | {status} | {desc} | {now} |")
                break

    progress_file.write_text('\n'.join(new_lines), encoding='utf-8')
    print(f"[OK] Progress updated: docs/progress.md")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--task-id', '-t', required=True)
    parser.add_argument('--prompt', '-p', required=True)
    parser.add_argument('--title', default=None)
    args = parser.parse_args()

    submit_task(args.task_id, args.prompt, args.title)
