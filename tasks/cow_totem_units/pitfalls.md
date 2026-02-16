# 牛图腾系列测试 - 踩过的坑

记录时间: 2026-02-16T09:52:34

## 测试执行注意事项

1. **GridManager 初始化**: 测试前需要确保 GridManager 的 tiles 已正确初始化
2. **GameManager 引用**: 需要设置 GameManager.grid_manager 和 GameManager.combat_manager
3. **单位放置**: 使用 UNIT_SCENE.instantiate() 和 unit.setup(type_key) 创建单位
4. **行为脚本加载**: 行为脚本通过 `type_key.to_pascal_case()` 自动加载
5. **等待帧**: 单位放置后需要等待一帧确保初始化完成
6. **网格坐标范围**: 地图是9x9的，中心在(0,0)，有效坐标范围是-4到4

## 遇到的问题及解决方案

### 问题1: 无效网格位置
- **现象**: 放置单位时报错 "无效的网格位置 (6, 2)"
- **原因**: 地图是9x9的，坐标范围是-4到4，(6,2)超出了范围
- **解决**: 使用有效坐标如 (1,1), (-1,1), (2,1), (3,1)

### 问题2: 辅助单位攻击测试判定
- **现象**: yak_guardian攻击测试显示FAIL
- **原因**: yak_guardian是辅助单位，attackType为"none"，没有传统攻击
- **解决**: 对于辅助单位，测试其辅助机制（如broadcast_buffs）视为攻击测试通过

### 问题3: Headless模式下的Shader错误
- **现象**: 运行测试时出现大量 "SHADER ERROR" 和 "set_instance_shader_parameter" 错误
- **原因**: Headless模式不支持某些shader特性
- **解决**: 这些错误不影响功能测试，可以忽略

## 各单位测试要点

### Yak Guardian (牦牛守护)
- 使用 broadcast_buffs() 给邻居添加 guardian_shield buff
- 减伤效果在 Unit.gd 的 take_damage 中处理
- 辅助单位，没有传统攻击能力

### Mushroom Healer (菌菇治愈者)
- 需要监控 GameManager.core_health 变化来检测治疗
- 使用 delayed_heal_queue 存储延迟回血
- 技能可立即释放所有存储的治疗量

### Rock Armor Cow (岩甲牛)
- 护盾通过 on_damage_taken 优先吸收伤害
- 脱战计时器在 on_tick 中处理
- 护盾最大值为 max_hp * shield_percent

### Cow Golem (牛魔像)
- 受击计数在 on_damage_taken 中累加
- 达到阈值时触发 _trigger_shockwave()
- 震荡反击会对全屏敌人造成晕眩效果

## 测试验证清单

- [x] yak_guardian - 放置测试
- [x] yak_guardian - 辅助机制测试 (broadcast_buffs)
- [x] yak_guardian - 受击机制测试
- [x] mushroom_healer - 放置测试
- [x] mushroom_healer - 过量治疗转化测试
- [x] mushroom_healer - 受击机制测试
- [x] rock_armor_cow - 放置测试
- [x] rock_armor_cow - 护盾生成测试
- [x] rock_armor_cow - 护盾吸收伤害测试
- [x] cow_golem - 放置测试
- [x] cow_golem - 受击计数测试
- [x] cow_golem - 震荡反击测试

