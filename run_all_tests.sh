#!/bin/bash
# 批量运行所有测试并收集错误

cd "$(dirname "$0")"

LOG_FILE="test_run_$(date +%Y%m%d_%H%M%S).log"
ERROR_FILE="test_errors_$(date +%Y%m%d_%H%M%S).log"

# 获取所有测试ID
tests=$(grep -oP '"test_[^"]+"' src/Scripts/Tests/TestSuite.gd | tr -d '"' | sort -u)

total=$(echo "$tests" | wc -l)
count=0
errors=0

echo "Running $total tests..."
echo "============================" | tee -a "$LOG_FILE"

for test_id in $tests; do
    count=$((count + 1))
    echo -n "[$count/$total] Testing $test_id... " | tee -a "$LOG_FILE"

    # 运行测试并捕获输出
    output=$(godot --path . --headless -- --run-test="$test_id" 2>&1)
    exit_code=$?

    # 检查错误
    if echo "$output" | grep -q "SCRIPT ERROR"; then
        echo "FAILED (Script Error)" | tee -a "$LOG_FILE"
        echo "$test_id" >> "$ERROR_FILE"
        echo "$output" | grep -A2 "SCRIPT ERROR" >> "$ERROR_FILE"
        echo "---" >> "$ERROR_FILE"
        errors=$((errors + 1))
    elif [ $exit_code -ne 0 ]; then
        echo "FAILED (Exit $exit_code)" | tee -a "$LOG_FILE"
        errors=$((errors + 1))
    else
        echo "OK" | tee -a "$LOG_FILE"
    fi
done

echo "============================" | tee -a "$LOG_FILE"
echo "Completed: $total tests, $errors failed" | tee -a "$LOG_FILE"

if [ $errors -gt 0 ]; then
    echo "Errors saved to: $ERROR_FILE"
    cat "$ERROR_FILE"
fi
