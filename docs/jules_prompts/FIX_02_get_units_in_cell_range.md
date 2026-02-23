# Jules 任务: 实现 get_units_in_cell_range 方法

## 任务ID
FIX-02

## 优先级
P0 - 高优先级

## 问题描述
蘑菇医者 (MushroomHealer) 和植物 (Plant) 单位无法加载，因为代码调用了不存在的 `get_units_in_cell_range` 方法。

**错误信息**:
```
SCRIPT ERROR: Invalid call. Nonexistent function 'get_units_in_cell_range' in base 'Node2D (Unit)'.
   at: MushroomHealerBehavior._apply_spore_shields (res://src/Scripts/Units/Behaviors/MushroomHealer.gd:22)
```

## 影响单位
- 蘑菇医者 (MushroomHealer) - 用于获取范围内友方单位施加孢子护盾
- 植物 (Plant) - 用于获取范围内友方单位施加生长光环

## 需要修改的文件

### src/Scripts/Unit.gd

在 `Unit` 类中添加公共方法：

```gdscript
# 获取指定范围内的友方单位
# center_unit: 中心单位（通常是self）
# cell_range: 格子范围（曼哈顿距离）
# returns: 范围内友方单位数组（不包含自己）
func get_units_in_cell_range(center_unit: Node2D, cell_range: int) -> Array:
    var result = []
    if not GameManager.grid_manager:
        return result

    var center_x = grid_x
    var center_y = grid_y

    for key in GameManager.grid_manager.tiles:
        var tile = GameManager.grid_manager.tiles[key]
        if tile.unit and tile.unit != self:
            # 计算曼哈顿距离
            var dist = abs(tile.x - center_x) + abs(tile.y - center_y)
            if dist <= cell_range:
                result.append(tile.unit)

    return result
```

## 验证步骤

1. 运行蘑菇医者测试：
```bash
godot --path . --headless -- --run-test=test_cow_totem_mushroom_healer
```

2. 运行植物测试：
```bash
godot --path . --headless -- --run-test=test_cow_totem_plant
```

3. 确认无 SCRIPT ERROR

## 相关文件
- `src/Scripts/Unit.gd` - 需要添加方法
- `src/Scripts/Units/Behaviors/MushroomHealer.gd` - 调用方，无需修改
- `src/Scripts/Units/Behaviors/Plant.gd` - 调用方，无需修改

## 参考资料
- 回归测试报告: `TEST_REGRESSION_REPORT.md`

## 代码提交要求

1. 在独立分支上工作：`fix/FIX-02-get-units-in-cell-range`
2. 提交信息格式：`[FIX-02] 添加 get_units_in_cell_range 方法修复蘑菇医者和植物`
3. 完成后创建 Pull Request 到 main 分支
4. 更新 `docs/progress.md` 添加修复记录

## 进度同步

修复完成后，更新 `docs/progress.md`：
```markdown
| FIX-02 | completed | 添加 get_units_in_cell_range 方法 | 2026-02-21 |
```
