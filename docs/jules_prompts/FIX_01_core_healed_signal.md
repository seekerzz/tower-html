# Jules 任务: 修复 core_healed 信号缺失问题

## 任务ID
FIX-01

## 优先级
P0 - 高优先级

## 问题描述
岩甲牛 (RockArmorCow) 单位无法加载，因为代码尝试连接 `GameManager.core_healed` 信号，但该信号在当前代码中不存在。

**错误信息**:
```
SCRIPT ERROR: Invalid access to property or key 'core_healed' on a base object of type 'Node (GameManager.gd)'.
   at: on_setup (res://src/Scripts/Units/Behaviors/RockArmorCow.gd:9)
   at: on_cleanup (res://src/Scripts/Units/Behaviors/RockArmorCow.gd:43)
```

## 问题根因
信号在 `01518b0`（牛图腾实现）中添加，但在 `70c0be4`（鹰图腾合并）时被意外移除。

## 需要修改的文件

### 1. src/Autoload/GameManager.gd

在信号定义区域添加：
```gdscript
signal core_healed(amount, overheal)
```

修改 `heal_core` 方法：
```gdscript
func heal_core(amount: float):
    var old_hp = core_health
    core_health = min(max_core_health, core_health + amount)
    var actual_heal = core_health - old_hp
    var overheal = amount - actual_heal

    resource_changed.emit()
    core_healed.emit(actual_heal, overheal)
```

## 验证步骤

1. 运行测试验证修复：
```bash
godot --path . --headless -- --run-test=test_cow_totem_rock_armor_cow
```

2. 确认无 SCRIPT ERROR

3. 检查岩甲牛 Lv3 机制正常工作（护盾转化）

## 相关文件
- `src/Autoload/GameManager.gd` - 需要添加信号和修改 heal_core 方法
- `src/Scripts/Units/Behaviors/RockArmorCow.gd` - 无需修改，等待信号恢复

## 参考资料
- 原始实现提交: `01518b0`
- 回归测试报告: `TEST_REGRESSION_REPORT.md`

## 代码提交要求

1. 在独立分支上工作：`fix/FIX-01-core-healed-signal`
2. 提交信息格式：`[FIX-01] 恢复 core_healed 信号修复岩甲牛加载问题`
3. 完成后创建 Pull Request 到 main 分支
4. 更新 `docs/progress.md` 添加修复记录

## 进度同步

修复完成后，更新 `docs/progress.md`：
```markdown
| FIX-01 | completed | 恢复 core_healed 信号 | 2026-02-21 |
```
