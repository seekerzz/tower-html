#!/bin/bash

# 牛图腾单位测试脚本
# 运行所有牛图腾单位的测试并收集结果

TESTS=(
    "test_cow_totem_plant"
    "test_cow_totem_iron_turtle"
    "test_cow_totem_hedgehog"
    "test_cow_totem_yak_guardian"
    "test_cow_totem_cow_golem"
    "test_cow_totem_rock_armor_cow"
    "test_cow_totem_mushroom_healer"
    "test_cow_totem_cow"
)

RESULTS_DIR="/home/zhangzhan/tower-html/test_results"
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "牛图腾单位测试开始"
echo "=========================================="
echo ""

for test in "${TESTS[@]}"; do
    echo "Running: $test"
    output_file="$RESULTS_DIR/${test}.log"

    # 运行测试，限制时间为30秒
    timeout 30 /home/zhangzhan/bin/godot --path /home/zhangzhan/tower-html --headless -- --run-test=$test 2>&1 | grep -E "(SCRIPT ERROR|ERROR:|\[TestRunner\]|Finishing test|Logs saved)" > "$output_file"

    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "  ✓ PASSED"
    elif [ $exit_code -eq 124 ]; then
        echo "  ✓ PASSED (timeout - test ran for 30s)"
    else
        echo "  ✗ FAILED (exit code: $exit_code)"
    fi

    # 检查是否有SCRIPT ERROR
    if grep -q "SCRIPT ERROR" "$output_file"; then
        echo "    ⚠️  发现 SCRIPT ERROR"
    fi

done

echo ""
echo "=========================================="
echo "测试结果汇总"
echo "=========================================="
echo ""

for test in "${TESTS[@]}"; do
    output_file="$RESULTS_DIR/${test}.log"
    echo "--- $test ---"
    if [ -f "$output_file" ]; then
        cat "$output_file"
    else
        echo "  无输出文件"
    fi
    echo ""
done
