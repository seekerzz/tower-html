# 塔防游戏机制总结文档

## 1. 游戏概述

这是一个基于Godot引擎开发的网格塔防游戏，融合了自走棋元素。玩家在一个9x9的网格上放置单位，抵御波次敌人的进攻，保护中央核心。

### 核心玩法
- **网格系统**: 60px瓷砖，9x9地图，中央核心区域半径2格
- **单位等级**: 所有单位最高3级，通过合并升级
- **法力系统**: 用于主动技能和部分单位攻击
- **核心生命值**: 基础500HP，必须保护
- **波次系统**: 敌人HP随波次增长(100 + wave*80)，速度(40 + wave*2)
- **商店系统**: 购买新单位

## 2. 单位系统架构

### 2.1 核心单位类
文件: `/home/zhangzhan/tower-html/src/Scripts/Unit.gd`

关键属性:
- `type_key`: String - 单位标识符
- `level`: int (1-3) - 当前等级
- `stats_multiplier`: float - 伤害/HP缩放
- `unit_data`: Dictionary - 合并自Constants + levels的数据
- `behavior`: UnitBehavior - 自定义行为实例
- `grid_pos`: Vector2i - 网格坐标
- `damage`, `range_val`, `atk_speed`: float - 战斗属性

### 2.2 单位数据结构 (game_data.json)
```json
{
  "name": "显示名称",
  "icon": "Emoji",
  "size": [1, 1],
  "range": 250,
  "atkSpeed": 1.5,
  "manaCost": 0,
  "attackType": "ranged",  // "ranged", "melee", "none", "mimic"
  "proj": "pinecone",
  "levels": {
    "1": { "damage": 300, "hp": 500, "cost": 250, "mechanics": {} },
    "2": { "damage": 450, "hp": 750, "cost": 500, "mechanics": {"crit_rate_bonus": 0.1} },
    "3": { "damage": 675, "hp": 1125, "cost": 1000, "mechanics": {"crit_rate_bonus": 0.2, "multi_shot_chance": 0.3} }
  }
}
```

### 2.3 添加新单位的步骤

