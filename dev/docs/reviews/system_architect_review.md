# 系统架构审核报告

**审核人**: 陈睿 (System Architect)
**审核日期**: 2026-02-19
**审核范围**: docs/jules_prompts/ 目录下全部10个Prompt文件

---

## 执行摘要

本次审核涵盖10个Jules Prompts，涉及4个基础系统(P0)和6个单位实现包(P1)。经分析，整体技术架构可行，但需要严格遵循执行顺序和依赖关系。主要风险集中在JSON配置冲突、信号循环依赖和并行执行时的文件冲突。

### 关键发现

| 类别 | 数量 | 说明 |
|------|------|------|
| 高可行性 | 8个 | 可直接实现，依赖清晰 |
| 有条件可行 | 2个 | 需要前置系统完成后实现 |
| 高风险冲突 | 3处 | JSON配置、信号系统、文件并发 |
| 阻塞依赖 | 4个 | P0系统为P1单位的前置条件 |

### 推荐执行策略

```
Phase 1 (P0基础系统 - 串行):
  P0_01 (狼图腾魂魄系统) -> P0_04 (流血吸血系统) -> P0_02 (嘲讽系统) -> P0_03 (召唤系统)

Phase 2 (P1单位实现 - 按图腾并行):
  狼图腾单位组 (P1_01)
  眼镜蛇单位组 (P1_02)
  蝙蝠单位组 (P1_03) [依赖P0_04]
  蝴蝶单位组 (P1_04)
  鹰单位组 (P1_05)
  牛图腾单位组 (P1_06) [依赖P0_02]
```

---

## 一、P0基础系统审核

### 1.1 P0_01: 狼图腾魂魄系统

#### 技术可行性
- **可行性**: 可行
- **主要技术点**:
  - Godot Autoload单例模式实现SoulManager
  - 信号系统(soul_count_changed)实现UI更新
  - 敌人死亡事件集成

#### 架构方案
```gdscript
# 推荐的代码结构
class_name SoulManager
extends Node

signal soul_count_changed(new_count: int, delta: int)

var current_souls: int = 0
var max_souls: int = 999

func add_souls_from_enemy_death(enemy_data: Dictionary) -> void:
    var gain = calculate_soul_gain(enemy_data)
    current_souls = min(current_souls + gain, max_souls)
    soul_count_changed.emit(current_souls, gain)
```

#### 依赖清单
- [x] GameManager (已存在)
- [x] Enemy.gd (已存在，需添加死亡事件绑定)
- [x] UnitDragHandler.gd (已存在，需添加合并事件)
- [ ] MechanicWolfTotem.gd (需要创建)

#### 接口设计
| 接口 | 输入 | 输出 | 说明 |
|-----|------|------|------|
| add_souls_from_enemy_death | enemy_data: Dictionary | void | 敌人死亡时调用 |
| add_souls_from_unit_merge | unit_data: Dictionary | void | 单位合并时调用 |
| get_soul_damage_bonus | - | float | 获取当前魂魄伤害加成 |
| consume_souls | amount: int | bool | 消耗魂魄(如有需要) |

#### Jules执行建议
- **拆分策略**: 垂直拆分 - 数据层(SoulManager) -> 逻辑层(图腾机制) -> 表现层(UI)
- **执行顺序**: 必须在所有狼图腾单位之前完成
- **预估冲突**:
  - data/game_data.json: 需要添加wolf_totem配置
  - Enemy.gd: 需要在die()方法中添加魂魄获取调用

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 魂魄数波次持久化 | 中 | 在GameManager中保存/恢复 |
| 大量敌人同时死亡 | 低 | 使用批量更新，避免每敌人都发信号 |
| JSON配置冲突 | 中 | 使用独立配置段，避免与其他图腾配置冲突 |

---

### 1.2 P0_02: 嘲讽/仇恨系统

