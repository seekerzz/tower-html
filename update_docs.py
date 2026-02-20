import re
import datetime

# Update test_progress.md
file_path = "docs/test_progress.md"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Update Summary Table for Eagle Totem
# Assuming current is 0/12.
content = re.sub(
    r"\| 鹰图腾 \(eagle_totem\) \| 12 \| 0 \| 0% \|",
    "| 鹰图腾 (eagle_totem) | 12 | 1 | 8% |",
    content
)

# Find Vulture Section and update checkmarks
# Use regex to find the section between 6.11 and 6.12
# Note: 6.12 might be the next section, or it might be end of file or something else.
# The doc has 6.12 after 6.11.
vulture_pattern = r"(### 6.11 秃鹫 \(vulture\).*?)(### 6.12)"
match = re.search(vulture_pattern, content, re.DOTALL)
if match:
    section = match.group(1)
    # Replace [ ] with [x] in this section
    new_section = section.replace("- [ ]", "- [x]")

    # Add Test Record if not present
    if "**测试记录**" not in new_section:
        record = "\n**测试记录**:\n- 测试日期: 2026-02-20\n- 测试人员: Jules\n- 测试结果: 通过\n- 备注: 修复了Lv3无限叠加逻辑，调整了测试敌人生成位置以确保在射程内。\n\n"
        new_section += record

    content = content.replace(section, new_section)
else:
    print("Warning: Vulture section not found via regex.")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

# Update progress.md
progress_path = "docs/progress.md"
timestamp = datetime.datetime.now().isoformat()
with open(progress_path, "a", encoding="utf-8") as f:
    f.write(f"| TEST-EAGLE-vulture | completed | 所有测试通过 | {timestamp} |\n")

print("Docs updated.")
