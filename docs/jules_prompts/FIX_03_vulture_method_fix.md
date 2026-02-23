# Jules 任务: 修复 Vulture 方法调用错误

## 任务ID
FIX-03

## 优先级
P0 - 高优先级

## 问题描述
秃鹫 (Vulture) 单位无法加载，因为代码调用了不存在的方法 `_enter_claw_return()`。

**错误信息**:
```
SCRIPT ERROR: Parse Error: Function "_enter_claw_return()" not found in base self.
   at: GDScript::reload (res://src/Scripts/Units/Behaviors/Vulture.gd:75)
   at: GDScript::reload (res://src/Scripts/Units/Behaviors/Vulture.gd:80)
```

## 问题根因
- `Vulture.gd` 继承自 `FlyingMeleeBehavior`
- 代码复制了 `HarpyEagle.gd` 的结构，但 HarpyEagle 有自定义的 `_enter_claw_return()` 方法
- 父类 `FlyingMeleeBehavior` 中只有 `_enter_return()` 方法

## 需要修改的文件

### src/Scripts/Units/Behaviors/Vulture.gd

修改第 75 行和第 80 行的方法调用：

**当前代码（错误）**:
```gdscript
_combat_tween.tween_callback(func(): _enter_claw_return(t_return, t_landing))
```

**修复后**:
```gdscript
_combat_tween.tween_callback(func(): _enter_return(t_return, t_landing))
```

或者，如果需要保留自定义的返回动画逻辑，可以添加 `_enter_claw_return` 方法：

```gdscript
func _enter_claw_return(t_return, t_landing):
    # 调用父类的返回方法
    _enter_return(t_return, t_landing)
```

## 验证步骤

1. 运行秃鹫测试：
```bash
godot --path . --headless -- --run-test=test_eagle_totem_vulture
```

2. 确认无 SCRIPT ERROR

3. 验证秃鹫攻击动画正常（优先攻击低血量敌人、击杀获得攻击加成）

## 相关文件
- `src/Scripts/Units/Behaviors/Vulture.gd` - 需要修改
- `src/Scripts/Units/Behaviors/FlyingMeleeBehavior.gd` - 父类，参考可用方法
- `src/Scripts/Units/Behaviors/HarpyEagle.gd` - 参考实现

## 参考资料
- 回归测试报告: `TEST_REGRESSION_REPORT.md`

## 代码提交要求

1. 在独立分支上工作：`fix/FIX-03-vulture-method`
2. 提交信息格式：`[FIX-03] 修复 Vulture 方法调用错误`
3. 完成后创建 Pull Request 到 main 分支
4. 更新 `docs/progress.md` 添加修复记录

## 进度同步

修复完成后，更新 `docs/progress.md`：
```markdown
| FIX-03 | completed | 修复 Vulture 方法调用错误 | 2026-02-21 |
```
