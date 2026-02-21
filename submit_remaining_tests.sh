#!/bin/bash
# Submit remaining test tasks to Jules
# Run this script after the rate limit resets

export HTTP_PROXY=http://127.0.0.1:10998
export HTTPS_PROXY=http://127.0.0.1:10998

cd /home/zhangzhan/tower-html

# Butterfly (2 remaining)
echo "=== Butterfly Totem ==="
python docs/jules_prompts/submit_jules_task.py --task-id TEST-BUTTERFLY-eel --prompt docs/jules_prompts/TEST_BUTTERFLY_eel.md --title "Test: Eel (电鳗)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-BUTTERFLY-dragon --prompt docs/jules_prompts/TEST_BUTTERFLY_dragon.md --title "Test: Dragon (龙)"
sleep 2

# Viper (8 units)
echo "=== Viper Totem ==="
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-spider --prompt docs/jules_prompts/TEST_VIPER_spider.md --title "Test: Spider (蜘蛛)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-snowman --prompt docs/jules_prompts/TEST_VIPER_snowman.md --title "Test: Snowman (雪人)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-scorpion --prompt docs/jules_prompts/TEST_VIPER_scorpion.md --title "Test: Scorpion (蝎子)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-viper --prompt docs/jules_prompts/TEST_VIPER_viper.md --title "Test: Viper (蝰蛇)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-arrow_frog --prompt docs/jules_prompts/TEST_VIPER_arrow_frog.md --title "Test: Arrow Frog (箭毒蛙)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-medusa --prompt docs/jules_prompts/TEST_VIPER_medusa.md --title "Test: Medusa (美杜莎)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-lure_snake --prompt docs/jules_prompts/TEST_VIPER_lure_snake.md --title "Test: Lure Snake (诱捕蛇)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-VIPER-rat --prompt docs/jules_prompts/TEST_VIPER_rat.md --title "Test: Rat (老鼠)"
sleep 2

# Eagle (12 units)
echo "=== Eagle Totem ==="
python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-kestrel --prompt docs/jules_prompts/TEST_EAGLE_kestrel.md --title "Test: Kestrel (红隼)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-owl --prompt docs/jules_prompts/TEST_EAGLE_owl.md --title "Test: Owl (猫头鹰)"
sleep 2
python docs/jules_prompts/submit_jules_task.py --task-id TEST-EAGLE-magpie --prompt docs/jules_prompts/TEST_EAGLE_magpie.md --title "Test: Magpie (喜鹊)"
sleep 2
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

echo "=== All remaining tests submitted ==="