#### 技术可行性
- **可行性**: 可行，但需注意与现有Enemy系统的集成
- **主要技术点**:
  - AggroManager管理敌人-目标映射
  - 敌人AI修改以支持嘲讽优先级
  - 空间分区优化性能

#### 架构方案
```gdscript
# 推荐的代码结构
class_name AggroManager
extends Node

var enemy_targets: Dictionary = {}  # {enemy_id: target_unit}
var taunting_units: Array[Unit] = []

signal target_changed(enemy: Enemy, new_target: Unit)
signal taunt_started(unit: Unit, radius: float)
signal taunt_ended(unit: Unit)

func apply_taunt(unit: Unit, radius: float, duration: float = -1):
    taunting_units.append(unit)
    _update_enemy_targets_in_radius(unit.global_position, radius)
    taunt_started.emit(unit, radius)
```

#### 依赖清单
- [x] Enemy.gd (需要修改目标选择逻辑)
- [x] Unit.gd (基础单位类)
- [ ] TauntBehavior.gd (需要创建)
- [ ] yak_guardian单位 (依赖此系统)

#### 接口设计
| 接口 | 输入 | 输出 | 说明 |
|-----|------|------|------|
| register_enemy | enemy: Enemy | void | 注册新敌人 |
| get_target_for_enemy | enemy: Enemy | Unit | 获取敌人目标 |
| apply_taunt | unit, radius, duration | void | 开启嘲讽 |
| remove_taunt | unit: Unit | void | 移除嘲讽 |

#### Jules执行建议
- **拆分策略**: 水平拆分 - AggroManager -> Enemy修改 -> TauntBehavior -> 牦牛守护
- **执行顺序**: 必须在P1_06(牛图腾单位)之前完成
- **预估冲突**:
  - Enemy.gd: 需要修改目标选择逻辑，可能与其他修改冲突
  - 现有敌人行为可能需要调整

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 性能问题(大量敌人) | 中 | 使用空间分区或定期更新而非每帧 |
| 信号循环 | 高 | 避免在target_changed中触发新的目标变更 |
| 多嘲讽单位冲突 | 中 | 明确优先级规则(最近距离) |

---

### 1.3 P0_03: 召唤物系统

#### 技术可行性
- **可行性**: 可行
- **主要技术点**:
  - SummonedUnit继承Unit基类
  - 生命周期管理(Timer)
  - 属性继承(克隆体)

#### 架构方案
```gdscript
# 推荐的代码结构
class_name SummonedUnit
extends Unit

@export var lifetime: float = 30.0
@export var is_clone: bool = false
@export var summon_source: Unit = null

var lifetime_timer: Timer
signal summon_expired(summon: SummonedUnit)
signal summon_killed(summon: SummonedUnit)

func _ready():
    super._ready()
    if lifetime > 0:
        _setup_lifetime_timer()
    modulate = Color(1, 1, 1, 0.7)  # 视觉区分
```

#### 依赖清单
- [x] Unit.gd (基础类)
- [ ] SummonManager.gd (需要创建)
- [ ] SummonedUnit.tscn (需要创建场景)
- [ ] P1_01中的羊灵 (依赖此系统)
- [ ] 蜘蛛Lv3 (依赖此系统)

#### 接口设计
| 接口 | 输入 | 输出 | 说明 |
|-----|------|------|------|
| create_summon | summon_data: Dictionary | SummonedUnit | 创建召唤物 |
| get_summons_by_source | source: Unit | Array[SummonedUnit] | 获取来源的召唤物 |
| clear_all_summons | - | void | 清除所有召唤物 |

#### Jules执行建议
- **拆分策略**: 垂直拆分 - SummonManager -> SummonedUnit -> 具体召唤物实现
- **执行顺序**: 必须在P1_01(羊灵)和蜘蛛Lv3之前完成
- **预估冲突**: 较低，主要创建新文件

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 召唤物数量失控 | 中 | 实现max_summons_per_source限制 |
| 核心血量计算 | 中 | 确保召唤物不增加核心血量 |
| 场景树组织 | 低 | 明确召唤物的父节点 |

