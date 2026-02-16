# 牛图腾系列测试 - 踩过的坑

记录时间: 2026-02-16T14:14:16

## 测试执行注意事项

1. **GridManager 初始化**: 测试前需要确保 GridManager 的 tiles 已正确初始化
2. **GameManager 引用**: 需要设置 GameManager.grid_manager 和 GameManager.combat_manager
3. **单位放置**: 使用 UNIT_SCENE.instantiate() 和 unit.setup(type_key) 创建单位
4. **行为脚本加载**: 行为脚本通过 `type_key.to_pascal_case()` 自动加载
5. **等待帧**: 单位放置后需要等待一帧确保初始化完成

## 各单位测试要点

### Yak Guardian
- 使用 broadcast_buffs() 给邻居添加 guardian_shield buff
- 减伤效果在 Unit.gd 的 take_damage 中处理

### Mushroom Healer
- 需要监控 GameManager.core_health 变化来检测治疗
- 使用 delayed_heal_queue 存储延迟回血

### Rock Armor Cow
- 护盾通过 on_damage_taken 优先吸收伤害
- 脱战计时器在 on_tick 中处理

### Cow Golem
- 受击计数在 on_damage_taken 中累加
- 达到阈值时触发 _trigger_shockwave()

