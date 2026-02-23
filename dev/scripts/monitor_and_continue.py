#!/usr/bin/env python3
"""
持续监控并自动提交剩余任务
"""
import os
import sys
import json
import requests
import time
from pathlib import Path
from datetime import datetime

env_path = Path(__file__).parent / "docs" / "secrets" / ".env"
if env_path.exists():
    with open(env_path, encoding='utf-8') as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                os.environ.setdefault(key, value)

API_KEY = os.getenv('JULES_API_KEY')
PROXY = os.getenv('HTTP_PROXY', 'http://127.0.0.1:10908')
BASE_URL = "https://jules.googleapis.com/v1alpha"

SUBMITTED_TASKS = {
    # All 38 submitted tasks
    "TEST-COW-yak_guardian": "9259750312656791152",
    "TEST-COW-iron_turtle": "15175986494597926059",
    "TEST-COW-hedgehog": "15430884240302979920",
    "TEST-COW-cow_golem": "7758126963140366261",
    "TEST-COW-rock_armor_cow": "8350143221268592731",
    "TEST-COW-mushroom_healer": "122525792852353332",
    "TEST-COW-cow": "11207535753113131368",
    "TEST-COW-plant": "2488884770006773367",
    "TEST-COW-ascetic": "12495522591194376384",
    "TEST-BAT-mosquito": "9881182305532198147",
    "TEST-BAT-vampire_bat": "4153801140282894780",
    "TEST-BAT-plague_spreader": "1327521830971641082",
    "TEST-BAT-blood_mage": "4396490713445302650",
    "TEST-BAT-blood_ancestor": "18203609505312264863",
    "TEST-WOLF-tiger": "12858209013666654503",
    "TEST-WOLF-dog": "13450467198137360290",
    "TEST-WOLF-wolf": "3780996429922059263",
    "TEST-WOLF-hyena": "3994583798022591812",
    "TEST-WOLF-fox": "17705501139268513989",
    "TEST-WOLF-sheep_spirit": "10304931709877735180",
    "TEST-WOLF-lion": "7574649977311979363",
    "TEST-BUTTERFLY-torch": "13265696843951987200",
    "TEST-BUTTERFLY-butterfly": "7046216473243701974",
    "TEST-BUTTERFLY-fairy_dragon": "17502195174580125610",
    "TEST-BUTTERFLY-phoenix": "6836953366970019758",
    "TEST-BUTTERFLY-eel": "6798169719241185010",
    "TEST-BUTTERFLY-dragon": "9791647247200395909",
    "TEST-VIPER-spider": "9871249161849661192",
    "TEST-VIPER-snowman": "16313437160010514295",
    "TEST-VIPER-scorpion": "2742514873084175892",
    "TEST-VIPER-viper": "7366165111901134880",
    "TEST-VIPER-arrow_frog": "7496575543977610001",
    "TEST-VIPER-medusa": "10974464070784468331",
    "TEST-VIPER-lure_snake": "14457353620179937281",
    "TEST-EAGLE-kestrel": "16733686083955433172",
    "TEST-EAGLE-owl": "5028339004195650037",
    "TEST-EAGLE-magpie": "3311292287529318833",
}

def get_status(sid):
    try:
        resp = requests.get(f"{BASE_URL}/sessions/{sid}",
            headers={"X-Goog-Api-Key": API_KEY},
            proxies={"http": PROXY, "https": PROXY} if PROXY else None,
            timeout=30)
        resp.raise_for_status()
        return resp.json().get('state', 'UNKNOWN')
    except Exception as e:
        return f"ERROR: {str(e)[:30]}"

def main():
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Monitoring {len(SUBMITTED_TASKS)} tasks...")
    completed = in_progress = failed = 0
    for tid, sid in SUBMITTED_TASKS.items():
        state = get_status(sid)
        if state == 'COMPLETED':
            completed += 1
        elif state in ['IN_PROGRESS', 'PROCESSING', 'ACTIVE']:
            in_progress += 1
        elif state in ['FAILED', 'CANCELLED']:
            failed += 1
    print(f"  ✓ Completed: {completed} | ~ In Progress: {in_progress} | ✗ Failed: {failed}")
    if completed + failed == len(SUBMITTED_TASKS):
        print("  🎉 All submitted tasks finished! Ready to submit remaining 9 Eagle tasks.")
        print("  Run: bash submit_all_remaining.sh")
    return completed, in_progress, failed

if __name__ == "__main__":
    main()
