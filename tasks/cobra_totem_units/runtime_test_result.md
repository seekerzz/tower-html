# 眼镜蛇图腾系列运行时测试报告

## 测试时间
2026-02-16

## 测试环境
- Godot Engine v4.3.stable
- 测试场景: TestCobraTotemRuntime.tscn
- 测试脚本: TestCobraTotemRuntime.gd

## 测试单位

### 1. lure_snake (诱捕蛇)
- 放置测试: **FAIL** - 放置后无法获取单位实例
- 攻击测试: **SKIP** - 放置失败导致无法测试
- 受击测试: **SKIP** - 放置失败导致无法测试

### 2. medusa (美杜莎)
- 放置测试: **FAIL** - 行为脚本加载失败，存在语法错误
- 攻击测试: **SKIP** - 放置失败导致无法测试
- 受击测试: **SKIP** - 放置失败导致无法测试

## 发现的问题

### 问题 1: Medusa.gd 语法错误（严重）
**影响单位**: medusa

**错误信息**:
```
SCRIPT ERROR: Parse Error: Function "get_tree()" not found in base self.
          at: GDScript::reload (res://src/Scripts/Units/Behaviors/Medusa.gd:120)
SCRIPT ERROR: Parse Error: Function "get_tree()" not found in base self.
          at: GDScript::reload (res://src/Scripts/Units/Behaviors/Medusa.gd:132)
SCRIPT ERROR: Parse Error: Function "get_tree()" not found in base self.
          at: GDScript::reload (res://src/Scripts/Units/Behaviors/Medusa.gd:142)
```

**问题原因**:
- `UnitBehavior` 继承自 `RefCounted`，不是 `Node`
- 行为脚本实例没有 `get_tree()` 方法
- Medusa.gd 中第120、132、142行直接调用了 `get_tree()`

**建议修复**:
将 Medusa.gd 中的以下代码:
```gdscript
# 第120行
var enemies = get_tree().get_nodes_in_group("enemies")

# 第132行
get_tree().current_scene.add_child(effect)

# 第142行
get_tree().current_scene.add_child(effect)
```

改为:
```gdscript
# 第120行
var enemies = unit.get_tree().get_nodes_in_group("enemies")

# 第132行
unit.get_tree().current_scene.add_child(effect)

# 第142行
unit.get_tree().current_scene.add_child(effect)
```

### 问题 2: lure_snake 放置测试失败（中等）
**影响单位**: lure_snake

**问题描述**:
- `GridManager.place_unit()` 返回 `true` 表示放置成功
- 但通过 `tiles[tile_key].unit` 无法获取单位实例
- 可能是单位被立即销毁或放置逻辑存在问题

**可能原因**:
1. 单位放置后被其他逻辑移除
2. `place_unit` 返回 true 但实际放置失败
3. 单位放置到了错误的位置

**建议调查方向**:
1. 在 `GridManager.place_unit()` 中添加更多日志
2. 检查 `lure_snake` 的单位数据是否完整
3. 验证行为脚本 `LureSnake.gd` 是否能正确加载

### 问题 3: LureSnake.gd 潜在问题（轻微）
**影响单位**: lure_snake

**代码审查发现**:
- LureSnake.gd 代码逻辑看起来正确
- 使用了 `GameManager.grid_manager` 和 `GameManager.spawn_floating_text`，这些都是有效的全局访问
- 没有直接使用 `get_tree()`，所以不会有 Medusa.gd 的问题

**潜在风险**:
- 第50-52行的信号连接逻辑依赖陷阱有 `trap_triggered` 信号
- 需要确保所有 BARRICADE_TYPES 中的陷阱都有这个信号

## 代码审查摘要

### LureSnake.gd
- **状态**: 代码逻辑正确，但运行时测试失败
- **风险**: 低（语法正确）
- **需要修复**: 需要调查放置失败原因

### Medusa.gd
- **状态**: 存在语法错误，无法加载
- **风险**: 高（完全无法运行）
- **需要修复**: 将 `get_tree()` 改为 `unit.get_tree()`

## 修复优先级

1. **高优先级**: 修复 Medusa.gd 的 `get_tree()` 语法错误
2. **中优先级**: 调查 lure_snake 放置失败原因
3. **低优先级**: 验证 LureSnake.gd 的陷阱信号连接逻辑

## 总结
- 通过: 0/6
- 失败: 2/2 单位
- 跳过: 4/6 测试项

**结论**: 两个单位目前都无法正常运行。Medusa 存在明确的语法错误需要修复，lure_snake 需要进一步调查放置失败原因。
