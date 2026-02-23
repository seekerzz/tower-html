#!/usr/bin/env python3
"""
监控FIX任务状态
持续检查4个回归测试修复任务的状态
"""

import os
import sys
import time
import json
import requests
from pathlib import Path

# 加载 .env
env_path = Path(__file__).parent / "docs" / "secrets" / ".env"
if env_path.exists():
    with open(env_path, encoding='utf-8') as f:
        for line in f:
            if line.strip() and not line.startswith('#') and '=' in line:
                key, value = line.strip().split('=', 1)
                os.environ.setdefault(key, value)

API_KEY = os.getenv('JULES_API_KEY')
PROXY = os.getenv('HTTP_PROXY', 'http://127.0.0.1:10808')
API_URL = "https://jules.googleapis.com/v1alpha/sessions"

# FIX任务列表
FIX_TASKS = {
    "FIX-01": {"session": "3101655427339905152", "desc": "core_healed信号修复"},
    "FIX-02": {"session": "4448957128400382955", "desc": "get_units_in_cell_range方法"},
    "FIX-03": {"session": "15778006931107657755", "desc": "Vulture方法调用错误"},
    "FIX-04": {"session": "1235828679591241663", "desc": "召唤系统问题"}
}


def check_session(session_id: str) -> dict:
    """检查单个session状态"""
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY
    }
    proxies = {"http": PROXY, "https": PROXY} if PROXY else None

    try:
        resp = requests.get(
            f"{API_URL}/{session_id}",
            headers=headers,
            proxies=proxies,
            timeout=30
        )
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        return {"error": str(e)}


def format_status(state: str) -> str:
    """格式化状态显示"""
    colors = {
        "CREATED": "\033[93m",  # 黄色
        "RUNNING": "\033[94m",  # 蓝色
        "COMPLETED": "\033[92m",  # 绿色
        "FAILED": "\033[91m",  # 红色
        "ERROR": "\033[91m",
    }
    reset = "\033[0m"
    color = colors.get(state, "")
    return f"{color}{state:12}{reset}"


def main():
    print("=" * 70)
    print("FIX任务监控启动")
    print("=" * 70)
    print(f"任务: FIX-01, FIX-02, FIX-03, FIX-04")
    print(f"刷新间隔: 30秒")
    print("按 Ctrl+C 停止监控")
    print("=" * 70)

    completed_tasks = set()

    try:
        while len(completed_tasks) < len(FIX_TASKS):
            print(f"\n[{time.strftime('%H:%M:%S')}] 检查任务状态...")
            print("-" * 70)

            for task_id, info in FIX_TASKS.items():
                session_id = info["session"]
                result = check_session(session_id)

                if "error" in result:
                    status = f"ERROR: {result['error'][:30]}"
                else:
                    state = result.get('state', 'UNKNOWN')
                    status = format_status(state)

                    if state in ['COMPLETED', 'FAILED', 'ERROR']:
                        completed_tasks.add(task_id)

                url = f"https://jules.google.com/session/{session_id}"
                print(f"{task_id} | {info['desc'][:25]:25} | {status} | {url[:40]}")

            if len(completed_tasks) < len(FIX_TASKS):
                print(f"\n等待30秒后刷新... (已完成: {len(completed_tasks)}/{len(FIX_TASKS)})")
                time.sleep(30)
            else:
                print("\n" + "=" * 70)
                print("所有任务已完成!")
                print("=" * 70)
                break

    except KeyboardInterrupt:
        print("\n\n监控已停止")
        sys.exit(0)


if __name__ == "__main__":
    main()
