#!/usr/bin/env python3
"""
Jules 批量任务提交脚本
用于并行提交多个任务到 Jules API

使用方法:
    # 提交所有 P0 任务
    python run_jules_batch.py --phase P0

    # 提交所有 P1 任务（6个组并行）
    python run_jules_batch.py --phase P1

    # 提交特定组
    python run_jules_batch.py --tasks P0-01,P0-02,P0-03,P0-04

    # 提交并等待所有任务完成
    python run_jules_batch.py --phase P1 --wait

参考:
    https://developers.google.com/jules/api
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from jules_client import JulesClient, JulesTaskManager
from concurrent.futures import ThreadPoolExecutor, as_completed
import argparse
from pathlib import Path


# 任务定义
TASKS = {
    # Phase 0: 基础系统 (必须串行)
    "P0-01": {
        "prompt": "P0_01_wolf_totem_soul_system.md",
        "title": "P0-01: 狼图腾魂魄系统",
        "description": "实现狼图腾核心机制——魂魄系统",
        "dependencies": [],
        "group": "P0"
    },
    "P0-04": {
        "prompt": "P0_04_bleed_lifesteal_system.md",
        "title": "P0-04: 流血吸血联动系统",
        "description": "实现蝙蝠图腾核心机制——流血吸血联动",
        "dependencies": [],
        "group": "P0"
    },
    "P0-02": {
        "prompt": "P0_02_taunt_aggro_system.md",
        "title": "P0-02: 嘲讽/仇恨系统",
        "description": "实现嘲讽/仇恨系统",
        "dependencies": [],
        "group": "P0"
    },
    "P0-03": {
        "prompt": "P0_03_summon_system.md",
        "title": "P0-03: 召唤物系统",
        "description": "实现召唤物系统",
        "dependencies": [],
        "group": "P0"
    },

    # Phase 1: 图腾单位 (可并行)
    "P1-A": {
        "prompt": "P1_01_wolf_units_implementation.md",
        "title": "P1-A: 狼图腾单位群",
        "description": "实现狼图腾流派所有单位",
        "dependencies": ["P0-01", "P0-03"],
        "group": "P1"
    },
    "P1-B": {
        "prompt": "P1_02_viper_cobra_units.md",
        "title": "P1-B: 眼镜蛇图腾单位群",
        "description": "实现眼镜蛇图腾流派单位",
        "dependencies": [],
        "group": "P1"
    },
    "P1-C": {
        "prompt": "P1_03_bat_totem_units.md",
        "title": "P1-C: 蝙蝠图腾单位群",
        "description": "实现蝙蝠图腾流派单位",
        "dependencies": ["P0-04"],
        "group": "P1"
    },
    "P1-D": {
        "prompt": "P1_04_butterfly_units.md",
        "title": "P1-D: 蝴蝶图腾单位群",
        "description": "实现蝴蝶图腾流派单位",
        "dependencies": [],
        "group": "P1"
    },
    "P1-E": {
        "prompt": "P1_05_eagle_units.md",
        "title": "P1-E: 鹰图腾单位群",
        "description": "实现鹰图腾流派单位",
        "dependencies": [],
        "group": "P1"
    },
    "P1-F": {
        "prompt": "P1_06_cow_totem_units.md",
        "title": "P1-F: 牛图腾单位群",
        "description": "实现牛图腾流派单位",
        "dependencies": ["P0-02"],
        "group": "P1"
    },
}


def submit_single_task(task_id: str, task_config: dict, wait: bool = False, timeout: int = 3600) -> dict:
    """提交单个任务"""
    client = JulesClient()
    manager = JulesTaskManager(client)

    prompt_file = task_config["prompt"]
    prompt_path = Path(__file__).parent / prompt_file

    if not prompt_path.exists():
        return {
            "task_id": task_id,
            "status": "error",
            "error": f"Prompt file not found: {prompt_file}"
        }

    try:
        session_id = manager.submit_task(
            task_id=task_id,
            prompt=str(prompt_path),
            title=task_config["title"]
        )

        result = {
            "task_id": task_id,
            "session_id": session_id,
            "status": "submitted"
        }

        if wait:
            final = manager.wait_for_task(task_id, timeout=timeout)
            result["final_state"] = final.get("state")
            result["url"] = final.get("url")

        return result

    except Exception as e:
        return {
            "task_id": task_id,
            "status": "error",
            "error": str(e)
        }


def main():
    parser = argparse.ArgumentParser(
        description='批量提交任务到 Jules API',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
示例:
  # 提交所有 P0 任务
  python run_jules_batch.py --phase P0

  # 提交所有 P1 任务（并行）
  python run_jules_batch.py --phase P1

  # 提交特定任务
  python run_jules_batch.py --tasks P1-A,P1-B,P1-C

  # 提交并等待完成
  python run_jules_batch.py --phase P1 --wait --max-workers 3
        '''
    )

    parser.add_argument(
        '--phase',
        choices=['P0', 'P1', 'all'],
        help='提交特定阶段的任务'
    )

    parser.add_argument(
        '--tasks',
        help='逗号分隔的特定任务ID列表 (例如: P0-01,P0-02)'
    )

    parser.add_argument(
        '--wait',
        action='store_true',
        help='等待所有任务完成'
    )

    parser.add_argument(
        '--timeout',
        type=int,
        default=3600,
        help='每个任务的超时时间 (秒，默认: 3600)'
    )

    parser.add_argument(
        '--max-workers',
        type=int,
        default=6,
        help='最大并行任务数 (默认: 6)'
    )

    parser.add_argument(
        '--list',
        action='store_true',
        help='列出所有可用任务'
    )

    args = parser.parse_args()

    # 列出任务
    if args.list:
        print("可用任务列表:")
        print("=" * 80)
        for task_id, config in TASKS.items():
            deps = ", ".join(config["dependencies"]) if config["dependencies"] else "无"
            print(f"\n{task_id}: {config['title']}")
            print(f"  描述: {config['description']}")
            print(f"  文件: {config['prompt']}")
            print(f"  依赖: {deps}")
            print(f"  分组: {config['group']}")
        return

    # 确定要提交的任务
    if args.tasks:
        task_ids = [t.strip() for t in args.tasks.split(',')]
    elif args.phase:
        if args.phase == 'all':
            task_ids = list(TASKS.keys())
        else:
            task_ids = [k for k, v in TASKS.items() if v["group"] == args.phase]
    else:
        print("错误: 请指定 --phase 或 --tasks")
        parser.print_help()
        sys.exit(1)

    # 验证任务ID
    invalid_tasks = [t for t in task_ids if t not in TASKS]
    if invalid_tasks:
        print(f"错误: 无效的任务ID: {', '.join(invalid_tasks)}")
        print("使用 --list 查看所有可用任务")
        sys.exit(1)

    # 检查 API 密钥
    api_key = os.getenv('JULES_API_KEY')
    if not api_key:
        print("错误: JULES_API_KEY 环境变量未设置")
        print("请设置环境变量或将 API 密钥写入 docs/secrets/.env 文件")
        sys.exit(1)

    # 显示提交计划
    print("=" * 80)
    print(f"批量提交 {len(task_ids)} 个任务到 Jules API")
    print("=" * 80)
    for task_id in task_ids:
        config = TASKS[task_id]
        deps = f" (依赖: {', '.join(config['dependencies'])})" if config["dependencies"] else ""
        print(f"  - {task_id}: {config['title']}{deps}")
    print(f"\n并行数: {args.max_workers}")
    print(f"等待完成: {'是' if args.wait else '否'}")
    print("=" * 80)

    confirm = input("\n确认提交? (y/N): ")
    if confirm.lower() != 'y':
        print("已取消")
        sys.exit(0)

    # 提交任务
    results = []

    if len(task_ids) == 1:
        # 单个任务直接提交
        task_id = task_ids[0]
        result = submit_single_task(task_id, TASKS[task_id], args.wait, args.timeout)
        results.append(result)
    else:
        # 多个任务并行提交
        with ThreadPoolExecutor(max_workers=args.max_workers) as executor:
            future_to_task = {
                executor.submit(submit_single_task, task_id, TASKS[task_id], args.wait, args.timeout): task_id
                for task_id in task_ids
            }

            for future in as_completed(future_to_task):
                task_id = future_to_task[future]
                try:
                    result = future.result()
                    results.append(result)
                    status = "✓" if result["status"] != "error" else "✗"
                    print(f"{status} {task_id}: {result.get('session_id', result.get('error'))}")
                except Exception as e:
                    results.append({
                        "task_id": task_id,
                        "status": "error",
                        "error": str(e)
                    })
                    print(f"✗ {task_id}: {e}")

    # 汇总结果
    print("\n" + "=" * 80)
    print("提交结果汇总")
    print("=" * 80)

    success = [r for r in results if r["status"] != "error"]
    failed = [r for r in results if r["status"] == "error"]

    print(f"成功: {len(success)}")
    print(f"失败: {len(failed)}")

    if failed:
        print("\n失败任务:")
        for r in failed:
            print(f"  - {r['task_id']}: {r['error']}")
        sys.exit(1)

    if args.wait:
        completed = [r for r in results if r.get("final_state") == "COMPLETED"]
        print(f"已完成: {len(completed)}/{len(results)}")

    print(f"\n进度文件已更新: docs/progress.md")


if __name__ == "__main__":
    main()
