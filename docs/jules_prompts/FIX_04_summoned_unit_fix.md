# Jules 任务: 修复 SummonedUnit 和 SummonManager 问题

## 任务ID
FIX-04

## 优先级
P0 - 高优先级

## 问题描述
召唤系统完全崩溃，有两个问题：

### 问题1: 成员变量重复定义
```
SCRIPT ERROR: Parse Error: The member "current_hp" already exists in parent class Unit.
   at: GDScript::reload (res://src/Scripts/Units/SummonedUnit.gd:9)
```

### 问题2: 方法调用错误
```
SCRIPT ERROR: Invalid call. Nonexistent function 'setup' in base 'Node2D'.
   at: SummonManager.create_summon (res://src/Scripts/Managers/SummonManager.gd:33)
```

## 需要修改的文件

### 1. src/Scripts/Units/SummonedUnit.gd

**需要删除或注释掉重复定义的成员变量**：

检查文件中的变量定义，删除以下已在父类 `Unit` 中定义的变量：
- `current_hp`（如果在 SummonedUnit 中定义了）
- 其他与父类冲突的变量

父类 `Unit.gd` 已定义的成员：
```gdscript
# Unit.gd 中已有的定义
var current_hp: float = 0.0
var max_hp: float = 0.0
var damage: float = 0.0
var atk_speed: float = 1.0
var range_val: float = 100.0
```

### 2. src/Scripts/Managers/SummonManager.gd

检查 `create_summon` 方法的实现，确保正确调用单位初始化：

**可能的修复方案**:

如果代码调用：
```gdscript
summon.setup(...)  # 或其他不存在的方法
```

改为：
```gdscript
# 使用正确的初始化方法
summon.setup_unit(...)  # 或者单位实际有的方法
# 或者直接设置属性
summon.current_hp = summon.max_hp
```

或者如果 `setup` 是必需的方法，需要在 `SummonedUnit` 或 `Unit` 基类中添加。

## 验证步骤

1. 运行召唤系统测试：
```bash
godot --path . --headless -- --run-test=test_summon_system
```

2. 确认无 SCRIPT ERROR

3. 验证召唤物能正常生成和销毁

## 相关文件
- `src/Scripts/Units/SummonedUnit.gd` - 需要移除重复变量
- `src/Scripts/Managers/SummonManager.gd` - 需要修复方法调用
- `src/Scripts/Unit.gd` - 父类定义参考

## 参考资料
- 回归测试报告: `TEST_REGRESSION_REPORT.md`

## 代码提交要求

1. 在独立分支上工作：`fix/FIX-04-summon-system`
2. 提交信息格式：`[FIX-04] 修复召唤系统成员冲突和方法调用错误`
3. 完成后创建 Pull Request 到 main 分支
4. 更新 `docs/progress.md` 添加修复记录

## 进度同步

修复完成后，更新 `docs/progress.md`：
```markdown
| FIX-04 | completed | 修复召唤系统问题 | 2026-02-21 |
```
