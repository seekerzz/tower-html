#!/usr/bin/env python3
"""
P2阶段任务批量提交脚本
用于并行提交 P2-02, P2-03, P2-04 三个任务
"""

import subprocess
import sys
import argparse

def submit_task(prompt_file: str, task_id: str, wait: bool = False):
    """提交单个 Jules 任务"""
    cmd = [
        "python", "docs/jules_prompts/submit_jules_task.py",
        "--prompt", f"docs/jules_prompts/{prompt_file}",
        "--task-id", task_id
    ]

    if wait:
        cmd.append("--wait")

    print(f"\n{'='*60}")
    print(f"提交任务: {task_id}")
    print(f"命令: {' '.join(cmd)}")
    print(f"{'='*60}\n")

    try:
        result = subprocess.run(cmd, check=True, capture_output=False, text=True)
        print(f"[OK] {task_id} 提交成功")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {task_id} 提交失败: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="提交 P2 阶段 Jules 任务")
    parser.add_argument("--wait", action="store_true", help="等待任务完成")
    parser.add_argument("--tasks", type=str, default="all", help="指定任务: all, P2-02, P2-03, P2-04")
    args = parser.parse_args()

    # P2 任务定义
    p2_tasks = {
        "P2-02": {
            "file": "P2_02_charm_control_system.md",
            "desc": "魅惑/控制敌人系统完善"
        },
        "P2-03": {
            "file": "P2_03_wolf_devour_system.md",
            "desc": "狼的吞噬继承系统完善"
        },
        "P2-04": {
            "file": "P2_04_medusa_petrify_system.md",
            "desc": "美杜莎石化与石块系统"
        }
    }

    # 确定要执行的任务
    if args.tasks == "all":
        tasks_to_run = list(p2_tasks.keys())
    else:
        tasks_to_run = [t.strip() for t in args.tasks.split(",")]

    print("="*60)
    print("P2 阶段 Jules 任务批量提交")
    print("="*60)
    print(f"\n准备提交的任务:")
    for task_id in tasks_to_run:
        if task_id in p2_tasks:
            print(f"  - {task_id}: {p2_tasks[task_id]['desc']}")

    print(f"\n等待模式: {'开启' if args.wait else '关闭'}")
    print("\n注意: 请确保已设置 JULES_API_KEY 环境变量或在 docs/secrets/.env 中配置")

    # 提交任务
    success_count = 0
    for task_id in tasks_to_run:
        if task_id in p2_tasks:
            if submit_task(p2_tasks[task_id]["file"], task_id, args.wait):
                success_count += 1
        else:
            print(f"[WARN] 未知任务: {task_id}")

    print(f"\n{'='*60}")
    print(f"提交完成: {success_count}/{len(tasks_to_run)} 成功")
    print(f"{'='*60}")

    return 0 if success_count == len(tasks_to_run) else 1

if __name__ == "__main__":
    sys.exit(main())
