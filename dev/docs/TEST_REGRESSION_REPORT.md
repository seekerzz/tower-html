# 回归测试报告

**测试日期**: 2026-02-21
**测试范围**: 全量单位测试（123个测试用例）
**测试环境**: Godot 4.6 Headless模式

---

## 执行摘要

| 指标 | 数值 |
|------|------|
| 测试用例总数 | 123 |
| 执行测试数 | 46 |
| 发现问题数 | 5 |
| 严重问题数 | 5 |

---

## 发现的问题

### 1. 岩甲牛 (RockArmorCow) - 信号不存在

**错误信息**:
```
SCRIPT ERROR: Invalid access to property or key 'core_healed' on a base object of type 'Node (GameManager.gd)'.
   at: on_setup (res://src/Scripts/Units/Behaviors/RockArmorCow.gd:9)
   at: on_cleanup (res://src/Scripts/Units/Behaviors/RockArmorCow.gd:43)
```

**问题分析**:
- 代码尝试连接 `GameManager.core_healed` 信号
- 该信号在 `01518b0`（牛图腾实现）中添加
- 在 `70c0be4`（鹰图腾合并）时被意外移除

**影响等级**: 🔴 高 - 单位无法加载

**修复建议**:
在 `GameManager.gd` 中恢复信号定义和 `heal_core` 方法：
```gdscript
signal core_healed(amount, overheal)

func heal_core(amount: float):
    var overheal = 0.0
    if core_health + amount > max_core_health:
        overheal = (core_health + amount) - max_core_health
    damage_core(-amount)
    if core_health > max_core_health:
        core_health = max_core_health
    core_healed.emit(amount, overheal)
```

---

### 2. 蘑菇医者 (MushroomHealer) - 方法不存在

**错误信息**:
```
SCRIPT ERROR: Invalid call. Nonexistent function 'get_units_in_cell_range' in base 'Node2D (Unit)'.
   at: MushroomHealerBehavior._apply_spore_shields (res://src/Scripts/Units/Behaviors/MushroomHealer.gd:22)
```

**问题分析**:
- 代码调用 `unit.get_units_in_cell_range(unit, 3)` 获取范围内友方单位
- `Unit` 基类中没有此方法定义
- 同样问题存在于 `Plant.gd:43`

**影响等级**: 🔴 高 - 单位无法加载

**修复建议**:
在 `Unit.gd` 中添加方法：
```gdscript
func get_units_in_cell_range(center_unit: Node2D, cell_range: int) -> Array:
    var result = []
    var center_pos = Vector2i(grid_x, grid_y)
    for key in GameManager.grid_manager.tiles:
        var tile = GameManager.grid_manager.tiles[key]
        if tile.unit and tile.unit != self:
            var dist = abs(tile.x - center_pos.x) + abs(tile.y - center_pos.y)
            if dist <= cell_range:
                result.append(tile.unit)
    return result
```

---

### 3. 秃鹫 (Vulture) - 继承链错误

**错误信息**:
```
SCRIPT ERROR: Parse Error: Function "_enter_claw_return()" not found in base self.
   at: GDScript::reload (res://src/Scripts/Units/Behaviors/Vulture.gd:75)
   at: GDScript::reload (res://src/Scripts/Units/Behaviors/Vulture.gd:80)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
SCRIPT ERROR: Invalid call. Nonexistent function 'on_setup' in base 'Nil'.
```

**问题分析**:
- `Vulture.gd` 继承自 `FlyingMeleeBehavior`
- 代码调用 `_enter_claw_return()` 方法（line 75, 80）
- 父类 `FlyingMeleeBehavior` 中只有 `_enter_return()` 方法
- 对比 `HarpyEagle.gd` 有自定义的 `_enter_claw_return()` 方法
- Vulture 复制了 HarpyEagle 的代码结构但缺少方法定义

**影响等级**: 🔴 高 - 单位无法加载

**修复建议**:
方案A：将调用改为父类方法名：
```gdscript
# 修改 Vulture.gd line 75, 80
_combat_tween.tween_callback(func(): _enter_return(t_return, t_landing))
```

方案B：添加缺失的方法定义（如果需要自定义返回动画）

---

### 4. 召唤系统 (SummonSystem) - 成员变量冲突

**错误信息**:
```
SCRIPT ERROR: Parse Error: The member "current_hp" already exists in parent class Unit.
   at: GDScript::reload (res://src/Scripts/Units/SummonedUnit.gd:9)
SCRIPT ERROR: Invalid call. Nonexistent function 'setup' in base 'Node2D'.
   at: SummonManager.create_summon (res://src/Scripts/Managers/SummonManager.gd:33)
```

**问题分析**:
- `SummonedUnit.gd` 定义了 `current_hp` 变量
- 父类 `Unit` 已定义同名变量
- `SummonManager` 尝试调用 `setup` 方法但接口不匹配

**影响等级**: 🔴 高 - 召唤系统完全不可用

**修复建议**:
1. 移除 `SummonedUnit.gd` 中的重复变量定义
2. 检查 `SummonManager` 和 `SummonedUnit` 的接口兼容性

---

## 问题根因分类

| 根因类型 | 问题数 | 说明 |
|----------|--------|------|
| 合并冲突/覆盖 | 1 | `core_healed` 信号被意外移除 |
| 方法名错误 | 1 | 复制代码时未调整方法名 |
| 缺失API实现 | 2 | `get_units_in_cell_range`, `setup` |
| 继承冲突 | 1 | 子类重复定义父类成员 |

---

## 修复优先级

| 优先级 | 问题 | 理由 |
|--------|------|------|
| P0 | `core_healed` 信号 | 影响岩甲牛Lv3核心机制 |
| P0 | Vulture 方法错误 | 单位完全无法使用 |
| P0 | SummonedUnit 冲突 | 召唤系统完全崩溃 |
| P1 | `get_units_in_cell_range` | 影响蘑菇医者和植物两个单位 |

---

## 预防措施建议

1. **代码审查清单**：
   - [ ] 所有信号连接前验证信号存在
   - [ ] 所有方法调用前验证方法存在（特别是继承的方法）
   - [ ] 子类定义成员前检查父类是否已定义
   - [ ] 跨文件引用的方法需确认导出/公共

2. **测试改进**：
   - [ ] 所有单位测试必须实际加载单位场景
   - [ ] 添加引用完整性静态检查脚本
   - [ ] 合并前强制通过全量回归测试

3. **工作流程改进**：
   - [ ] 多个并行功能开发时，合并顺序需谨慎
   - [ ] 涉及共享文件（如 GameManager）的修改需额外审查

---

*报告生成时间: 2026-02-21*