---

### 1.4 P0_04: 流血吸血联动系统

#### 技术可行性
- **可行性**: 可行
- **主要技术点**:
  - 流血Debuff层数系统
  - LifestealManager处理吸血逻辑
  - 蝙蝠图腾机制集成

#### 架构方案
```gdscript
# 推荐的代码结构
class_name LifestealManager
extends Node

@export var base_lifesteal_ratio: float = 0.5

func _ready():
    GameManager.damage_dealt.connect(_on_damage_dealt)

func _on_damage_dealt(source: Node, target: Enemy, damage: float):
    if target.bleed_stacks <= 0:
        return
    if not _is_under_bat_totem_influence(source):
        return

    var lifesteal_amount = target.bleed_stacks * 2.0 * base_lifesteal_ratio
    GameManager.heal_core(lifesteal_amount)
```

#### 依赖清单
- [x] Enemy.gd (需要添加bleed_stacks)
- [x] GameManager (已存在)
- [ ] LifestealManager.gd (需要创建)
- [ ] MechanicBatTotem.gd (需要更新)
- [ ] P1_03蝙蝠单位 (依赖此系统)

#### 接口设计
| 接口 | 输入 | 输出 | 说明 |
|-----|------|------|------|
| add_bleed_stacks | stacks: int | void | 添加流血层数 |
| get_lifesteal_amount | - | float | 获取可吸血量 |
| _is_under_bat_totem_influence | source: Node | bool | 检查吸血资格 |

#### Jules执行建议
- **拆分策略**: 水平拆分 - 流血系统 -> 吸血管理器 -> 蝙蝠图腾更新
- **执行顺序**: 必须在P1_03(蝙蝠单位)之前完成
- **预估冲突**:
  - Enemy.gd: 需要添加bleed_stacks属性
  - data/game_data.json: 需要更新蝙蝠图腾配置

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 吸血计算性能 | 低 | 每次伤害事件计算，数量可控 |
| 多层流血平衡 | 中 | 需要测试50层流血时的吸血效果 |
| 与现有效果系统冲突 | 中 | 复用现有的Effect系统架构 |

---

## 二、P1单位实现审核

### 2.1 P1_01: 狼图腾单位群

#### 技术可行性
- **可行性**: 有条件可行(依赖P0_01, P0_03)
- **单位列表**: 血食、猛虎、恶霸犬、狼、鬣狗、狐狸、羊灵、狮子

#### 架构方案
```gdscript
# 示例：狼的吞噬机制
class_name UnitWolf
extends Unit

var consumed_unit_data: Dictionary = {}

func on_target_selected(target_unit: Unit):
    _devour_unit(target_unit)
    SoulManager.add_souls(10)  # 吞噬获得魂魄

func _devour_unit(target: Unit):
    base_damage += target.damage * 0.5
    max_hp += target.max_hp * 0.5
    consumed_unit_data = {"unit_id": target.type_key}
    target.queue_free()
```

#### 依赖清单
- [ ] P0_01狼图腾魂魄系统 (阻塞依赖)
- [ ] P0_03召唤物系统 (羊灵需要)
- [ ] SoulManager (魂魄获取)

#### 特殊机制分析
| 单位 | 特殊机制 | 实现复杂度 |
|------|----------|------------|
| 狼 | 吞噬继承 | 高 - 需要UI选择目标 |
| 羊灵 | 召唤克隆体 | 中 - 依赖召唤系统 |
| 狐狸 | 魅惑敌人 | 高 - 需要修改敌人AI |
| 猛虎 | 血魂暴击 | 低 - 纯数值计算 |

