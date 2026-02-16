# 鹰图腾系列测试 - 踩过的坑

## 测试时间
2026-02-16T10:04:35

## 测试过程中遇到的问题

### 1. 单位放置位置选择
**问题**: 初始测试时选择了(-2, -2)等位置，但初始网格只有中心3x3区域是解锁的
**解决**: 改为使用(0, -1), (-1, 0), (1, 0), (0, 1)等中心区域位置

### 2. Godot Headless模式限制
**问题**: 在headless模式下运行时，`set_instance_shader_parameter`等渲染相关功能不可用
**影响**: 产生大量错误日志，但不影响游戏逻辑测试
**解决**: 忽略这些错误，专注于游戏逻辑测试

### 3. GaleEagle的await冲突
**问题**: GaleEagle.gd在`_do_wind_blade_attack`中使用了`await`，在测试时可能导致崩溃
**代码位置**: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/GaleEagle.gd:53`
**现象**: 测试在gale_eagle放置后崩溃
**建议**: 在测试环境中减少等待时间，或考虑使用同步测试方法

### 4. Vulture的初始化时序问题
**问题**: Vulture.gd的`_connect_to_enemy_deaths`在`on_setup`中直接调用`get_tree()`，可能返回null
**代码位置**: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/Vulture.gd:36`
**建议修复**:
```gdscript
func _connect_to_enemy_deaths():
    if not is_inside_tree():
        return
    var tree = get_tree()
    if not tree:
        return
    var enemies = tree.get_nodes_in_group("enemies")
    # ...
```

### 5. 测试脚本并发问题
**问题**: 测试脚本使用await，与被测单位的await可能产生冲突
**解决**: 增加测试之间的延迟时间，确保每个测试完全结束后再开始下一个

## 给后续开发者的建议

1. **网格位置选择**: 测试单位放置时，确保选择已解锁的格子。初始只有中心3x3区域(坐标范围-1到1)是解锁的。

2. **Headless模式测试**: 在headless模式下运行时，忽略shader相关的错误。这些错误不影响游戏逻辑测试。

3. **使用await的单位**: 对于使用await进行动画控制的单位(如GaleEagle)，测试时需要特别小心，可能需要:
   - 减少等待时间
   - 使用更长的测试间隔
   - 考虑禁用动画进行纯逻辑测试

4. **get_tree()调用**: 在单位行为脚本的`on_setup`中调用`get_tree()`时，始终添加null检查:
   ```gdscript
   if not is_inside_tree() or not get_tree():
       return
   ```

5. **部分结果保存**: 由于Godot可能崩溃，建议在每次测试后立即保存结果，而不是等所有测试完成。

6. **测试超时设置**: 为Godot测试设置合理的超时时间(建议180-250秒)，防止无限等待。

## 测试文件位置
- 测试场景: `/home/zhangzhan/tower-html/src/Scenes/Tests/TestEagleTotemRuntime.tscn`
- 测试脚本: `/home/zhangzhan/tower-html/src/Scripts/Tests/TestEagleTotemRuntime.gd`
- 测试结果: `/home/zhangzhan/tower-html/tasks/eagle_totem_units/runtime_test_result.md`
