#!/usr/bin/env python3
"""
监控所有已提交的Jules测试任务状态
"""

import os
import sys
import json
import requests
from pathlib import Path
from datetime import datetime

# 加载 .env
env_path = Path(__file__).parent / "docs" / "secrets" / ".env"
if env_path.exists():
    with open(env_path, encoding='utf-8') as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                os.environ.setdefault(key, value)

API_KEY = os.getenv('JULES_API_KEY')
PROXY = os.getenv('HTTP_PROXY', 'http://127.0.0.1:10998')
BASE_URL = "https://jules.googleapis.com/v1alpha"

# 已提交的任务列表 (从progress.md中提取)
SUBMITTED_TASKS = {
    # Cow Totem (9)
    "TEST-COW-yak_guardian": "9259750312656791152",
    "TEST-COW-iron_turtle": "15175986494597926059",
    "TEST-COW-hedgehog": "15430884240302979920",
    "TEST-COW-cow_golem": "7758126963140366261",
    "TEST-COW-rock_armor_cow": "8350143221268592731",
    "TEST-COW-mushroom_healer": "122525792852353332",
    "TEST-COW-cow": "11207535753113131368",
    "TEST-COW-plant": "2488884770006773367",
    "TEST-COW-ascetic": "12495522591194376384",
    # Bat Totem (5)
    "TEST-BAT-mosquito": "9881182305532198147",
    "TEST-BAT-vampire_bat": "4153801140282894780",
    "TEST-BAT-plague_spreader": "1327521830971641082",
    "TEST-BAT-blood_mage": "4396490713445302650",
    "TEST-BAT-blood_ancestor": "18203609505312264863",
    # Wolf Totem (7)
    "TEST-WOLF-tiger": "12858209013666654503",
    "TEST-WOLF-dog": "13450467198137360290",
    "TEST-WOLF-wolf": "3780996429922059263",
    "TEST-WOLF-hyena": "3994583798022591812",
    "TEST-WOLF-fox": "17705501139268513989",
    "TEST-WOLF-sheep_spirit": "10304931709877735180",
    "TEST-WOLF-lion": "7574649977311979363",
    # Butterfly Totem (6)
    "TEST-BUTTERFLY-torch": "13265696843951987200",
    "TEST-BUTTERFLY-butterfly": "7046216473243701974",
    "TEST-BUTTERFLY-fairy_dragon": "17502195174580125610",
    "TEST-BUTTERFLY-phoenix": "6836953366970019758",
    "TEST-BUTTERFLY-eel": "299489837968568554",
    "TEST-BUTTERFLY-dragon": "7970843417849497309",
    # Viper Totem (8)
    "TEST-VIPER-spider": "11535360915414252077",
    "TEST-VIPER-snowman": "13469566763816627683",
    "TEST-VIPER-scorpion": "5261333368884214964",
    "TEST-VIPER-viper": "4869278410684967634",
    "TEST-VIPER-arrow_frog": "7939285818152393656",
    "TEST-VIPER-medusa": "10041158047437884215",
    "TEST-VIPER-lure_snake": "8973128394434980817",
    "TEST-VIPER-rat": "5363347949880217510",
    # Eagle Totem (12)
    "TEST-EAGLE-kestrel": "16733686083955433172",
    "TEST-EAGLE-owl": "5028339004195650037",
    "TEST-EAGLE-magpie": "3311292287529318833",
    "TEST-EAGLE-pigeon": "11435639122473732057",
    "TEST-EAGLE-harpy_eagle": "14583700898748003528",
    "TEST-EAGLE-gale_eagle": "149199656860086866",
    "TEST-EAGLE-eagle": "567138428131140866",
    "TEST-EAGLE-vulture": "16863976502807481868",
    "TEST-EAGLE-woodpecker": "5775892564167130519",
    "TEST-EAGLE-parrot": "8439249873560185159",
    "TEST-EAGLE-peacock": "12143319191127893868",
    "TEST-EAGLE-storm_eagle": "18152400928651194387",
}

PENDING_TASKS = [
    # All tasks submitted! None remaining.
]

FAILED_TASKS = [
    # Failed tasks that need retry
    "TEST-BUTTERFLY-eel",
]


def get_session_status(session_id: str):
    """获取会话状态"""
    headers = {"X-Goog-Api-Key": API_KEY}
    proxies = {"http": PROXY, "https": PROXY} if PROXY else None

    try:
        resp = requests.get(
            f"{BASE_URL}/sessions/{session_id}",
            headers=headers,
            proxies=proxies,
            timeout=30
        )
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        return {"error": str(e)}


def check_all_tasks():
    """检查所有已提交任务的状态"""
    print("=" * 80)
    print("Jules 测试任务状态监控")
    print(f"检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)

    completed = 0
    failed = 0
    in_progress = 0
    other = 0

    results = []

    for task_id, session_id in SUBMITTED_TASKS.items():
        result = get_session_status(session_id)

        if "error" in result:
            status = "ERROR"
            state = result.get("error", "Unknown")
        else:
            state = result.get('state', 'UNKNOWN')
            status = state

        # 简化状态显示
        if state in ['COMPLETED']:
            completed += 1
            status_icon = "✓"
        elif state in ['FAILED', 'CANCELLED']:
            failed += 1
            status_icon = "✗"
        elif state in ['IN_PROGRESS', 'PROCESSING', 'ACTIVE']:
            in_progress += 1
            status_icon = "~"
        else:
            other += 1
            status_icon = "?"

        results.append({
            "task_id": task_id,
            "session_id": session_id,
            "state": state,
            "icon": status_icon
        })

    # 按派系分组显示
    factions = {
        "Cow Totem": [r for r in results if "TEST-COW" in r["task_id"]],
        "Bat Totem": [r for r in results if "TEST-BAT" in r["task_id"]],
        "Wolf Totem": [r for r in results if "TEST-WOLF" in r["task_id"]],
        "Butterfly Totem": [r for r in results if "TEST-BUTTERFLY" in r["task_id"]],
        "Viper Totem": [r for r in results if "TEST-VIPER" in r["task_id"]],
        "Eagle Totem": [r for r in results if "TEST-EAGLE" in r["task_id"]],
    }

    for faction_name, faction_results in factions.items():
        if faction_results:
            print(f"\n{faction_name}:")
            for r in faction_results:
                print(f"  {r['icon']} {r['task_id']:35s} - {r['state']}")

    print("\n" + "=" * 80)
    print("汇总统计:")
    print(f"  ✓ 已完成:   {completed}/{len(SUBMITTED_TASKS)}")
    print(f"  ~ 进行中:   {in_progress}/{len(SUBMITTED_TASKS)}")
    print(f"  ✗ 失败:     {failed}/{len(SUBMITTED_TASKS)}")
    print(f"  ? 其他:     {other}/{len(SUBMITTED_TASKS)}")
    print(f"  - 待提交:   {len(PENDING_TASKS)}")
    print("=" * 80)

    # 如果所有任务都完成，提示可以提交剩余任务
    if completed == len(SUBMITTED_TASKS):
        print("\n🎉 所有已提交任务已完成！可以提交剩余任务：")
        print(f"   bash submit_remaining_tests.sh")
    elif completed + failed == len(SUBMITTED_TASKS):
        print("\n⚠️ 所有任务已结束（部分失败）。建议检查失败任务后提交剩余任务。")

    return completed, failed, in_progress, other


if __name__ == "__main__":
    if not API_KEY:
        print("错误: JULES_API_KEY 未设置")
        sys.exit(1)

    check_all_tasks()
