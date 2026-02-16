# lure_snake 问题调查报告

## 调查时间
2026-02-16

## 问题描述
单位: lure_snake (诱捕蛇) 和 medusa (美杜莎)
- place_unit() 返回 false
- 无法获取单位实例 (tiles[tile_key].unit 返回 null)

## 调查发现

### 根本原因
测试脚本 `TestCobraTotemRuntime.gd` 使用了错误的网格位置来放置单位。

**错误的位置:**
- lure_snake: 尝试放置在 (-2, 0)
- medusa: 尝试放置在 (2, 0)

**GridManager 的初始网格状态:**
根据 `/home/zhangzhan/tower-html/src/Scripts/GridManager.gd` 中的 `create_initial_grid()` 函数，只有以下位置是解锁的 (`state = "unlocked"`):
- (0, 0) - 核心位置
- (0, 1), (0, -1) - 上下相邻
- (1, 0), (-1, 0) - 左右相邻

所有其他位置的状态为:
- `locked_inner` - 核心区域内的锁定位置
- `locked_outer` - 野外区域的锁定位置

**can_place_unit 检查:**
在 `GridManager.gd` 第 1105 行，`can_place_unit` 函数检查:
```gdscript
if tile.state != "unlocked": return false
```

这意味着只有在 `unlocked` 状态的 tile 上才能放置单位。

### 为什么 place_unit 返回 false
当尝试在 (-2, 0) 或 (2, 0) 放置单位时:
1. `place_unit` 调用 `can_place_unit(x, y, w, h)`
2. `can_place_unit` 检查 tile 状态为 `locked_inner`
3. 返回 false，单位被销毁 (`unit.queue_free()`)
4. 因此 `tiles[tile_key].unit` 为 null

## 修复措施
修改测试脚本 `TestCobraTotemRuntime.gd`，将单位放置位置更改为已解锁的位置:

**修改前:**
```gdscript
var lure_snake = await place_test_unit(unit_key, -2, 0)
var medusa = await place_test_unit(unit_key, 2, 0)
```

**修改后:**
```gdscript
var lure_snake = await place_test_unit(unit_key, -1, 0)  # 左侧解锁位置
var medusa = await place_test_unit(unit_key, 1, 0)       # 右侧解锁位置
```

## 测试结果
- [x] lure_snake 放置测试: PASS
- [x] lure_snake 攻击测试: PASS
- [x] lure_snake 受击测试: PASS
- [x] medusa 放置测试: PASS
- [x] medusa 攻击测试: PASS
- [x] medusa 受击测试: PASS

## 经验教训
1. **测试前检查网格状态** - 在编写放置单位的测试时，应先确认目标位置是否已解锁
2. **GridManager 初始化逻辑** - 了解 `create_initial_grid()` 中定义的初始网格状态
3. **错误诊断方法** - 当 place_unit 返回 false 时，应检查:
   - tile 是否存在
   - tile 状态是否为 "unlocked"
   - tile 是否已被其他单位占用
   - 是否有障碍物

## 相关文件
- `/home/zhangzhan/tower-html/src/Scripts/Tests/TestCobraTotemRuntime.gd` - 测试脚本
- `/home/zhangzhan/tower-html/src/Scripts/GridManager.gd` - 网格管理器，第 603-662 行定义初始网格状态
- `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/LureSnake.gd` - lure_snake 行为脚本（无问题）
- `/home/zhangzhan/tower-html/data/game_data.json` - 单位数据配置（无问题）