1. **创建行为脚本** (如需要):
   - 路径: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/{UnitName}.gd`
   - 继承 `DefaultBehavior` 或 `UnitBehavior`
   - 覆盖方法以实现自定义行为

2. **添加到 game_data.json**:
   - 在 `UNIT_TYPES` 对象中添加条目
   - 定义基础属性和3个等级
   - 在等级定义中包含mechanics

3. **单位行为自动加载**:
   ```gdscript
   var behavior_name = type_key.to_pascal_case()
   var path = "res://src/Scripts/Units/Behaviors/%s.gd" % behavior_name
   ```

## 3. 行为系统

### 3.1 基础行为类
文件: `/home/zhangzhan/tower-html/src/Scripts/Units/UnitBehavior.gd`

虚拟方法:
```gdscript
func on_setup()                          # 单位初始化
func on_tick(delta: float)               # 每帧（非战斗）
func on_combat_tick(delta: float) -> bool # 返回true以覆盖默认攻击
func on_skill_activated()                # 主动技能触发
func on_skill_executed_at(grid_pos)      # 点目标技能
func on_damage_taken(amount, source) -> float  # 返回修改后的伤害
func on_projectile_hit(target, damage, projectile)  # 弹丸命中回调
func on_stats_updated()                  # 属性重新计算
func broadcast_buffs()                   # 向邻居应用增益
func get_trap_type() -> String           # 放置陷阱的单位
func on_cleanup()                        # 单位销毁前
```

### 3.2 行为类型

1. **DefaultBehavior** - 使用Unit.gd默认攻击逻辑
2. **Custom Combat Behaviors** - 覆盖 on_combat_tick
3. **FlyingMeleeBehavior** - 复杂近战，带视觉飞行路径
4. **BuffProviderBehavior** - 自动向邻居单位应用增益
5. **特殊行为** - Spider, Dragon, Phoenix, Cow, Snowman等

## 4. 核心机制系统

### 4.1 基础核心机制类
文件: `/home/zhangzhan/tower-html/src/Scripts/CoreMechanics/CoreMechanic.gd`

虚拟方法:
```gdscript
func on_wave_started()
func on_core_damaged(amount: float)
func on_damage_dealt_by_unit(unit, amount: float)
func on_projectile_crit(projectile, target)
func get_stat_modifier(stat_type: String, context: Dictionary) -> float
```

### 4.2 已实现的核心机制
- **MechanicViperTotem** - 定期对最远敌人降下毒液
- **MechanicButterflyTotem** - 环绕法球
- **MechanicEagleTotem** - 暴击回响(30%概率再次触发)
- **MechanicCowTotem** - 受伤充能，定期全屏反击
- **MechanicBatTotem** - 流血标记，攻击流血敌人回血
- **MechanicMoonWell** - 储存伤害转化为治疗
- **MechanicHolySword** - 必定暴击充能
- **MechanicAbundance** - 波次法力奖励
- **MechanicGeneral** - 通用属性修改器

## 5. 弹丸系统

### 5.1 基础弹丸
文件: `/home/zhangzhan/tower-html/src/Scripts/Projectiles/BaseProjectile.gd`

### 5.2 主弹丸类
文件: `/home/zhangzhan/tower-html/src/Scripts/Projectile.gd`

特性:
- **类型**: pinecone, stinger, ink, web, fire, lightning, roar, feather, meteor, black_hole_field
- **属性**: pierce(穿透), bounce(弹射), split(分裂), chain(连锁), damage_type, is_critical
- **效果**: Burn, Poison, Slow, Bleed 通过 `apply_payload()` 应用

## 6. 敌人系统

### 6.1 敌人类
文件: `/home/zhangzhan/tower-html/src/Scripts/Enemy.gd`

属性:
- type_key, hp, max_hp, speed
- state: MOVE, ATTACK_BASE, STUNNED, SUPPORT
- mass, knockback_resistance, knockback_velocity

### 6.2 敌人行为
文件: `/home/zhangzhan/tower-html/src/Scripts/Enemies/Behaviors/`

- **DefaultBehavior** - 寻路到核心，近战/远程攻击
- **BossBehavior** - 带特殊攻击的强化版
- **SuicideBehavior** - 冲锋并爆炸
- **MutantSlimeBehavior** - 受击时分裂

### 6.3 敌人类型
- 基础: slime, poison, wolf
- 坦克: treant, yeti, golem, crab
- 远程: shooter, archer_rat
- 特殊: mutant_slime(分裂), healer(治疗)

## 7. 效果系统

### 7.1 状态效果基类
文件: `/home/zhangzhan/tower-html/src/Scripts/Effects/StatusEffect.gd`

效果类型:
- **BurnEffect** - 持续伤害，死亡时爆炸(死亡回响)
- **PoisonEffect** - 持续伤害，可无限叠加
- **SlowEffect** - 降低敌人速度
- **BleedEffect** - 持续伤害，吸血协同

## 8. 现有单位列表

### 8.1 远程单位
| 单位 | 攻击类型 | 特殊机制 | 技能 |
|------|----------|----------|------|
| Squirrel(松鼠) | 快速射击 | L3有多重射击几率 | - |
| Bee(蜜蜂) | 穿透(3) | 高暴击率(20%) | - |
| Octopus(八爪鱼) | 散射(5) | 多重射击增益交互 | - |
| Scorpion(蝎子) | 远程 | 部署时放置尖牙陷阱 | - |
| Tiger(猛虎) | 远程 | 流星雨技能 | 主动:流星风暴 |
| Lion(狮子) | 远程 | AOE溅射伤害 | - |
| Butterfly(蝴蝶) | 法力攻击 | 每次攻击消耗法力 | - |
| Eel(电鳗) | 连锁闪电 | 连锁4个敌人，法力消耗 | - |
| Spider(蜘蛛) | 网射击 | 命中几率放置粘液陷阱 | - |
| Woodpecker(啄木鸟) | 快速啄击 | 对同一目标叠加伤害 | - |
| Oxpecker(牛椋鸟) | 远程 | 可附身其他单位 | - |
| FairyDragon(精灵龙) | 魔法弹 | 命中时传送敌人 | - |
| Peacock(孔雀) | 羽毛 | 第4次收回拉扯敌人 | - |

### 8.2 近战单位
| 单位 | 特殊机制 | 技能 |
|------|----------|------|
| Dog(恶霸犬) | 溅射伤害，狂暴技能 | 主动:狂暴(增益) |
| Bear(暴怒熊) | 攻击晕眩 | 主动:震慑 |
| Hedgehog(刺猬) | 30%反伤 | - |
| IronTurtle(铁甲龟) | 固定减伤20 | - |
| Viper(毒蛇) | 部署时放置毒陷阱 | - |
| ArrowFrog(箭毒蛙) | 斩杀低生命值敌人 | - |
| Eagle(老鹰) | 飞行近战，攻击最远敌人，满血双倍伤害 | - |

### 8.3 辅助/增益单位
| 单位 | 增益类型 | 机制 |
|------|----------|------|
| Torch(红莲火炬) | Fire | 邻接单位附加燃烧 |
| Cauldron(剧毒大锅) | Poison | 邻接单位附加中毒 |
| Drum(战鼓) | Speed | 邻接攻速+20% |
| Mirror(反射魔镜) | Bounce | 邻接子弹弹射+1 |
| Splitter(多重棱镜) | Split | 邻接子弹分裂+1 |
| Rabbit(兔子) | Bounce | 点击给予弹射增益 |
| LuckyCat(招财猫) | Wealth | 邻接击杀获金 |
| Plant(向日葵) | Mana | +60法力/秒 |
| Cow(奶牛) | Heal | 每5秒治疗核心50 |
| Snowman(雪人) | Trap | 生成冰冻陷阱 |
| Meat(五花肉) | Food | 可被吞噬获得经验 |

### 8.4 特殊单位
| 单位 | 机制 |
|------|------|
| Dragon(龙) | 黑洞技能(点目标) |
| Phoenix(凤凰) | 火雨技能(点目标AOE) |
| Parrot(鹦鹉) | 模仿邻居弹丸(最多5-10发) |

## 9. 核心类型

| 核心 | 名称 | 机制 |
|------|------|------|
| abundance | 丰饶图腾 | 每波获得法力补给 |
| moon_well | 月亮井 | 储存伤害转化为治疗 |
| holy_sword | 圣剑图腾 | 每波获得圣剑 |
| cow_totem | 牛图腾 | 受伤充能，5秒一次全屏反击 |
| bat_totem | 蝙蝠图腾 | 每5秒攻击3个最近敌人，施加流血标记 |
| viper_totem | 毒蛇图腾 | 每5秒对最远3个敌人降下毒液 |
| butterfly_totem | 蝴蝶图腾 | 生成3颗环绕法球，无限穿透 |
| eagle_totem | 鹰之图腾 | 暴击时30%概率触发回响 |

## 10. 障碍类型

| 障碍 | 名称 | 类型 | 特性 |
|------|------|------|------|
| mucus | 粘液网 | slow | 减速30% |
| poison | 毒雾 | poison | 免疫，200伤害 |
| fang | 荆棘 | reflect | 反弹100伤害 |
| snowball_trap | 雪球陷阱 | trap_freeze | 3秒后爆炸，冻结3x3范围 |

## 11. 关键架构模式

1. **行为模式** - 单位将逻辑委托给行为类
2. **事件驱动** - GameManager全局事件信号
3. **组件化** - VisualController处理所有动画
4. **数据驱动** - 所有单位/敌人属性在JSON中
5. **网格空间系统** - GridManager处理瓷砖操作

## 12. 开发注意事项

### 12.1 已有陷阱/坑
1. **行为脚本命名**: 必须使用帕斯卡命名法(PascalCase)，与type_key匹配
2. **Projectile类型**: 新增自定义弹丸需要在Projectile.gd中添加处理逻辑
3. **技能系统**: 点目标技能需要设置skillType为"point"和targetArea
4. **Buff系统**: BuffProviderBehavior自动处理邻接增益
5. **效果系统**: 状态效果需要继承StatusEffect并实现apply方法

### 12.2 调试建议
1. 使用仿照MainGame的测试场景进行运行时测试
2. 测试必须验证: 放置、攻击敌人、被敌人攻击三个环节
3. CombatManager处理伤害计算和效果应用
4. 运行Godot进行完整测试，检查运行时报错

## 13. 测试规范

### 13.1 测试要求
每个单位必须通过以下运行时测试：

| 测试项 | 说明 | 验证方式 |
|--------|------|----------|
| 放置测试 | 单位能正确放置在棋盘上 | 无报错，单位显示正常 |
| 攻击测试 | 单位能正确攻击敌人 | 敌人受到伤害，技能效果触发 |
| 受击测试 | 单位被攻击时逻辑正确 | 单位受到伤害/减伤/反击等机制正常 |

### 13.2 测试步骤
1. 创建测试场景（仿照MainGame.tscn结构）
2. 实例化被测单位并放置
3. 生成测试敌人
4. 运行Godot进行实际测试
5. 检查控制台输出是否有报错
6. 验证单位行为是否符合设计

### 13.3 测试场景结构
```
TestScene (Node2D)
├── GridManager (GridManager.tscn)
├── CombatManager (CombatManager.tscn)
├── DrawManager (DrawManager.tscn)
└── TestController (Script)
    ├── 生成测试单位
    ├── 生成测试敌人
    └── 验证测试结果
```
