#!/usr/bin/env python3
"""
Jules 任务执行脚本
用于提交单个任务到 Jules API

使用方法:
    python run_jules_task.py --prompt P0_01_wolf_totem_soul_system.md --task-id P0-01

环境变量:
    JULES_API_KEY - Jules API 密钥 (必需)
    JULES_API_URL - API 端点 URL (可选)
    HTTP_PROXY - HTTP 代理 (可选)

参考:
    https://developers.google.com/jules/api
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from jules_client import JulesClient, JulesTaskManager
import argparse


def main():
    parser = argparse.ArgumentParser(
        description='Submit a task to Jules API',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
示例:
  # 提交 P0-01 任务
  python run_jules_task.py -p P0_01_wolf_totem_soul_system.md -t P0-01

  # 提交并等待完成
  python run_jules_task.py -p P0_01_wolf_totem_soul_system.md -t P0-01 -w

  # 批量提交所有 P0 任务
  python run_jules_batch.py --phase P0
        '''
    )

    parser.add_argument(
        '--prompt', '-p',
        required=True,
        help='Prompt 文件路径 (例如: P0_01_wolf_totem_soul_system.md)'
    )

    parser.add_argument(
        '--task-id', '-t',
        required=True,
        help='任务标识符 (例如: P0-01, P1-A-WOLF)'
    )

    parser.add_argument(
        '--title',
        help='会话标题 (可选，默认使用 task-id)'
    )

    parser.add_argument(
        '--wait', '-w',
        action='store_true',
        help='等待任务完成'
    )

    parser.add_argument(
        '--timeout',
        type=int,
        default=3600,
        help='等待超时时间 (秒，默认: 3600)'
    )

    parser.add_argument(
        '--poll-interval',
        type=int,
        default=10,
        help='状态轮询间隔 (秒，默认: 10)'
    )

    parser.add_argument(
        '--approve-plan',
        action='store_true',
        help='自动批准计划 (仅在 --wait 时有效)'
    )

    args = parser.parse_args()

    # 检查 API 密钥
    api_key = os.getenv('JULES_API_KEY')
    if not api_key:
        print("错误: JULES_API_KEY 环境变量未设置")
        print("请设置环境变量或将 API 密钥写入 docs/secrets/.env 文件")
        print("\n示例:")
        print("  export JULES_API_KEY='YOUR_JULES_API_KEY_HERE'")
        sys.exit(1)

    # 确保 prompt 文件存在
    prompt_path = args.prompt
    if not os.path.isabs(prompt_path):
        prompt_path = os.path.join(os.path.dirname(__file__), prompt_path)

    if not os.path.exists(prompt_path):
        print(f"错误: Prompt 文件不存在: {prompt_path}")
        sys.exit(1)

    # 创建客户端
    client = JulesClient()
    manager = JulesTaskManager(client)

    # 提交任务
    print(f"=" * 60)
    print(f"提交任务到 Jules API")
    print(f"=" * 60)
    print(f"任务ID: {args.task_id}")
    print(f"Prompt: {os.path.basename(prompt_path)}")
    print(f"API URL: {client.config.base_url}")
    print(f"=" * 60)

    try:
        session_id = manager.submit_task(
            task_id=args.task_id,
            prompt=prompt_path,
            title=args.title or args.task_id,
            require_plan_approval=not args.approve_plan
        )
        print(f"✓ 会话创建成功: {session_id}")
        print(f"✓ 进度文件已更新: docs/progress.md")

        if args.wait:
            print(f"\n等待任务完成...")
            print(f"(按 Ctrl+C 取消等待，任务将继续在后台运行)\n")

            result = manager.wait_for_task(
                task_id=args.task_id,
                timeout=args.timeout,
                poll_interval=args.poll_interval
            )

            state = result.get('state', 'UNKNOWN')
            print(f"\n{'=' * 60}")
            print(f"任务完成")
            print(f"{'=' * 60}")
            print(f"最终状态: {state}")
            print(f"会话URL: {result.get('url', 'N/A')}")

            if state == 'COMPLETED':
                print(f"\n✓ 任务执行成功!")
                # 显示输出
                outputs = result.get('outputs', [])
                if outputs:
                    print(f"\n输出文件:")
                    for output in outputs:
                        print(f"  - {output}")
            elif state == 'FAILED':
                print(f"\n✗ 任务执行失败")
                sys.exit(1)
            else:
                print(f"\n? 任务状态: {state}")
        else:
            print(f"\n任务已在后台提交")
            print(f"使用以下命令查看状态:")
            print(f"  python check_jules_status.py -t {args.task_id}")

    except KeyboardInterrupt:
        print(f"\n\n已取消")
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ 错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
