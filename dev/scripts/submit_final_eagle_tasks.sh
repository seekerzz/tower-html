#!/bin/bash
# Submit remaining Eagle test tasks to Jules
# Run this after rate limit resets

export HTTP_PROXY=http://127.0.0.1:10998
export HTTPS_PROXY=http://127.0.0.1:10998

cd /home/zhangzhan/tower-html

echo "=== Submitting remaining 9 Eagle tasks ==="

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-pigeon --prompt docs/jules_prompts/TEST_EAGLE_pigeon.md --title "Test: Pigeon (鸽子)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-harpy_eagle --prompt docs/jules_prompts/TEST_EAGLE_harpy_eagle.md --title "Test: Harpy Eagle (角雕)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-gale_eagle --prompt docs/jules_prompts/TEST_EAGLE_gale_eagle.md --title "Test: Gale Eagle (疾风鹰)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-eagle --prompt docs/jules_prompts/TEST_EAGLE_eagle.md --title "Test: Eagle (老鹰)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-vulture --prompt docs/jules_prompts/TEST_EAGLE_vulture.md --title "Test: Vulture (秃鹫)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-woodpecker --prompt docs/jules_prompts/TEST_EAGLE_woodpecker.md --title "Test: Woodpecker (啄木鸟)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-parrot --prompt docs/jules_prompts/TEST_EAGLE_parrot.md --title "Test: Parrot (鹦鹉)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-peacock --prompt docs/jules_prompts/TEST_EAGLE_peacock.md --title "Test: Peacock (孔雀)"
sleep 2

python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-storm_eagle --prompt docs/jules_prompts/TEST_EAGLE_storm_eagle.md --title "Test: Storm Eagle (风暴鹰)"

echo "=== All Eagle tasks submitted ==="
