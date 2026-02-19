#!/usr/bin/env python3
"""
Jules API 客户端
用于调用 Google Jules API 执行代码任务

参考文档: https://developers.google.com/jules/api
"""

import os
import json
import time
import requests
from pathlib import Path
from typing import Optional, Dict, Any, Callable
from dataclasses import dataclass
from datetime import datetime

# 加载环境变量
from dotenv import load_dotenv

env_path = Path(__file__).parent / ".." / "secrets" / ".env"
load_dotenv(env_path)


@dataclass
class JulesConfig:
    """Jules API 配置"""
    api_key: str
    base_url: str = "https://jules.googleapis.com/v1alpha"
    proxy: Optional[str] = None

    def __post_init__(self):
        if not self.api_key:
            raise ValueError("JULES_API_KEY is required")
        if self.proxy:
            os.environ["HTTP_PROXY"] = self.proxy
            os.environ["HTTPS_PROXY"] = self.proxy


class JulesClient:
    """Jules API 客户端"""

    def __init__(self, config: Optional[JulesConfig] = None):
        if config is None:
            config = JulesConfig(
                api_key=os.getenv("JULES_API_KEY"),
                base_url=os.getenv("JULES_API_URL", "https://jules.googleapis.com/v1alpha"),
                proxy=os.getenv("HTTP_PROXY")
            )
        self.config = config
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {config.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        })
        if config.proxy:
            self.session.proxies = {
                "http": config.proxy,
                "https": config.proxy
            }

    def create_session(
        self,
        prompt: str,
        title: Optional[str] = None,
        require_plan_approval: bool = False,
        automation_mode: str = "AUTOMATION_MODE_UNSPECIFIED",
        source_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        创建一个新的 Jules 会话

        Args:
            prompt: 任务提示词
            title: 会话标题（可选）
            require_plan_approval: 是否需要计划审批
            automation_mode: 自动化模式
            source_context: 源代码上下文

        Returns:
            创建的会话信息
        """
        url = f"{self.config.base_url}/sessions"

        body = {
            "prompt": prompt,
            "requirePlanApproval": require_plan_approval,
            "automationMode": automation_mode
        }

        if title:
            body["title"] = title
        if source_context:
            body["sourceContext"] = source_context

        response = self.session.post(url, json=body)
        response.raise_for_status()
        return response.json()

    def get_session(self, session_id: str) -> Dict[str, Any]:
        """获取会话信息"""
        url = f"{self.config.base_url}/sessions/{session_id}"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def send_message(self, session_id: str, prompt: str) -> None:
        """向会话发送消息"""
        url = f"{self.config.base_url}/sessions/{session_id}:sendMessage"
        body = {"prompt": prompt}
        response = self.session.post(url, json=body)
        response.raise_for_status()

    def approve_plan(self, session_id: str) -> Dict[str, Any]:
        """批准会话计划"""
        url = f"{self.config.base_url}/sessions/{session_id}:approvePlan"
        response = self.session.post(url)
        response.raise_for_status()
        return response.json()

    def list_activities(self, session_id: str) -> Dict[str, Any]:
        """列出会话活动"""
        url = f"{self.config.base_url}/sessions/{session_id}/activities"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def wait_for_completion(
        self,
        session_id: str,
        timeout: int = 3600,
        poll_interval: int = 10,
        on_progress: Optional[Callable[[Dict[str, Any]], None]] = None
    ) -> Dict[str, Any]:
        """
        等待会话完成

        Args:
            session_id: 会话ID
            timeout: 超时时间（秒）
            poll_interval: 轮询间隔（秒）
            on_progress: 进度回调函数

        Returns:
            最终会话状态
        """
        start_time = time.time()

        while time.time() - start_time < timeout:
            session = self.get_session(session_id)
            state = session.get("state", "STATE_UNSPECIFIED")

            if on_progress:
                on_progress(session)

            # 检查是否完成
            if state in ["COMPLETED", "FAILED", "CANCELLED"]:
                return session

            # 检查是否需要审批
            if state == "AWAITING_PLAN_APPROVAL":
                print(f"Session {session_id} awaiting plan approval")
                # 可以选择自动批准或等待人工批准
                # self.approve_plan(session_id)

            time.sleep(poll_interval)

        raise TimeoutError(f"Session {session_id} did not complete within {timeout} seconds")


class JulesTaskManager:
    """Jules 任务管理器 - 用于管理多个并行任务"""

    def __init__(self, client: Optional[JulesClient] = None):
        self.client = client or JulesClient()
        self.tasks: Dict[str, Dict[str, Any]] = {}
        self.progress_file = Path(__file__).parent / ".." / "progress.md"

    def submit_task(
        self,
        task_id: str,
        prompt: str,
        title: Optional[str] = None,
        require_plan_approval: bool = False
    ) -> str:
        """
        提交一个新任务

        Args:
            task_id: 任务标识
            prompt: 任务提示词
            title: 任务标题
            require_plan_approval: 是否需要计划审批

        Returns:
            Jules 会话ID
        """
        # 读取prompt文件内容
        prompt_content = prompt
        if Path(prompt).exists():
            with open(prompt, 'r', encoding='utf-8') as f:
                prompt_content = f.read()

        # 添加进度同步要求
        prompt_content += f"""

## 重要：进度同步要求

你正在执行的任务ID是: {task_id}

在完成任务的过程中，**每次完成一个重要步骤后**，请立即更新进度文件：

1. 读取 `docs/progress.md` 文件
2. 找到你的任务ID对应的条目
3. 更新状态为以下之一：
   - `in_progress` - 进行中
   - `completed` - 已完成
   - `failed` - 失败
4. 添加简短的进度描述

进度文件格式示例：
```markdown
| 任务ID | 状态 | 描述 | 更新时间 |
|--------|------|------|----------|
| {task_id} | in_progress | 正在创建核心系统... | {datetime.now().isoformat()} |
```

## 自动化测试要求

根据项目中的自动化测试框架文档 (`docs/GameDesign.md` 第491-589行)，你必须：

1. **创建测试配置**: 在 `src/Scripts/Tests/TestSuite.gd` 中添加针对本任务的测试用例
2. **运行测试**: 使用命令 `godot --path . --headless -- --run-test=your_test_name` 验证实现
3. **确保通过**: 所有测试必须通过后，任务才算完成

测试配置应包含：
- 核心类型选择
- 初始金币和法力设置
- 需要测试的单位放置
- 预期的伤害数值验证

## 代码提交要求

1. 在独立的分支上工作: `feature/{task_id}`
2. 每次提交前运行: `git diff` 检查修改
3. 提交信息格式: `[{task_id}] 简要描述`
4. 完成后创建 Pull Request 到 main 分支
"""

        session = self.client.create_session(
            prompt=prompt_content,
            title=title or task_id,
            require_plan_approval=require_plan_approval
        )

        session_id = session.get("id")
        self.tasks[task_id] = {
            "session_id": session_id,
            "status": "submitted",
            "created_at": datetime.now().isoformat(),
            "prompt_file": prompt if Path(prompt).exists() else None
        }

        # 更新进度文件
        self._update_progress(task_id, "submitted", "任务已提交到Jules")

        return session_id

    def check_task(self, task_id: str) -> Dict[str, Any]:
        """检查任务状态"""
        if task_id not in self.tasks:
            raise ValueError(f"Task {task_id} not found")

        session_id = self.tasks[task_id]["session_id"]
        session = self.client.get_session(session_id)

        self.tasks[task_id]["status"] = session.get("state", "UNKNOWN")
        self.tasks[task_id]["last_check"] = datetime.now().isoformat()

        return session

    def wait_for_task(
        self,
        task_id: str,
        timeout: int = 3600,
        poll_interval: int = 10
    ) -> Dict[str, Any]:
        """等待任务完成"""
        if task_id not in self.tasks:
            raise ValueError(f"Task {task_id} not found")

        session_id = self.tasks[task_id]["session_id"]

        def on_progress(session):
            state = session.get("state", "UNKNOWN")
            print(f"[{task_id}] State: {state}")
            self._update_progress(task_id, state.lower(), f"当前状态: {state}")

        return self.client.wait_for_completion(
            session_id,
            timeout=timeout,
            poll_interval=poll_interval,
            on_progress=on_progress
        )

    def _update_progress(self, task_id: str, status: str, description: str):
        """更新进度文件"""
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # 读取现有进度
        progress_data = {}
        if self.progress_file.exists():
            with open(self.progress_file, 'r', encoding='utf-8') as f:
                content = f.read()
                # 解析markdown表格
                for line in content.split('\n'):
                    if line.startswith('|') and task_id in line:
                        continue  # 跳过旧记录
                    if line.startswith('|') and '任务ID' not in line and '---' not in line:
                        parts = [p.strip() for p in line.split('|')[1:-1]]
                        if len(parts) >= 4:
                            progress_data[parts[0]] = parts

        # 更新当前任务
        progress_data[task_id] = [task_id, status, description, now]

        # 写回文件
        with open(self.progress_file, 'w', encoding='utf-8') as f:
            f.write("# 任务进度跟踪\n\n")
            f.write("| 任务ID | 状态 | 描述 | 更新时间 |\n")
            f.write("|--------|------|------|----------|\n")
            for row in progress_data.values():
                f.write(f"| {' | '.join(row)} |\n")


def main():
    """命令行入口"""
    import argparse

    parser = argparse.ArgumentParser(description='Jules API Client')
    parser.add_argument('--prompt', '-p', required=True, help='Prompt file path or text')
    parser.add_argument('--task-id', '-t', required=True, help='Task identifier')
    parser.add_argument('--title', help='Session title')
    parser.add_argument('--wait', '-w', action='store_true', help='Wait for completion')
    parser.add_argument('--timeout', type=int, default=3600, help='Timeout in seconds')

    args = parser.parse_args()

    # 创建客户端
    client = JulesClient()
    manager = JulesTaskManager(client)

    # 提交任务
    print(f"Submitting task: {args.task_id}")
    session_id = manager.submit_task(
        task_id=args.task_id,
        prompt=args.prompt,
        title=args.title
    )
    print(f"Session created: {session_id}")

    # 等待完成
    if args.wait:
        print("Waiting for completion...")
        result = manager.wait_for_task(args.task_id, timeout=args.timeout)
        print(f"Final state: {result.get('state')}")
        print(f"URL: {result.get('url')}")


if __name__ == "__main__":
    main()