#### Jules执行建议
- **拆分策略**: 按单位并行，但狼和羊灵需要等待前置系统
- **执行顺序**: 等待P0_01完成后，血食/猛虎/恶霸犬/鬣狗/狮子可并行；狼和羊灵需额外等待
- **预估冲突**:
  - data/game_data.json: 8个单位配置
  - src/Scripts/Units/Behaviors/: 多个行为脚本

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 狼的吞噬UI | 高 | 需要设计目标选择模式 |
| 狐狸魅惑 | 高 | 需要修改敌人目标 faction |
| 羊灵克隆体属性继承 | 中 | 明确继承规则和视觉效果 |

---

### 2.2 P1_02: 眼镜蛇单位群

#### 技术可行性
- **可行性**: 可行
- **单位列表**: 老鼠、蟾蜍 + 美杜莎Lv3完善

#### 架构方案
```gdscript
# 老鼠的瘟疫传播
class_name UnitRat
extends Unit

func _on_debuff_applied(enemy: Enemy, debuff_type: String):
    if debuff_type == "poison":
        enemy.set_meta("plague_infected", true)
        enemy.tree_exited.connect(_on_plagued_enemy_died.bind(enemy))

func _on_plagued_enemy_died(enemy: Enemy):
    var nearby = get_enemies_in_radius(enemy.global_position, 100.0)
    for e in nearby:
        e.add_poison_stacks(3)
```

#### 依赖清单
- [x] 现有毒系统 (已存在)
- [x] Enemy.gd (已存在)
- [ ] DistanceDamageDebuff.gd (需要创建)

#### Jules执行建议
- **拆分策略**: 老鼠和蟾蜍可并行
- **执行顺序**: 无特殊依赖，可在P0完成后随时执行
- **预估冲突**: 较低

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 瘟疫传播链式反应 | 中 | 设置传播上限或免疫时间 |
| 蟾蜍陷阱管理 | 低 | 限制最大陷阱数量 |

---

### 2.3 P1_03: 蝙蝠图腾单位群

#### 技术可行性
- **可行性**: 有条件可行(依赖P0_04)
- **单位列表**: 石像鬼、生命链条、鲜血圣杯、血祭术士 + 蚊子/血法师Lv3

#### 架构方案
```gdscript
# 石像鬼的石化状态
class_name UnitGargoyle
extends Unit

enum State { NORMAL, PETRIFIED }
var current_state: State = State.NORMAL

func _check_petrify_state():
    var health_percent = GameManager.core_health / GameManager.max_core_health
    if health_percent < 0.3 and current_state == State.NORMAL:
        _enter_petrified_state()

func _enter_petrified_state():
    current_state = State.PETRIFIED
    can_attack = false
    reflect_count = level  # Lv1=1, Lv2=2, Lv3=3
```

#### 依赖清单
- [ ] P0_04流血吸血系统 (阻塞依赖)
- [ ] LifestealManager (需要存在)
- [x] GameManager (已存在)

#### Jules执行建议
- **拆分策略**: 必须等待P0_04完成后执行
- **执行顺序**: P0_04 -> 蝙蝠单位群
- **预估冲突**:
  - Unit_mosquito.gd: 需要修改
  - Unit_blood_mage.gd: 需要修改

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 血祭术士消耗核心HP | 中 | 需要二次确认UI |
| 生命链条性能 | 中 | 定期更新而非每帧计算 |
| 鲜血圣杯溢出追踪 | 低 | 使用元数据存储 |

---

### 2.4 P1_04: 蝴蝶图腾单位群

#### 技术可行性
- **可行性**: 可行
- **单位列表**: 冰晶蝶、萤火虫、木精灵 + 蝴蝶/凤凰/龙Lv3

#### 架构方案
```gdscript
# 萤火虫的致盲
class_name UnitFirefly
extends Unit

func _on_apply_blind(enemy: Enemy, damage: float):
    enemy.apply_blind(blind_duration)

    if level >= 3:
        enemy.attack_missed.connect(_on_enemy_miss)

func _on_enemy_miss(enemy: Enemy):
    if level >= 3:
        GameManager.add_mana(10)
```

