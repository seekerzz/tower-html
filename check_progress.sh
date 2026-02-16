#!/bin/bash
# 测试进度监控脚本

echo "========== 测试进度检查 =========="
echo "时间: $(date)"
echo ""

echo "--- 1. 检查各流派测试结果文件 ---"
for faction in cow_totem_units bat_totem_units cobra_totem_units eagle_totem_units; do
    result_file="tasks/${faction}/strict_test_result.md"
    if [ -f "$result_file" ]; then
        lines=$(wc -l < "$result_file")
        echo "$faction: 已生成 ($lines 行)"
    else
        echo "$faction: 尚未生成"
    fi
done

echo ""
echo "--- 2. 检查pitfalls更新 ---"
ls -la tasks/*/pitfalls.md

echo ""
echo "--- 3. SubAgent活动统计 ---"
wc -l /home/zhangzhan/.claude/projects/-home-zhangzhan-tower-html/9f4bb8a7-4374-453f-89c9-e734e774ab05/subagents/agent-*.jsonl 2>/dev/null | head -6

echo ""
echo "--- 4. 检查是否有agent完成 ---"
for agent_id in af8e5a3 abe7277 a106f04 a9e254f; do
    output_file="/tmp/claude-1000/-home-zhangzhan-tower-html/tasks/${agent_id}.output"
    if [ -L "$output_file" ]; then
        real_file=$(readlink -f "$output_file")
        if [ -f "$real_file" ]; then
            last_line=$(tail -1 "$real_file" 2>/dev/null)
            if echo "$last_line" | grep -q "completed\|finished\|done"; then
                echo "Agent $agent_id: 可能已完成"
            else
                echo "Agent $agent_id: 运行中"
            fi
        fi
    fi
done

echo ""
echo "========== 检查完成 =========="
