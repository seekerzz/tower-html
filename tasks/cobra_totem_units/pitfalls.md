# 眼镜蛇图腾系列测试踩坑记录

## 测试时间
2026-02-16

## 踩过的坑

### 1. 行为脚本中不能直接使用 get_tree()
**问题描述**: 在 Medusa.gd 中直接使用 `get_tree().get_nodes_in_group("enemies")` 和 `get_tree().current_scene.add_child()` 会导致脚本加载失败。

**错误信息**:
```
SCRIPT ERROR: Parse Error: Function "get_tree()" not found in base self.
          at: GDScript::reload (res://src/Scripts/Units/Behaviors/Medusa.gd:120)
```

**原因分析**: 行为脚本（继承 DefaultBehavior）是独立的实例，不是 Node 的子类，因此没有直接访问场景树的 `get_tree()` 方法。

**解决方案**: 通过 `unit.get_tree()` 来访问场景树，因为 `unit` 是 Node2D 的实例，有完整的节点方法。

**修复代码示例**:
```gdscript
# 错误
var enemies = get_tree().get_nodes_in_group("enemies")
get_tree().current_scene.add_child(effect)

# 正确
var enemies = unit.get_tree().get_nodes_in_group("enemies")
unit.get_tree().current_scene.add_child(effect)
```

### 2. 测试场景的 GridManager 位置
**问题描述**: GridManager 在测试场景中的位置需要正确设置，否则单位放置后位置计算会出错。

**解决方案**: 确保 GridManager 的 position 设置为 `Vector2(640, 300)`，与 MainGame.tscn 保持一致。

### 3. 单位放置后获取实例的方式
**问题描述**: 使用 `GridManager.place_unit()` 后，需要通过 tile 来获取单位实例，但需要注意 tile_key 的正确性。

**正确获取方式**:
```gdscript
var tile_key = GameManager.grid_manager.get_tile_key(grid_x, grid_y)
if GameManager.grid_manager.tiles.has(tile_key):
    var tile = GameManager.grid_manager.tiles[tile_key]
    if tile.unit:
        return tile.unit
```

### 4. Headless 模式下的 Shader 错误
**问题描述**: 在 headless 模式下运行测试时，会出现 shader 编译错误，但这不影响功能测试。

**错误信息**:
```
SHADER ERROR: Uniform instances are not yet implemented for 'canvas_item' shaders.
```

**说明**: 这是 Godot headless 模式的限制，不影响实际游戏运行，可以忽略。

### 5. 测试脚本的超时设置
**问题描述**: 测试脚本需要足够的超时时间来完成所有测试步骤。

**建议**: 设置至少 60 秒的超时时间，以确保所有测试步骤（包括放置、攻击、受击测试和清理）能够完成。

## 给后续开发者的建议

1. **在行为脚本中访问场景树**: 始终使用 `unit.get_tree()` 而不是 `get_tree()`

2. **测试前先验证脚本语法**: 在运行完整测试前，可以先单独加载行为脚本验证是否有语法错误

3. **检查 game_data.json**: 确保单位数据已正确定义，包括所有等级的 mechanics

4. **行为脚本命名**: 确保行为脚本名称与 type_key 的帕斯卡命名匹配（如 `lure_snake` -> `LureSnake.gd`）