#### 依赖清单
- [x] 现有冻结系统 (已存在)
- [ ] 致盲Debuff (需要添加到Enemy)
- [x] MechanicButterflyTotem.gd (已存在，需要修改)

#### Jules执行建议
- **拆分策略**: 三个新单位可并行；Lv3完善需要修改现有文件
- **执行顺序**: 无特殊依赖
- **预估冲突**:
  - Enemy.gd: 需要添加致盲逻辑
  - Unit_butterfly.gd: 需要修改

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 致盲效果平衡 | 中 | 10%Miss率需要测试验证 |
| 木精灵被动触发 | 中 | 需要修改所有单位攻击逻辑 |
| 凤凰临时法球 | 低 | 确保10秒后正确清理 |

---

### 2.5 P1_05: 鹰图腾单位群

#### 技术可行性
- **可行性**: 可行
- **单位列表**: 红隼、猫头鹰、喜鹊、鸽子 + 角雕/疾风鹰/老鹰/秃鹫/啄木鸟Lv3

#### 架构方案
```gdscript
# 喜鹊的属性偷取
class_name UnitMagpie
extends Unit

enum StealType { ATTACK_SPEED, MOVE_SPEED, DEFENSE }

func _on_attack_steal(enemy: Enemy, damage: float):
    if randf() >= steal_chance:
        return

    var steal_type = StealType.values()[randi() % 3]
    var steal_amount = _calculate_steal_amount(enemy, steal_type)

    if level >= 2:
        steal_amount *= 1.5

    _apply_steal_effect(steal_type, steal_amount)
```

#### 依赖清单
- [x] 现有暴击系统 (已存在)
- [x] EventBus (已存在或需要创建)
- [ ] 眩晕效果 (红隼需要)

#### Jules执行建议
- **拆分策略**: 新单位可并行；Lv3完善串行
- **执行顺序**: 无特殊依赖
- **预估冲突**:
  - 多个现有单位文件需要修改
  - data/game_data.json: 4个新单位配置

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 眩晕效果实现 | 中 | 复用现有stun系统 |
| 属性偷取UI | 低 | 需要视觉反馈 |
| 鸽子闪避机制 | 中 | 需要优先于伤害计算 |

---

### 2.6 P1_06: 牛图腾单位群

#### 技术可行性
- **可行性**: 有条件可行(依赖P0_02)
- **单位列表**: 苦修者 + 树苗/铁甲龟/刺猬/牦牛守护/岩甲牛/牛椋鸟/菌菇/奶牛完善

#### 架构方案
```gdscript
# 苦修者的伤害转法力
class_name UnitAscetic
extends Unit

func _on_buffed_unit_damaged(amount: float, source: Node):
    var ratio = 0.10 if level < 2 else 0.15
    var mana_gain = amount * ratio
    GameManager.add_mana(mana_gain)

# 牦牛守护的嘲讽
func _ready():
    taunt_behavior = TauntBehavior.new()
    taunt_behavior.taunt_interval = 5.0 if level < 2 else 4.0
    add_child(taunt_behavior)
```

#### 依赖清单
- [ ] P0_02嘲讽/仇恨系统 (阻塞依赖)
- [ ] AggroManager (需要存在)
- [ ] TauntBehavior (需要存在)

#### Jules执行建议
- **拆分策略**: 必须等待P0_02完成后执行
- **执行顺序**: P0_02 -> 牛图腾单位群
- **预估冲突**:
  - 多个现有单位文件需要修改
  - 菌菇治愈者需要完全重写

#### 风险预警
| 风险 | 等级 | 缓解方案 |
|------|------|----------|
| 苦修者目标选择UI | 高 | 类似狼的吞噬，需要选择模式 |
| 菌菇治愈者重写 | 高 | 与现有实现完全不同 |
| 牦牛守护Lv3联动 | 中 | 需要图腾攻击事件 |
| 刺猬抛物线尖刺 | 中 | 需要物理模拟或Tween |

---

## 三、系统依赖图

```
P0基础系统层:
  P0_01 (狼图腾魂魄系统)
    ├── 被依赖: P1_01 (狼图腾单位)
    └── 修改: Enemy.gd, UnitDragHandler.gd, game_data.json

  P0_02 (嘲讽/仇恨系统)
    ├── 被依赖: P1_06 (牛图腾单位 - 牦牛守护)
    └── 修改: Enemy.gd, 新增AggroManager.gd

  P0_03 (召唤物系统)
    ├── 被依赖: P1_01 (羊灵)
    └── 新增: SummonManager.gd, SummonedUnit.gd

  P0_04 (流血吸血系统)
    ├── 被依赖: P1_03 (蝙蝠图腾单位)
    └── 修改: Enemy.gd, MechanicBatTotem.gd

P1单位实现层:
  P1_01 (狼图腾单位) - 依赖: P0_01, P0_03
  P1_02 (眼镜蛇单位) - 依赖: 无
  P1_03 (蝙蝠单位) - 依赖: P0_04
  P1_04 (蝴蝶单位) - 依赖: 无
  P1_05 (鹰单位) - 依赖: 无
  P1_06 (牛图腾单位) - 依赖: P0_02
```

---

## 四、Jules执行策略

### 4.1 执行顺序

```
第1波 (P0串行 - 必须按顺序):
1. P0_01 狼图腾魂魄系统
2. P0_04 流血吸血系统
3. P0_02 嘲讽/仇恨系统
4. P0_03 召唤物系统

第2波 (P1并行 - 按图腾分组):
组A: P1_01 狼图腾单位 (等待P0_01, P0_03)
组B: P1_02 眼镜蛇单位 (可立即执行)
组C: P1_03 蝙蝠单位 (等待P0_04)
组D: P1_04 蝴蝶单位 (可立即执行)
组E: P1_05 鹰单位 (可立即执行)
组F: P1_06 牛图腾单位 (等待P0_02)
```

### 4.2 冲突预测与缓解

#### 高风险冲突区域

| 文件 | 冲突类型 | 缓解方案 |
|------|----------|----------|
| data/game_data.json | JSON结构冲突 | 每个Prompt只添加自己的配置段，不修改其他段 |
| src/Scripts/Enemy.gd | 代码逻辑冲突 | 使用信号而非直接修改，预留扩展点 |
| src/Scripts/Unit.gd | 基类修改冲突 | 优先使用组合而非继承 |
| src/Autoload/GameManager.gd | 全局状态冲突 | 使用独立的管理器类 |

#### 并行执行建议

**可以并行的Prompts**:
- P1_02, P1_04, P1_05 (无依赖，修改不同文件)
- P1_01内部单位 (血食、猛虎、恶霸犬、鬣狗、狮子)
- P1_03内部单位 (石像鬼、生命链条、鲜血圣杯、血祭术士)

**必须串行的Prompts**:
- P0_01 -> P1_01 (狼)
- P0_04 -> P1_03 (蝙蝠)
- P0_02 -> P1_06 (牛)
- P0_03 -> P1_01羊灵

### 4.3 代码合并策略

```
分支策略:
main (基线分支 - 始终保持可运行)
  ├── feature/P0-01-soul-system
  ├── feature/P0-02-aggro-system
  ├── feature/P0-03-summon-system
  ├── feature/P0-04-lifesteal-system
  └── feature/P1-XX-... (各单位实现)

合并窗口:
1. 每个P0系统完成后立即合并到main
2. 每组P1单位完成后合并到main
3. 合并前必须运行测试验证
```

---

## 五、技术风险与缓解方案

### 5.1 高风险项

| 风险 | 影响 | 概率 | 缓解方案 |
|------|------|------|----------|
| 信号循环依赖 | 系统死锁 | 中 | 使用disconnect避免循环，设计时绘制信号流图 |
| JSON配置冲突 | 数据损坏 | 高 | 每个图腾独立配置段，合并时人工检查 |
| 敌人AI修改冲突 | 行为异常 | 中 | 使用AggroManager集中管理，避免分散修改 |
| 召唤物生命周期 | 内存泄漏 | 中 | 确保所有召唤物都有超时或清理机制 |
| 魂魄数溢出 | 数值异常 | 低 | 设置max_souls上限(999) |

### 5.2 性能风险

| 场景 | 风险 | 缓解方案 |
|------|------|----------|
| 大量敌人同时死亡 | 魂魄计算卡顿 | 批量处理，延迟到帧末执行 |
| 嘲讽范围检测 | 每帧检测开销大 | 使用空间分区或定期更新 |
| 生命链条连线 | 每帧重绘 | 使用Line2D节点，只在目标变化时更新 |
| 召唤物数量过多 | 帧率下降 | 限制每个来源的最大召唤数 |

### 5.3 架构建议

1. **信号使用规范**:
   - 使用信号进行系统间通信
   - 避免在信号处理函数中发射新信号(防止循环)
   - 信号命名规范: [动作]_[对象]_[时机] (如: enemy_died, taunt_started)

2. **数据存储规范**:
   - 游戏配置: data/game_data.json
   - 运行时状态: 各Manager单例
   - 单位特定数据: 使用set_meta/get_meta

3. **错误处理**:
   - 所有Manager使用is_instance_valid检查节点有效性
   - 单位被销毁时清理所有信号连接
   - 使用try-catch包装可能失败的调用

---

## 六、接口契约

### 6.1 SoulManager接口

```gdscript
# 信号
signal soul_count_changed(new_count: int, delta: int)

# 公共方法
func add_souls(amount: int, source: String) -> void
func get_soul_damage_bonus() -> float
func get_current_souls() -> int
```

### 6.2 AggroManager接口

```gdscript
# 信号
signal target_changed(enemy: Enemy, new_target: Unit)
signal taunt_started(unit: Unit, radius: float)
signal taunt_ended(unit: Unit)

# 公共方法
func register_enemy(enemy: Enemy) -> void
func unregister_enemy(enemy: Enemy) -> void
func apply_taunt(unit: Unit, radius: float, duration: float) -> void
func remove_taunt(unit: Unit) -> void
func get_target_for_enemy(enemy: Enemy) -> Unit
```

### 6.3 SummonManager接口

```gdscript
# 信号
signal summon_created(summon: SummonedUnit, source: Unit)
signal summon_destroyed(summon: SummonedUnit)

# 公共方法
func create_summon(data: Dictionary) -> SummonedUnit
func get_summons_by_source(source: Unit) -> Array[SummonedUnit]
func clear_all_summons() -> void
```

### 6.4 LifestealManager接口

```gdscript
# 公共方法
func register_bleed_source(unit: Unit) -> void
func unregister_bleed_source(unit: Unit) -> void
func calculate_lifesteal(bleed_stacks: int) -> float
```

---

## 七、审核结论

### 7.1 总体评估

**技术可行性**: 可行
**架构合理性**: 合理，建议按依赖顺序执行
**风险评估**: 中等，主要风险在配置冲突和信号循环
**推荐执行**: 分阶段执行，P0系统串行，P1单位按图腾并行

### 7.2 关键建议

1. **优先完成P0系统**: 4个基础系统是后续所有单位的前置条件
2. **严格分离配置**: 每个图腾使用独立的JSON配置段
3. **统一信号命名**: 建立信号命名规范，避免冲突
4. **充分测试P0**: 基础系统的稳定性直接影响所有依赖单位
5. **预留扩展点**: 在Enemy.gd和Unit.gd中预留机制扩展点

### 7.3 下一步行动

1. 创建feature/P0-01-soul-system分支，开始实现魂魄系统
2. 制定JSON配置合并规范
3. 创建EventBus或完善现有信号系统
4. 准备测试场景验证P0系统

---

**审核完成**
陈睿 (System Architect)
2026-02-19
