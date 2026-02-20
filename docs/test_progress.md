# 游戏测试进度文档

本文档详细描述每个单位机制的测试场景、验证方法和当前测试进度。测试工程师需根据此文档设计自动化测试用例，并在测试完成后更新进度。

---

## 测试进度概览

| 图腾流派 | 单位数量 | 已测试 | 测试覆盖率 |
|----------|----------|--------|------------|
| 牛图腾 (cow_totem) | 9 | 0 | 0% |
| 蝙蝠图腾 (bat_totem) | 5 | 0 | 0% |
| 蝴蝶图腾 (butterfly_totem) | 6 | 0 | 0% |
| 狼图腾 (wolf_totem) | 7 | 0 | 0% |
| 眼镜蛇图腾 (viper_totem) | 8 | 1 | 12.5% |
| 鹰图腾 (eagle_totem) | 12 | 0 | 0% |
| **总计** | **47** | **0** | **0%** |

---

## 文档说明

- **坐标规则**: (0,0) 为核心区，禁止放置单位。测试单位应放置在 (±1,0) 或 (0,±1) 等位置
- **测试原则**: 每个单位的每个机制都需要构造专门的测试场景验证
- **验证方式**: 通过日志事件、属性变化、行为表现等方式验证机制是否生效
- **进度更新**: 完成测试后，测试工程师需更新本文档中的测试进度

### 测试状态标记

- `[ ]` - 未测试
- `[~]` - 测试中
- `[x]` - 已测试通过
- `[!]` - 测试发现问题

---

## 如何更新测试进度

测试完成后，在对应单位的验证指标处将 `[ ]` 标记为 `[x]`，并更新上方的**测试进度概览**表格。

同时记录测试信息：
```markdown
**测试记录**:
- 测试日期: YYYY-MM-DD
- 测试人员: [姓名]
- 测试结果: 通过/失败
- 备注: [如有问题记录详情]
```

---

## 一、牛图腾流派单位测试

### 1.1 牦牛守护 (yak_guardian)

**核心机制**: 嘲讽/守护领域，周期性吸引敌人攻击自己，并为周围友方提供减伤Buff

#### 测试场景 1: Lv1 嘲讽机制验证
```gdscript
{
    "id": "test_yak_guardian_lv1_taunt",
    "core_type": "cow_totem",
    "initial_gold": 1000,
    "start_wave_index": 1,
    "duration": 15.0,
    "units": [
        {"id": "squirrel", "x": 0, "y": -1},  # 诱饵单位
        {"id": "yak_guardian", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "spawn_delay": 1.0}
    ],
    "expected_behavior": {
        "description": "敌人初始攻击松鼠，5秒后转为攻击牦牛守护",
        "verification": "检查日志中敌人target切换记录",
        "taunt_interval": 5.0
    }
}
```
**验证指标**:
- [ ] 敌人生成后首先锁定松鼠
- [ ] 5秒后敌人目标切换为牦牛守护
- [ ] 牦牛守护周围的友方单位获得guardian_shield buff
- [ ] Buff提供的减伤为5%

#### 测试场景 2: Lv2 嘲讽频率提升验证
```gdscript
{
    "id": "test_yak_guardian_lv2_taunt",
    "core_type": "cow_totem",
    "duration": 12.0,
    "units": [
        {"id": "squirrel", "x": 0, "y": -1},
        {"id": "yak_guardian", "x": 0, "y": 1, "level": 2}
    ],
    "expected_behavior": {
        "taunt_interval": 4.0,
        "damage_reduction": 0.10
    }
}
```
**验证指标**:
- [ ] 嘲讽间隔为4秒
- [ ] Buff提供的减伤为10%

#### 测试场景 3: Lv3 图腾反击联动验证
```gdscript
{
    "id": "test_yak_guardian_lv3_totem_counter",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "yak_guardian", "x": 0, "y": 1, "level": 3}
    ],
    "scheduled_actions": [
        {
            "time": 5.0,
            "type": "damage_core",
            "amount": 50  # 触发牛图腾反击
        }
    ],
    "expected_behavior": {
        "description": "牛图腾反击时，牦牛攻击范围内敌人受到牦牛血量15%的额外伤害",
        "verification": "检查反击时敌人受到的伤害数值"
    }
}
```
**验证指标**:
- [ ] 核心受到伤害后，牛图腾触发全屏反击
- [ ] 牦牛守护攻击范围内的敌人受到额外伤害
- [ ] 额外伤害 = 牦牛当前血量 × 15%

---

### 1.2 铁甲龟 (iron_turtle)

**核心机制**: 硬化皮肤，受到伤害时减去固定数值

#### 测试场景 1: Lv1 固定减伤验证
```gdscript
{
    "id": "test_iron_turtle_lv1_reduction",
    "core_type": "cow_totem",
    "duration": 15.0,
    "units": [
        {"id": "iron_turtle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "attack_damage": 30, "count": 3}
    ],
    "expected_behavior": {
        "description": "敌人攻击铁甲龟时，伤害减少20点",
        "verification": "核心血量减少量 = 原伤害 - 20"
    }
}
```
**验证指标**:
- [ ] 敌人攻击伤害30点，核心实际损失10点
- [ ] 减伤数值为固定20点

#### 测试场景 2: Lv2 减伤提升验证
**验证指标**:
- [ ] 减伤数值提升至35点

#### 测试场景 3: Lv3 绝对防御与回血验证
```gdscript
{
    "id": "test_iron_turtle_lv3_absolute_defense",
    "core_type": "cow_totem",
    "duration": 15.0,
    "core_health": 500,
    "units": [
        {"id": "iron_turtle", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "weak_enemy", "attack_damage": 10, "count": 5}  # 伤害被减至0或miss
    ],
    "expected_behavior": {
        "description": "当伤害被减为0或miss时，回复1%核心HP",
        "verification": "观察核心血量是否增加"
    }
}
```
**验证指标**:
- [ ] 减伤数值提升至50点
- [ ] 当敌人伤害≤50时，核心不扣血反而回血
- [ ] 回血量为最大核心血量的1%

---

### 1.3 刺猬 (hedgehog)

**核心机制**: 尖刺反弹，受到伤害时概率反弹伤害

#### 测试场景 1: Lv1 反弹概率验证
```gdscript
{
    "id": "test_hedgehog_lv1_reflect",
    "core_type": "cow_totem",
    "duration": 30.0,
    "units": [
        {"id": "hedgehog", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10, "hp": 100}
    ],
    "expected_behavior": {
        "description": "30%概率反弹敌人伤害",
        "verification": "统计多次攻击中反弹发生的次数，概率应在30%左右"
    }
}
```
**验证指标**:
- [ ] 反弹概率为30%
- [ ] 反弹伤害等于敌人造成的伤害

#### 测试场景 2: Lv2 反弹概率提升验证
**验证指标**:
- [ ] 反弹概率提升至50%

#### 测试场景 3: Lv3 刚毛散射验证
```gdscript
{
    "id": "test_hedgehog_lv3_spikes",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "hedgehog", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": -2, "y": 0}, {"x": 0, "y": 2}]},
        {"type": "attacker_enemy", "count": 1}  # 会攻击刺猬的敌人
    ],
    "expected_behavior": {
        "description": "反伤时向周围发射3枚尖刺",
        "verification": "检查周围敌人是否受到尖刺伤害"
    }
}
```
**验证指标**:
- [ ] 反弹时触发尖刺散射
- [ ] 散射尖刺数量为3枚
- [ ] 尖刺对范围内敌人造成伤害

---

### 1.4 牛魔像 (cow_golem)

**核心机制**: 怒火中烧，受击叠加攻击力；Lv3触发晕眩

#### 测试场景 1: Lv1 受击叠加攻击力验证
```gdscript
{
    "id": "test_cow_golem_lv1_rage",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "cow_golem", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "fast_attacker", "attack_speed": 2.0, "count": 1}  # 快速攻击触发多次受击
    ],
    "scheduled_actions": [
        {"time": 2.0, "type": "record_damage"},
        {"time": 10.0, "type": "record_damage"}
    ],
    "expected_behavior": {
        "description": "每次受击攻击力+3%，上限30%(10层)",
        "verification": "对比不同时间点的攻击伤害"
    }
}
```
**验证指标**:
- [ ] 每次受击攻击力增加3%
- [ ] 攻击力上限为30%(10层)
- [ ] 伤害输出随受击次数增加

#### 测试场景 2: Lv2 叠加上限提升验证
**验证指标**:
- [ ] 攻击力上限提升至50%(约17层)

#### 测试场景 3: Lv3 充能震荡验证
```gdscript
{
    "id": "test_cow_golem_lv3_shockwave",
    "core_type": "cow_totem",
    "duration": 30.0,
    "units": [
        {"id": "cow_golem", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 1, "y": 1}, {"x": -1, "y": 1}]}
    ],
    "expected_behavior": {
        "description": "受击时20%概率给敌人叠加瘟疫易伤Debuff",
        "verification": "检查敌人是否获得plague_debuff"
    }
}
```
**验证指标**:
- [ ] 受击时有20%概率触发
- [ ] 敌人获得瘟疫易伤Debuff
- [ ] Debuff可叠加

---

### 1.5 岩甲牛 (rock_armor_cow)

**核心机制**: 脱战生成护盾，攻击附加护盾伤害

#### 测试场景 1: Lv1 脱战护盾生成验证
```gdscript
{
    "id": "test_rock_armor_cow_lv1_shield",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "rock_armor_cow", "x": 0, "y": 1, "level": 1}
    ],
    "scheduled_actions": [
        {"time": 3.0, "type": "spawn_enemy", "enemy_type": "basic", "count": 2},
        {"time": 10.0, "type": "verify_shield", "expected_shield_percent": 0.1}
    ],
    "expected_behavior": {
        "description": "脱战5秒后生成10%最大HP的护盾",
        "verification": "检查护盾值是否为最大血量的10%"
    }
}
```
**验证指标**:
- [ ] 脱战5秒后生成护盾
- [ ] 护盾值为最大血量的10%
- [ ] 攻击附加护盾值50%的伤害

#### 测试场景 2: Lv2 护盾值提升验证
**验证指标**:
- [ ] 护盾值为最大血量的15%
- [ ] 脱战时间缩短至4秒

#### 测试场景 3: Lv3 溢出回血转护盾验证
```gdscript
{
    "id": "test_rock_armor_cow_lv3_overflow",
    "core_type": "cow_totem",
    "duration": 25.0,
    "core_health": 500,
    "max_core_health": 500,
    "units": [
        {"id": "rock_armor_cow", "x": 0, "y": 1, "level": 3},
        {"id": "mushroom_healer", "x": 1, "y": 0, "level": 3}  # 提供治疗
    ],
    "expected_behavior": {
        "description": "核心满血时，溢出回血的10%转为护盾",
        "verification": "核心满血后，观察护盾是否继续增加"
    }
}
```
**验证指标**:
- [ ] 核心满血时，治疗溢出部分转化为护盾
- [ ] 转化比例为10%

---

### 1.6 菌菇治愈者 (mushroom_healer)

**核心机制**: 孢子护盾，为友方提供可抵消伤害的Buff

#### 测试场景 1: Lv1 孢子Buff验证
```gdscript
{
    "id": "test_mushroom_healer_lv1_spores",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "mushroom_healer", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 受Buff保护的单位
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "为周围友方添加1层孢子Buff，抵消1次伤害并使敌人叠加3层中毒",
        "verification": "松鼠第一次受击时不掉血，敌人获得中毒Debuff"
    }
}
```
**验证指标**:
- [ ] 周围友方获得孢子Buff
- [ ] Buff抵消1次伤害
- [ ] 抵消时敌人叠加3层中毒

#### 测试场景 2: Lv2 孢子层数提升验证
**验证指标**:
- [ ] 孢子层数为3层

#### 测试场景 3: Lv3 孢子耗尽伤害验证
```gdscript
{
    "id": "test_mushroom_healer_lv3_spore_damage",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "mushroom_healer", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}  # 多次攻击耗尽孢子
    ],
    "expected_behavior": {
        "description": "孢子耗尽时额外造成一次中毒伤害",
        "verification": "孢子层数归零时，敌人受到额外中毒伤害"
    }
}
```
**验证指标**:
- [ ] 孢子层数耗尽时触发额外伤害
- [ ] 伤害类型为中毒伤害

---

### 1.7 奶牛 (cow)

**核心机制**: 周期性治疗核心

#### 测试场景 1: Lv1 产奶治疗验证
```gdscript
{
    "id": "test_cow_lv1_heal",
    "core_type": "cow_totem",
    "duration": 20.0,
    "core_health": 400,
    "max_core_health": 500,
    "units": [
        {"id": "cow", "x": 0, "y": 1, "level": 1}
    ],
    "expected_behavior": {
        "description": "每5秒回复1%核心HP",
        "verification": "观察核心血量每5秒增加5点(500×1%)"
    }
}
```
**验证指标**:
- [ ] 治疗间隔为5秒
- [ ] 治疗量为最大核心血量的1%

#### 测试场景 2: Lv2 治疗频率提升验证
**验证指标**:
- [ ] 治疗间隔缩短至4秒

#### 测试场景 3: Lv3 损失血量额外治疗验证
```gdscript
{
    "id": "test_cow_lv3_heal_boost",
    "core_type": "cow_totem",
    "duration": 25.0,
    "core_health": 250,  # 50%血量
    "max_core_health": 500,
    "units": [
        {"id": "cow", "x": 0, "y": 1, "level": 3}
    ],
    "expected_behavior": {
        "description": "根据核心已损失血量额外回复",
        "verification": "血量越低，每次治疗量越高"
    }
}
```
**验证指标**:
- [ ] 核心损失50%血量时，治疗量增加
- [ ] 治疗量与损失血量百分比相关

---

### 1.8 苦修者 (ascetic)

**核心机制**: 将受到伤害转为MP

#### 测试场景 1: Lv1 伤害转MP验证
```gdscript
{
    "id": "test_ascetic_lv1_convert",
    "core_type": "cow_totem",
    "duration": 20.0,
    "initial_mp": 500,
    "units": [
        {"id": "ascetic", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 被施加Buff的单位
    ],
    "enemies": [
        {"type": "basic_enemy", "attack_damage": 50, "count": 3}
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "ascetic", "target_unit_id": "squirrel"}
    ],
    "expected_behavior": {
        "description": "被Buff单位受到伤害的12%转为MP",
        "verification": "松鼠受击50点伤害，MP增加6点"
    }
}
```
**验证指标**:
- [ ] 只能选择一个单位施加Buff
- [ ] 受到伤害的12%转化为MP
- [ ] MP增加量正确计算

#### 测试场景 2: Lv2 转化比例提升验证
**验证指标**:
- [ ] 转化比例提升至18%

#### 测试场景 3: Lv3 双目标验证
```gdscript
{
    "id": "test_ascetic_lv3_dual",
    "core_type": "cow_totem",
    "duration": 20.0,
    "units": [
        {"id": "ascetic", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0},
        {"id": "bee", "x": -1, "y": 0}
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "ascetic", "target_unit_id": "squirrel"},
        {"type": "apply_buff", "buff_id": "ascetic", "target_unit_id": "bee"}
    ],
    "expected_behavior": {
        "description": "可以选择两个单位施加Buff",
        "verification": "两个被Buff单位受到伤害都转化为MP"
    }
}
```
**验证指标**:
- [ ] 可以选择两个单位
- [ ] 两个单位的伤害都转化为MP

---

### 1.9 树苗 (plant)

**核心机制**: 每波增加自身Max HP，Lv3提供范围加成

#### 测试场景 1: Lv1 扎根成长验证
```gdscript
{
    "id": "test_plant_lv1_growth",
    "core_type": "cow_totem",
    "duration": 60.0,  # 跨越多个波次
    "start_wave_index": 1,
    "units": [
        {"id": "plant", "x": 0, "y": 1, "level": 1, "initial_hp": 100}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "end_wave"},
        {"time": 10.0, "type": "verify_hp", "expected_hp_percent": 1.05}
    ],
    "expected_behavior": {
        "description": "每波结束后自身Max HP+5%",
        "verification": "波次结束后检查血量是否增加"
    }
}
```
**验证指标**:
- [ ] 每波结束后最大血量增加5%
- [ ] 当前血量同步增加

#### 测试场景 2: Lv2 成长速度提升验证
**验证指标**:
- [ ] 每波最大血量增加8%

#### 测试场景 3: Lv3 世界树范围加成验证
```gdscript
{
    "id": "test_plant_lv3_world_tree",
    "core_type": "cow_totem",
    "duration": 30.0,
    "units": [
        {"id": "plant", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0, "initial_hp": 100},
        {"id": "bee", "x": 0, "y": 2, "initial_hp": 80}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "end_wave"},
        {"time": 10.0, "type": "verify_hp", "target": "squirrel", "expected_hp_percent": 1.05}
    ],
    "expected_behavior": {
        "description": "周围一圈单位Max HP加成5%",
        "verification": "周围友方单位血量增加5%"
    }
}
```
**验证指标**:
- [ ] 周围一圈友方单位最大血量增加5%
- [ ] 效果每波触发

---

### 1.10 牛椋鸟 (oxpecker)

**核心机制**: 附身单位，攻击时额外攻击

#### 测试场景 1: Lv1 额外攻击验证
```gdscript
{
    "id": "test_oxpecker_lv1_extra_attack",
    "core_type": "cow_totem",
    "duration": 15.0,
    "units": [
        {"id": "oxpecker", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 被附身单位
    ],
    "setup_actions": [
        {"type": "attach", "source": "oxpecker", "target": "squirrel"}
    ],
    "expected_behavior": {
        "description": "被附身单位攻击时额外攻击1次",
        "verification": "松鼠每次攻击触发两次伤害事件"
    }
}
```
**验证指标**:
- [ ] 被附身单位攻击时触发额外攻击
- [ ] 额外攻击1次

#### 测试场景 2: Lv2 额外攻击伤害提升验证
**验证指标**:
- [ ] 额外攻击伤害+50%

#### 测试场景 3: Lv3 易伤Debuff验证
```gdscript
{
    "id": "test_oxpecker_lv3_vulnerability",
    "core_type": "cow_totem",
    "duration": 15.0,
    "units": [
        {"id": "oxpecker", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "setup_actions": [
        {"type": "attach", "source": "oxpecker", "target": "squirrel"}
    ],
    "expected_behavior": {
        "description": "额外攻击给敌人叠加一层易伤Debuff",
        "verification": "敌人受到额外攻击后获得vulnerability_debuff"
    }
}
```
**验证指标**:
- [ ] 额外攻击给敌人叠加易伤Debuff
- [ ] Debuff使敌人受到更多伤害

---

## 二、蝙蝠图腾流派单位测试

### 2.1 蚊子 (mosquito)

**核心机制**: 攻击回血，对流血敌人增伤

#### 测试场景 1: Lv1 攻击回血验证
```gdscript
{
    "id": "test_mosquito_lv1_lifesteal",
    "core_type": "bat_totem",
    "duration": 15.0,
    "units": [
        {"id": "mosquito", "x": 0, "y": 1, "level": 1, "hp": 100}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "造成30%攻击力伤害，回复该单位HP的10%",
        "verification": "攻击后蚊子血量增加"
    }
}
```
**验证指标**:
- [ ] 攻击伤害为攻击力的30%
- [ ] 回血量为蚊子当前HP的10%

#### 测试场景 2: Lv2 伤害和回血提升验证
**验证指标**:
- [ ] 伤害提升至50%攻击力
- [ ] 回血比例提升至30%

#### 测试场景 3: Lv3 登革热验证
```gdscript
{
    "id": "test_mosquito_lv3_dengue",
    "core_type": "bat_totem",
    "duration": 20.0,
    "units": [
        {"id": "mosquito", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "debuffs": [{"type": "bleed", "stacks": 3}], "count": 3, "hp": 50}
    ],
    "expected_behavior": {
        "description": "对流血敌人伤害+100%，击杀时爆炸造成范围伤害",
        "verification": "对流血敌人伤害翻倍，击杀时周围敌人受到伤害"
    }
}
```
**验证指标**:
- [ ] 对流血敌人伤害翻倍
- [ ] 击杀敌人时触发范围爆炸
- [ ] 爆炸对周围敌人造成伤害

---

### 2.2 石像鬼 (gargoyle)

**核心机制**: 根据核心血量切换形态

#### 测试场景 1: Lv1 形态切换验证
```gdscript
{
    "id": "test_gargoyle_lv1_form",
    "core_type": "bat_totem",
    "duration": 30.0,
    "core_health": 500,
    "max_core_health": 500,
    "units": [
        {"id": "gargoyle", "x": 0, "y": 1, "level": 1}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "damage_core", "amount": 350},  # 核心HP降至30%
        {"time": 10.0, "type": "verify_form", "expected_form": "stone"},
        {"time": 15.0, "type": "heal_core", "amount": 200},  # 核心HP升至70%
        {"time": 20.0, "type": "verify_form", "expected_form": "normal"}
    ],
    "expected_behavior": {
        "description": "核心HP<35%进入石像形态停止攻击反弹15%伤害；>65%变回正常",
        "verification": "形态随核心血量变化"
    }
}
```
**验证指标**:
- [ ] 核心HP<35%时进入石像形态
- [ ] 石像形态停止主动攻击
- [ ] 反弹15%伤害
- [ ] 核心HP>65%时恢复正常形态

#### 测试场景 2: Lv2 反弹次数验证
**验证指标**:
- [ ] 反弹次数为2次

#### 测试场景 3: Lv3 反弹次数提升验证
**验证指标**:
- [ ] 反弹次数为3次

---

### 2.3 血法师 (blood_mage)

**核心机制**: 召唤血池区域造成DOT伤害

#### 测试场景 1: Lv1 血池召唤验证
```gdscript
{
    "id": "test_blood_mage_lv1_pool",
    "core_type": "bat_totem",
    "duration": 20.0,
    "units": [
        {"id": "blood_mage", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 2}, {"x": 2, "y": 3}]}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "blood_mage", "target": {"x": 2, "y": 2}}
    ],
    "expected_behavior": {
        "description": "召唤血池区域，区域内敌人每秒受到dot伤害",
        "verification": "血池内的敌人持续受到伤害"
    }
}
```
**验证指标**:
- [ ] 技能召唤血池区域
- [ ] 区域内敌人每秒受到伤害
- [ ] 血池持续一定时间

#### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 血池伤害提升

#### 测试场景 3: Lv3 流血叠加验证
```gdscript
{
    "id": "test_blood_mage_lv3_bleed",
    "core_type": "bat_totem",
    "duration": 25.0,
    "units": [
        {"id": "blood_mage", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 2}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "blood_mage", "target": {"x": 2, "y": 2}}
    ],
    "expected_behavior": {
        "description": "血池内敌人流血层数+1/秒",
        "verification": "敌人在血池内每秒叠加1层流血"
    }
}
```
**验证指标**:
- [ ] 血池内敌人每秒叠加1层流血
- [ ] 流血层数可叠加

---

### 2.4 生命链条 (life_chain)

**核心机制**: 连接敌人偷取生命

#### 测试场景 1: Lv1 单目标连接验证
```gdscript
{
    "id": "test_life_chain_lv1_single",
    "core_type": "bat_totem",
    "duration": 20.0,
    "units": [
        {"id": "life_chain", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "hp": 100, "positions": [{"x": 3, "y": 3}, {"x": 2, "y": 2}, {"x": 1, "y": 1}]}
    ],
    "expected_behavior": {
        "description": "连接1个最远敌人，每秒偷取生命值",
        "verification": "最远敌人持续掉血，核心或单位回血"
    }
}
```
**验证指标**:
- [ ] 自动连接最远的1个敌人
- [ ] 每秒偷取生命值
- [ ] 被连接敌人持续受到伤害

#### 测试场景 2: Lv2 双目标连接验证
**验证指标**:
- [ ] 同时连接2个敌人

#### 测试场景 3: Lv3 伤害分摊验证
```gdscript
{
    "id": "test_life_chain_lv3_share",
    "core_type": "bat_totem",
    "duration": 20.0,
    "units": [
        {"id": "life_chain", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "hp": 100}
    ],
    "expected_behavior": {
        "description": "被连接敌人分摊受到伤害",
        "verification": "攻击其中一个被连接敌人时，其他被连接敌人也受到部分伤害"
    }
}
```
**验证指标**:
- [ ] 被连接敌人之间分摊伤害
- [ ] 伤害分摊比例正确

---

### 2.5 瘟疫使者 (plague_spreader)

**核心机制**: 给敌人叠加易伤Debuff

#### 测试场景 1: Lv1 易伤叠加验证
```gdscript
{
    "id": "test_plague_spreader_lv1_vulnerability",
    "core_type": "bat_totem",
    "duration": 20.0,
    "units": [
        {"id": "plague_spreader", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "敌人每次进入攻击范围获得易伤debuff",
        "verification": "敌人获得plague_debuff，受到的伤害增加"
    }
}
```
**验证指标**:
- [ ] 敌人进入范围获得易伤Debuff
- [ ] 易伤效果使敌人受到更多伤害

#### 测试场景 2: Lv2 效果提升验证
**验证指标**:
- [ ] 易伤效果提升

#### 测试场景 3: Lv3 传染验证
```gdscript
{
    "id": "test_plague_spreader_lv3_spread",
    "core_type": "bat_totem",
    "duration": 25.0,
    "units": [
        {"id": "plague_spreader", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}, {"x": 3, "y": 0}]}
    ],
    "expected_behavior": {
        "description": "有瘟疫Buff的敌人每3秒传播给周围最近一个敌人",
        "verification": "未进入范围的敌人也获得Debuff"
    }
}
```
**验证指标**:
- [ ] 有Debuff的敌人每3秒传播
- [ ] 传播给最近的敌人
- [ ] 传播范围有限

---

### 2.6 鲜血圣杯 (blood_chalice)

**核心机制**: 吸血可超过HP上限但会流失

#### 测试场景 1: Lv1 溢出血量流失验证
```gdscript
{
    "id": "test_blood_chalice_lv1_overflow",
    "core_type": "bat_totem",
    "duration": 30.0,
    "units": [
        {"id": "blood_chalice", "x": 0, "y": 1, "level": 1},
        {"id": "mosquito", "x": 1, "y": 0}  # 吸血单位
    ],
    "enemies": [
        {"type": "basic_enemy", "debuffs": [{"type": "bleed", "stacks": 5}], "count": 5}
    ],
    "expected_behavior": {
        "description": "附近单位吸血可超过HP上限，但每0.5秒流失15%",
        "verification": "单位血量超过最大值后缓慢下降"
    }
}
```
**验证指标**:
- [ ] 吸血可使血量超过上限
- [ ] 溢出血量每0.5秒流失15%
- [ ] 流失直到回到上限

#### 测试场景 2: Lv2 流失速度降低验证
**验证指标**:
- [ ] 流失速度降至每0.5秒10%

#### 测试场景 3: Lv3 核心损失伤害验证
```gdscript
{
    "id": "test_blood_chalice_lv3_core_damage",
    "core_type": "bat_totem",
    "duration": 25.0,
    "core_health": 300,  # 损失200血量
    "max_core_health": 500,
    "units": [
        {"id": "blood_chalice", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "敌人每0.5秒受到核心损失HP的伤害",
        "verification": "敌人持续受到基于核心损失血量的伤害"
    }
}
```
**验证指标**:
- [ ] 敌人每0.5秒受到伤害
- [ ] 伤害值与核心损失血量相关

---

### 2.7 血祖 (blood_ancestor)

**核心机制**: 根据受伤敌人数量增加附身单位攻击力

#### 测试场景 1: Lv1 鲜血领域验证
```gdscript
{
    "id": "test_blood_ancestor_lv1_domain",
    "core_type": "bat_totem",
    "duration": 20.0,
    "units": [
        {"id": "blood_ancestor", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 被附身单位
    ],
    "enemies": [
        {"type": "basic_enemy", "hp": 50, "count": 3}  # 低血量确保受伤
    ],
    "setup_actions": [
        {"type": "attach", "source": "blood_ancestor", "target": "squirrel"}
    ],
    "expected_behavior": {
        "description": "每有受伤敌人，附身单位攻击+5%(上限30%)",
        "verification": "场上有受伤敌人时，松鼠攻击力增加"
    }
}
```
**验证指标**:
- [ ] 每有1个受伤敌人，攻击力+5%
- [ ] 攻击力上限+30%
- [ ] 加成实时更新

#### 测试场景 2: Lv2 加成上限提升验证
**验证指标**:
- [ ] 攻击力上限提升

#### 测试场景 3: Lv3 血怒验证
```gdscript
{
    "id": "test_blood_ancestor_lv3_blood_rage",
    "core_type": "bat_totem",
    "duration": 25.0,
    "core_health": 200,  # <50%
    "max_core_health": 500,
    "units": [
        {"id": "blood_ancestor", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "debuffs": [{"type": "bleed", "stacks": 3}], "count": 3}
    ],
    "expected_behavior": {
        "description": "核心HP<50%时流血敌人受到伤害+25%",
        "verification": "低血量时，流血敌人受到的伤害增加"
    }
}
```
**验证指标**:
- [ ] 核心HP<50%时触发
- [ ] 流血敌人受到伤害+25%

---

### 2.8 血祭术士 (blood_ritualist)

**核心机制**: 主动技能消耗核心HP施加流血

#### 测试场景 1: Lv1 鲜血仪式验证
```gdscript
{
    "id": "test_blood_ritualist_lv1_ritual",
    "core_type": "bat_totem",
    "duration": 20.0,
    "core_health": 500,
    "max_core_health": 500,
    "units": [
        {"id": "blood_ritualist", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "blood_ritualist"}
    ],
    "expected_behavior": {
        "description": "消耗20%核心HP，对攻击范围内敌人施加2层流血",
        "verification": "核心HP减少100点，敌人获得2层流血"
    }
}
```
**验证指标**:
- [ ] 技能消耗20%核心HP
- [ ] 范围内敌人获得2层流血
- [ ] 技能CD生效

#### 测试场景 2: Lv2 流血层数提升验证
**验证指标**:
- [ ] 敌人获得3层流血

#### 测试场景 3: Lv3 吸血翻倍验证
```gdscript
{
    "id": "test_blood_ritualist_lv3_lifesteal",
    "core_type": "bat_totem",
    "duration": 25.0,
    "units": [
        {"id": "blood_ritualist", "x": 0, "y": 1, "level": 3},
        {"id": "mosquito", "x": 1, "y": 0}  # 吸血单位
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "blood_ritualist"},
        {"time": 6.0, "type": "record_lifesteal"},
        {"time": 10.0, "type": "record_lifesteal"}
    ],
    "expected_behavior": {
        "description": "血祭后5秒内吸血效果翻倍",
        "verification": "技能释放后5秒内，蚊子吸血量翻倍"
    }
}
```
**验证指标**:
- [ ] 血祭后5秒内吸血翻倍
- [ ] 5秒后恢复正常

---

## 三、蝴蝶图腾流派单位测试

### 3.1 红莲火炬 (torch)

**核心机制**: 赋予燃烧Buff

#### 测试场景 1: Lv1 燃烧Buff验证
```gdscript
{
    "id": "test_torch_lv1_burn",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "torch", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 被Buff单位
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "fire", "target_unit_id": "squirrel"}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "赋予周围一个单位燃烧Buff，燃烧可叠加5层",
        "verification": "松鼠攻击使敌人叠加燃烧层数，最多5层"
    }
}
```
**验证指标**:
- [ ] 可赋予1个单位燃烧Buff
- [ ] 燃烧可叠加5层
- [ ] 每层燃烧造成持续伤害

#### 测试场景 2: Lv2 额外目标验证
**验证指标**:
- [ ] 可赋予2个单位燃烧Buff

#### 测试场景 3: Lv3 爆燃验证
```gdscript
{
    "id": "test_torch_lv3_explosion",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "units": [
        {"id": "torch", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "fire", "target_unit_id": "squirrel"}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 500}
    ],
    "expected_behavior": {
        "description": "燃烧叠加到5层时引爆，造成目标10%最大HP伤害",
        "verification": "5层燃烧时触发爆炸，造成目标50点伤害"
    }
}
```
**验证指标**:
- [ ] 5层燃烧时触发爆炸
- [ ] 爆炸伤害为敌人最大血量的10%

---

### 3.2 蝴蝶 (butterfly)

**核心机制**: 消耗法力增加伤害

#### 测试场景 1: Lv1 法力光辉验证
```gdscript
{
    "id": "test_butterfly_lv1_mana",
    "core_type": "butterfly_totem",
    "duration": 15.0,
    "initial_mp": 500,
    "units": [
        {"id": "butterfly", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "消耗5%最大法力，附加消耗法力100%的伤害",
        "verification": "攻击时MP减少25点，伤害增加25点"
    }
}
```
**验证指标**:
- [ ] 攻击消耗5%最大法力(25点)
- [ ] 附加伤害等于消耗的法力值
- [ ] MP不足时正常攻击

#### 测试场景 2: Lv2 伤害倍率提升验证
**验证指标**:
- [ ] 附加伤害为消耗法力的150%

#### 测试场景 3: Lv3 击杀回蓝验证
```gdscript
{
    "id": "test_butterfly_lv3_kill_restore",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "initial_mp": 400,
    "units": [
        {"id": "butterfly", "x": 0, "y": 1, "level": 3, "attack": 100}
    ],
    "enemies": [
        {"type": "weak_enemy", "count": 5, "hp": 50}  # 低血量确保击杀
    ],
    "expected_behavior": {
        "description": "每次击杀敌人恢复10%最大法力",
        "verification": "击杀敌人后MP增加50点"
    }
}
```
**验证指标**:
- [ ] 击杀敌人恢复10%最大法力
- [ ] 恢复量为50点(基于1000上限)

---

### 3.3 冰晶蝶 (ice_butterfly)

**核心机制**: 冰冻debuff叠加冻结

#### 测试场景 1: Lv1 极寒冻结验证
```gdscript
{
    "id": "test_ice_butterfly_lv1_freeze",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "ice_butterfly", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "攻击给敌人叠加冰冻debuff，叠满3层冻结1秒",
        "verification": "攻击3次后敌人冻结1秒"
    }
}
```
**验证指标**:
- [ ] 每次攻击叠加1层冰冻
- [ ] 3层时触发1秒冻结
- [ ] 冻结期间敌人无法移动

#### 测试场景 2: Lv2 冻结时间提升验证
**验证指标**:
- [ ] 冻结时间提升至2秒

#### 测试场景 3: Lv3 极寒增幅验证
```gdscript
{
    "id": "test_ice_butterfly_lv3_amplify",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "ice_butterfly", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "法球命中冻结敌人时伤害翻倍",
        "verification": "蝴蝶图腾法球命中冻结敌人时造成40伤害"
    }
}
```
**验证指标**:
- [ ] 图腾法球命中冻结敌人伤害翻倍
- [ ] 从20伤害变为40伤害

---

### 3.4 仙女龙 (fairy_dragon)

**核心机制**: 概率传送敌人

#### 测试场景 1: Lv1 传送验证
```gdscript
{
    "id": "test_fairy_dragon_lv1_teleport",
    "core_type": "butterfly_totem",
    "duration": 30.0,
    "units": [
        {"id": "fairy_dragon", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "25%概率将敌人传送至3格外",
        "verification": "约25%的攻击触发传送，敌人位置突变"
    }
}
```
**验证指标**:
- [ ] 传送概率为25%
- [ ] 敌人被传送至3格外
- [ ] 传送不造成伤害

#### 测试场景 2: Lv2 传送概率提升验证
**验证指标**:
- [ ] 传送概率提升至40%

#### 测试场景 3: Lv3 相位崩塌验证
```gdscript
{
    "id": "test_fairy_dragon_lv3_collapse",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "units": [
        {"id": "fairy_dragon", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "被传送敌人叠加两层瘟疫debuff",
        "verification": "传送触发后敌人获得2层plague_debuff"
    }
}
```
**验证指标**:
- [ ] 传送触发时叠加2层瘟疫Debuff
- [ ] Debuff使敌人受到更多伤害

---

### 3.5 萤火虫 (firefly)

**核心机制**: 致盲Debuff

#### 测试场景 1: Lv1 闪光致盲验证
```gdscript
{
    "id": "test_firefly_lv1_blind",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "firefly", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "attacker_enemy", "count": 3}  # 会攻击的敌人
    ],
    "expected_behavior": {
        "description": "攻击不造成伤害，给敌人一层致盲debuff",
        "verification": "敌人攻击有概率Miss"
    }
}
```
**验证指标**:
- [ ] 攻击不造成伤害
- [ ] 敌人获得致盲Debuff
- [ ] 致盲使敌人攻击Miss

#### 测试场景 2: Lv2 持续时间提升验证
**验证指标**:
- [ ] 致盲持续时间+2秒

#### 测试场景 3: Lv3 闪光回蓝验证
```gdscript
{
    "id": "test_firefly_lv3_restore",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "initial_mp": 500,
    "units": [
        {"id": "firefly", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "attacker_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "致盲敌人每次Miss回复8法力",
        "verification": "敌人攻击Miss时，MP增加8点"
    }
}
```
**验证指标**:
- [ ] 致盲敌人攻击Miss时回复8MP
- [ ] 回复量正确

---

### 3.6 凤凰 (phoenix)

**核心机制**: 火雨AOE技能

#### 测试场景 1: Lv1 火雨验证
```gdscript
{
    "id": "test_phoenix_lv1_rain",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "phoenix", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 2, "y": 3}, {"x": 3, "y": 2}]}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "phoenix", "target": {"x": 2, "y": 2}}
    ],
    "expected_behavior": {
        "description": "火雨AOE持续3秒",
        "verification": "目标区域内敌人持续受到伤害"
    }
}
```
**验证指标**:
- [ ] 技能召唤火雨区域
- [ ] 火雨持续3秒
- [ ] 区域内敌人受到伤害

#### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 火雨伤害+50%

#### 测试场景 3: Lv3 燃烧回蓝与临时法球验证
```gdscript
{
    "id": "test_phoenix_lv3_orb",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "initial_mp": 500,
    "units": [
        {"id": "phoenix", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "燃烧敌人时回复法力，获得临时法球",
        "verification": "燃烧敌人时MP增加，图腾法球数量增加"
    }
}
```
**验证指标**:
- [ ] 燃烧敌人时回复法力
- [ ] 获得临时法球
- [ ] 临时法球持续一定时间

---

### 3.7 电鳗 (eel)

**核心机制**: 闪电链弹射

#### 测试场景 1: Lv1 闪电链验证
```gdscript
{
    "id": "test_eel_lv1_chain",
    "core_type": "butterfly_totem",
    "duration": 15.0,
    "units": [
        {"id": "eel", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 3, "y": 0}, {"x": 4, "y": 0}]}
    ],
    "expected_behavior": {
        "description": "闪电链最多弹射4次",
        "verification": "一次攻击命中5个敌人"
    }
}
```
**验证指标**:
- [ ] 闪电链最多弹射4次
- [ ] 最多命中5个敌人
- [ ] 每次弹射伤害递减

#### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 闪电伤害+50%

#### 测试场景 3: Lv3 法力震荡验证
```gdscript
{
    "id": "test_eel_lv3_mana",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "initial_mp": 500,
    "units": [
        {"id": "eel", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "每次弹射回复3法力",
        "verification": "攻击命中5个敌人时MP增加12点"
    }
}
```
**验证指标**:
- [ ] 每次弹射回复3MP
- [ ] 回复量正确计算

---

### 3.8 龙 (dragon)

**核心机制**: 黑洞控制

#### 测试场景 1: Lv1 黑洞验证
```gdscript
{
    "id": "test_dragon_lv1_blackhole",
    "core_type": "butterfly_totem",
    "duration": 20.0,
    "units": [
        {"id": "dragon", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 2}, {"x": 3, "y": 2}, {"x": 2, "y": 3}]}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "dragon", "target": {"x": 2, "y": 2}}
    ],
    "expected_behavior": {
        "description": "黑洞控制持续4秒，吸入敌人",
        "verification": "敌人被吸入黑洞中心，持续4秒"
    }
}
```
**验证指标**:
- [ ] 技能召唤黑洞
- [ ] 黑洞持续4秒
- [ ] 范围内敌人被吸入中心

#### 测试场景 2: Lv2 范围和持续时间提升验证
**验证指标**:
- [ ] 黑洞范围+20%
- [ ] 持续时间提升至6秒

#### 测试场景 3: Lv3 星辰坠落验证
```gdscript
{
    "id": "test_dragon_lv3_meteor",
    "core_type": "butterfly_totem",
    "duration": 25.0,
    "units": [
        {"id": "dragon", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "hp": 100}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "dragon", "target": {"x": 2, "y": 2}},
        {"time": 11.0, "type": "verify_damage"}  # 黑洞结束时
    ],
    "expected_behavior": {
        "description": "黑洞结束时根据吸入敌人数量造成伤害",
        "verification": "黑洞结束时所有被吸入敌人受到伤害"
    }
}
```
**验证指标**:
- [ ] 黑洞结束时造成伤害
- [ ] 伤害与吸入敌人数量相关

---

## 四、狼图腾流派单位测试

### 4.1 狼 (wolf)

**核心机制**: 吞噬继承

#### 测试场景 1: Lv1 吞噬继承验证
```gdscript
{
    "id": "test_wolf_lv1_devour",
    "core_type": "wolf_totem",
    "duration": 20.0,
    "units": [
        {"id": "wolf", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 被吞噬单位
    ],
    "setup_actions": [
        {"type": "devour", "source": "wolf", "target": "squirrel"}
    ],
    "expected_behavior": {
        "description": "登场时吞噬一个单位，继承50%攻击力和血量及攻击机制",
        "verification": "狼的属性增加，获得松鼠的攻击方式"
    }
}
```
**验证指标**:
- [ ] 必须选择一个单位吞噬
- [ ] 继承被吞噬单位50%攻击力
- [ ] 继承被吞噬单位50%血量
- [ ] 继承被吞噬单位的攻击机制

#### 测试场景 2: Lv2 双重继承验证
```gdscript
{
    "id": "test_wolf_lv2_dual_inherit",
    "core_type": "wolf_totem",
    "duration": 25.0,
    "units": [
        {"id": "wolf", "x": 0, "y": 1, "level": 1},
        {"id": "wolf2", "x": 1, "y": 0, "level": 1, "devoured": "bee"},
        {"id": "squirrel", "x": -1, "y": 0}
    ],
    "setup_actions": [
        {"type": "devour", "source": "wolf", "target": "squirrel"},
        {"type": "merge", "source": "wolf", "target": "wolf2"}  # 合并两只狼
    ],
    "expected_behavior": {
        "description": "合并升级时保留两只狼各自的攻击机制",
        "verification": "升级后的狼同时拥有两种攻击方式"
    }
}
```
**验证指标**:
- [ ] 合并后保留两只狼的继承机制
- [ ] 可以同时使用两种攻击方式

#### 测试场景 3: Lv3 不可升级验证
**验证指标**:
- [ ] 狼无法升到Lv.3
- [ ] 合并时最多到Lv.2

---

### 4.2 猛虎 (tiger)

**核心机制**: 主动技能吞噬释放流星雨

#### 测试场景 1: Lv1 猛虎吞噬验证
```gdscript
{
    "id": "test_tiger_lv1_devour",
    "core_type": "wolf_totem",
    "duration": 25.0,
    "units": [
        {"id": "tiger", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 2}]}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "tiger", "target": "squirrel"}  # 吞噬松鼠
    ],
    "expected_behavior": {
        "description": "吞噬相邻友方单位，立即释放流星雨，伤害+被吞噬单位攻击力25%",
        "verification": "流星雨造成伤害，伤害值包含松鼠攻击力的25%"
    }
}
```
**验证指标**:
- [ ] 技能释放后吞噬相邻单位
- [ ] 立即释放流星雨
- [ ] 流星雨伤害增加被吞噬单位攻击力的25%

#### 测试场景 2: Lv2 血怒暴击验证
```gdscript
{
    "id": "test_tiger_lv2_blood_rage",
    "core_type": "wolf_totem",
    "duration": 30.0,
    "units": [
        {"id": "tiger", "x": 0, "y": 1, "level": 2}
    ],
    "setup_actions": [
        {"type": "add_soul", "count": 8}  # 添加8层血魂
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "每层血魂使暴击率+3%，最多8层",
        "verification": "8层血魂时暴击率+24%"
    }
}
```
**验证指标**:
- [ ] 每层血魂暴击率+3%
- [ ] 最多8层(+24%暴击率)
- [ ] 暴击率正确计算

#### 测试场景 3: Lv3 流星雨增强验证
```gdscript
{
    "id": "test_tiger_lv3_meteor",
    "core_type": "wolf_totem",
    "duration": 25.0,
    "units": [
        {"id": "tiger", "x": 0, "y": 1, "level": 3},
        {"id": "wolf", "x": 1, "y": 0}  # 狼图腾单位
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "tiger", "target": "wolf"}
    ],
    "expected_behavior": {
        "description": "流星雨流星数+2颗，吞噬狼图腾单位时额外+2颗",
        "verification": "吞噬狼时流星雨流星数增加4颗"
    }
}
```
**验证指标**:
- [ ] 流星雨流星数+2颗
- [ ] 吞噬狼图腾单位额外+2颗
- [ ] 吞噬非狼单位只+2颗

---

### 4.3 恶霸犬 (dog)

**核心机制**: 核心血量越低攻速越快

#### 测试场景 1: Lv1 狂暴验证
```gdscript
{
    "id": "test_dog_lv1_rampage",
    "core_type": "wolf_totem",
    "duration": 30.0,
    "core_health": 500,
    "max_core_health": 500,
    "units": [
        {"id": "dog", "x": 0, "y": 1, "level": 1}
    ],
    "scheduled_actions": [
        {"time": 2.0, "type": "record_attack_speed"},
        {"time": 5.0, "type": "damage_core", "amount": 250},  # 核心降至50%
        {"time": 8.0, "type": "record_attack_speed"},
        {"time": 10.0, "type": "damage_core", "amount": 200},  # 核心降至10%
        {"time": 13.0, "type": "record_attack_speed"}
    ],
    "expected_behavior": {
        "description": "核心HP每降低10%，攻速+5%",
        "verification": "核心50%时攻速+25%，10%时攻速+45%"
    }
}
```
**验证指标**:
- [ ] 核心HP每降低10%，攻速+5%
- [ ] 攻速随血量动态变化

#### 测试场景 2: Lv2 攻速提升验证
**验证指标**:
- [ ] 核心HP每降低10%，攻速+10%

#### 测试场景 3: Lv3 溅射验证
```gdscript
{
    "id": "test_dog_lv3_splash",
    "core_type": "wolf_totem",
    "duration": 25.0,
    "core_health": 50,  # 极低血量触发高攻速
    "max_core_health": 500,
    "units": [
        {"id": "dog", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}]}
    ],
    "expected_behavior": {
        "description": "攻速+80%以上时，可以造成溅射",
        "verification": "高攻速时，攻击一个敌人周围敌人也受到伤害"
    }
}
```
**验证指标**:
- [ ] 攻速提升80%以上时触发溅射
- [ ] 溅射对周围敌人造成伤害
- [ ] 溅射伤害为正常伤害的一定比例

---

### 4.4 狐狸 (fox)

**核心机制**: 魅惑敌人

#### 测试场景 1: Lv1 魅惑验证
```gdscript
{
    "id": "test_fox_lv1_charm",
    "core_type": "wolf_totem",
    "duration": 30.0,
    "units": [
        {"id": "fox", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "被攻击敌人有20%概率获得1层魂魄为你作战3秒",
        "verification": "约20%的攻击使敌人变为友方3秒"
    }
}
```
**验证指标**:
- [ ] 魅惑概率为20%
- [ ] 魅惑持续3秒
- [ ] 被魅惑敌人为我方作战

#### 测试场景 2: Lv2 献祭魅惑验证
```gdscript
{
    "id": "test_fox_lv2_sacrifice",
    "core_type": "wolf_totem",
    "duration": 35.0,
    "units": [
        {"id": "fox", "x": 0, "y": 1, "level": 2},
        {"id": "squirrel", "x": 1, "y": 0}  # 核心击杀单位
    ],
    "enemies": [
        {"type": "weak_enemy", "count": 5, "hp": 30}
    ],
    "expected_behavior": {
        "description": "魅惑敌人被核心击杀时获得1层血魂",
        "verification": "魅惑敌人被松鼠击杀后，获得血魂层数"
    }
}
```
**验证指标**:
- [ ] 魅惑敌人被友方击杀时获得血魂
- [ ] 血魂层数正确增加

#### 测试场景 3: Lv3 群体魅惑验证
**验证指标**:
- [ ] 可同时魅惑2个敌人
- [ ] 两个敌人同时为我方作战

---

### 4.5 羊灵 (sheep_spirit)

**核心机制**: 敌人阵亡时克隆

#### 测试场景 1: Lv1 克隆验证
```gdscript
{
    "id": "test_sheep_spirit_lv1_clone",
    "core_type": "wolf_totem",
    "duration": 25.0,
    "units": [
        {"id": "sheep_spirit", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "weak_enemy", "count": 3, "hp": 50, "positions": [{"x": 1, "y": 1}, {"x": 2, "y": 0}]}
    ],
    "expected_behavior": {
        "description": "附近敌人阵亡时复制1个40%属性的克隆体为你作战",
        "verification": "敌人死亡时生成克隆体，属性为原敌人的40%"
    }
}
```
**验证指标**:
- [ ] 敌人阵亡时生成克隆体
- [ ] 克隆体属性为原敌人的40%
- [ ] 克隆体为我方作战

#### 测试场景 2: Lv2 属性提升验证
**验证指标**:
- [ ] 克隆体属性为原敌人的60%

#### 测试场景 3: Lv3 双克隆验证
**验证指标**:
- [ ] 生成2个克隆体
- [ ] 每个克隆体属性为60%

---

### 4.6 狮子 (lion)

**核心机制**: 圆形冲击波

#### 测试场景 1: Lv1 冲击波验证
```gdscript
{
    "id": "test_lion_lv1_shockwave",
    "core_type": "wolf_totem",
    "duration": 15.0,
    "units": [
        {"id": "lion", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 1}, {"x": -1, "y": 1}, {"x": 0, "y": 2}]}
    ],
    "expected_behavior": {
        "description": "攻击变为圆形冲击波",
        "verification": "攻击时多个敌人同时受到伤害"
    }
}
```
**验证指标**:
- [ ] 攻击为圆形冲击波
- [ ] 冲击波对范围内所有敌人造成伤害

#### 测试场景 2: Lv2 威压回蓝验证
```gdscript
{
    "id": "test_lion_lv2_mana",
    "core_type": "wolf_totem",
    "duration": 20.0,
    "initial_mp": 500,
    "units": [
        {"id": "lion", "x": 0, "y": 1, "level": 2}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}, {"x": 2, "y": 2}]}
    ],
    "expected_behavior": {
        "description": "冲击波命中敌人时，所有友方恢复5点法力；命中3个以上额外恢复10点",
        "verification": "冲击波命中敌人时MP增加，命中3个以上时增加更多"
    }
}
```
**验证指标**:
- [ ] 命中敌人时所有友方回蓝5点
- [ ] 命中3个以上额外回蓝10点
- [ ] 回蓝量正确计算

#### 测试场景 3: Lv3 狮吼恐惧验证
```gdscript
{
    "id": "test_lion_lv3_fear",
    "core_type": "wolf_totem",
    "duration": 20.0,
    "units": [
        {"id": "lion", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "冲击波附加1秒恐惧效果，敌人朝随机方向逃跑",
        "verification": "被冲击波命中的敌人向后逃跑1秒"
    }
}
```
**验证指标**:
- [ ] 冲击波附加恐惧效果
- [ ] 恐惧持续1秒
- [ ] 恐惧时敌人朝反方向逃跑

---

## 五、眼镜蛇图腾流派单位测试

### 5.1 美杜莎 (medusa)

**核心机制**: 石化凝视

#### 测试场景 1: Lv1 石化验证
```gdscript
{
    "id": "test_medusa_lv1_petrify",
    "core_type": "viper_totem",
    "duration": 20.0,
    "units": [
        {"id": "medusa", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "每5秒石化最近敌人1秒",
        "verification": "每5秒最近的敌人被石化1秒，变为石块"
    }
}
```
**验证指标**:
- [ ] 每5秒触发一次
- [ ] 石化最近的敌人
- [ ] 石化持续1秒
- [ ] 石化时敌人变为石块

#### 测试场景 2: Lv2 石化时间提升验证
**验证指标**:
- [ ] 石化持续时间增加

#### 测试场景 3: Lv3 石块伤害验证
```gdscript
{
    "id": "test_medusa_lv3_damage",
    "core_type": "viper_totem",
    "duration": 25.0,
    "units": [
        {"id": "medusa", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 500}
    ],
    "expected_behavior": {
        "description": "石块额外造成敌人MaxHP的伤害",
        "verification": "石化结束时石块对敌人造成500点伤害"
    }
}
```
**验证指标**:
- [ ] 石化结束时造成伤害
- [ ] 伤害等于敌人最大血量

---

### 5.2 蜘蛛 (spider)

**核心机制**: 减速蛛网

#### 测试场景 1: Lv1 减速验证
```gdscript
{
    "id": "test_spider_lv1_slow",
    "core_type": "viper_totem",
    "duration": 20.0,
    "units": [
        {"id": "spider", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "fast_enemy", "speed": 100, "count": 3}
    ],
    "expected_behavior": {
        "description": "攻击使敌人减速40%",
        "verification": "被攻击的敌人移动速度降至60"
    }
}
```
**验证指标**:
- [x] 攻击使敌人减速40%
- [x] 减速效果持续

#### 测试场景 2: Lv2 减速提升验证
**验证指标**:
- [x] 减速效果提升至60%

#### 测试场景 3: Lv3 剧毒茧验证
```gdscript
{
    "id": "test_spider_lv3_cocoon",
    "core_type": "viper_totem",
    "duration": 25.0,
    "units": [
        {"id": "spider", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "weak_enemy", "count": 3, "hp": 50}
    ],
    "expected_behavior": {
        "description": "被网住并死亡的敌人生成小蜘蛛",
        "verification": "减速敌人死亡时生成小蜘蛛单位"
    }
}
```
**验证指标**:
- [x] 减速敌人死亡时生成小蜘蛛
- [x] 小蜘蛛为我方作战

---

### 5.3 箭毒蛙 (arrow_frog)

**核心机制**: 斩杀低血量敌人

#### 测试场景 1: Lv1 斩杀验证
```gdscript
{
    "id": "test_arrow_frog_lv1_execute",
    "core_type": "viper_totem",
    "duration": 20.0,
    "units": [
        {"id": "arrow_frog", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "poisoned_enemy", "hp": 100, "debuffs": [{"type": "poison", "stacks": 10}], "count": 3}
    ],
    "expected_behavior": {
        "description": "若敌人HP<Debuff层数*200%，则引爆斩杀",
        "verification": "10层中毒时，HP<2000的敌人被斩杀"
    }
}
```
**验证指标**:
- [ ] 斩杀条件: HP < 层数×200%
- [ ] 斩杀时引爆敌人
- [ ] 引爆造成伤害

#### 测试场景 2: Lv2 斩杀伤害提升验证
**验证指标**:
- [ ] 引爆伤害提升至250%

#### 测试场景 3: Lv3 传染引爆验证
```gdscript
{
    "id": "test_arrow_frog_lv3_spread",
    "core_type": "viper_totem",
    "duration": 25.0,
    "units": [
        {"id": "arrow_frog", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "poisoned_enemy", "hp": 50, "debuffs": [{"type": "poison", "stacks": 5}], "count": 5, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}]}
    ],
    "expected_behavior": {
        "description": "斩杀时将中毒层数传播给周围敌人",
        "verification": "敌人被斩杀时，周围敌人获得5层中毒"
    }
}
```
**验证指标**:
- [ ] 斩杀时传播中毒层数
- [ ] 传播给周围敌人

---

### 5.4 毒蛇 (viper)

**核心机制**: 赋予中毒Buff

#### 测试场景 1: Lv1 中毒Buff验证
```gdscript
{
    "id": "test_viper_lv1_poison",
    "core_type": "viper_totem",
    "duration": 20.0,
    "units": [
        {"id": "viper", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 被Buff单位
    ],
    "setup_actions": [
        {"type": "apply_buff", "buff_id": "poison", "target_unit_id": "squirrel"}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "赋予中毒Buff，攻击附加2层中毒",
        "verification": "松鼠攻击使敌人叠加2层中毒"
    }
}
```
**验证指标**:
- [ ] 可赋予1个单位中毒Buff
- [ ] 攻击附加2层中毒

#### 测试场景 2: Lv2 中毒层数提升验证
**验证指标**:
- [ ] 攻击附加3层中毒

#### 测试场景 3: Lv3 双目标验证
**验证指标**:
- [ ] 可赋予2个单位中毒Buff

---

### 5.5 蟾蜍 (toad)

**核心机制**: 放置毒陷阱

#### 测试场景 1: Lv1 毒陷阱验证
```gdscript
{
    "id": "test_toad_lv1_trap",
    "core_type": "viper_totem",
    "duration": 25.0,
    "units": [
        {"id": "toad", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "path": [{"x": 2, "y": 0}, {"x": 2, "y": 1}], "count": 3}
    ],
    "setup_actions": [
        {"type": "place_trap", "trap_id": "poison_trap", "position": {"x": 2, "y": 0}}
    ],
    "expected_behavior": {
        "description": "放置毒陷阱，敌人触发后受到伤害并中毒",
        "verification": "敌人经过陷阱时受到伤害和中毒"
    }
}
```
**验证指标**:
- [ ] 可放置1个毒陷阱
- [ ] 陷阱触发时敌人受到伤害
- [ ] 陷阱触发时敌人获得中毒

#### 测试场景 2: Lv2 陷阱数量提升验证
**验证指标**:
- [ ] 可放置2个毒陷阱

#### 测试场景 3: Lv3 额外伤害验证
```gdscript
{
    "id": "test_toad_lv3_damage",
    "core_type": "viper_totem",
    "duration": 25.0,
    "units": [
        {"id": "toad", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "敌人获得Debuff：每0.5秒受到额外伤害",
        "verification": "中毒敌人每0.5秒受到额外伤害"
    }
}
```
**验证指标**:
- [ ] 中毒敌人每0.5秒受到额外伤害
- [ ] 额外伤害数值正确

---

### 5.6 老鼠 (rat)

**核心机制**: 传播瘟疫

#### 测试场景 1: Lv1 瘟疫传播验证
```gdscript
{
    "id": "test_rat_lv1_plague",
    "core_type": "viper_totem",
    "duration": 30.0,
    "units": [
        {"id": "rat", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "low_hp_enemy", "hp": 30, "count": 3}
    ],
    "expected_behavior": {
        "description": "命中敌人在4秒内死亡时传递2层毒给周围敌人",
        "verification": "被老鼠攻击的敌人在4秒内死亡时，周围敌人获得2层中毒"
    }
}
```
**验证指标**:
- [ ] 4秒内死亡的敌人触发传播
- [ ] 传递2层中毒给周围敌人

#### 测试场景 2: Lv2 传播效果提升验证
**验证指标**:
- [ ] 传播层数或范围提升

#### 测试场景 3: Lv3 多Debuff传播验证
```gdscript
{
    "id": "test_rat_lv3_multi_debuff",
    "core_type": "viper_totem",
    "duration": 30.0,
    "units": [
        {"id": "rat", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "low_hp_enemy", "hp": 30, "debuffs": [{"type": "poison", "stacks": 3}, {"type": "burn", "stacks": 2}], "count": 3}
    ],
    "expected_behavior": {
        "description": "传递时额外增加其他Debuff",
        "verification": "传播时不仅传递中毒，还传递其他Debuff"
    }
}
```
**验证指标**:
- [ ] 传播时传递多种Debuff
- [ ] 包括中毒以外的Debuff

---

### 5.7 蝎子 (scorpion)

**核心机制**: 放置尖刺陷阱

#### 测试场景 1: Lv1 尖刺陷阱验证
```gdscript
{
    "id": "test_scorpion_lv1_spike",
    "core_type": "viper_totem",
    "duration": 20.0,
    "units": [
        {"id": "scorpion", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
    ],
    "setup_actions": [
        {"type": "place_trap", "trap_id": "spike_trap", "position": {"x": 2, "y": 0}}
    ],
    "expected_behavior": {
        "description": "尖刺陷阱：敌人经过时受到伤害",
        "verification": "敌人经过陷阱时受到伤害"
    }
}
```
**验证指标**:
- [ ] 陷阱触发时造成伤害
- [ ] 伤害数值正确

#### 测试场景 2: Lv2 倒钩伤害验证
**验证指标**:
- [ ] 陷阱伤害提升

#### 测试场景 3: Lv3 流血Debuff验证
```gdscript
{
    "id": "test_scorpion_lv3_bleed",
    "core_type": "viper_totem",
    "duration": 25.0,
    "units": [
        {"id": "scorpion", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
    ],
    "expected_behavior": {
        "description": "经过时叠加一层流血Debuff",
        "verification": "敌人经过陷阱时获得1层流血"
    }
}
```
**验证指标**:
- [ ] 陷阱触发时叠加流血
- [ ] 流血层数为1层

---

### 5.8 雪人 (snowman)

**核心机制**: 冰冻陷阱

#### 测试场景 1: Lv1 冰冻陷阱验证
```gdscript
{
    "id": "test_snowman_lv1_freeze",
    "core_type": "viper_totem",
    "duration": 20.0,
    "units": [
        {"id": "snowman", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "path": [{"x": 2, "y": 0}], "count": 3}
    ],
    "scheduled_actions": [
        {"time": 2.0, "type": "place_trap", "trap_id": "freeze_trap", "position": {"x": 2, "y": 0}}
    ],
    "expected_behavior": {
        "description": "制造冰冻陷阱，延迟1.5秒后触发冰冻",
        "verification": "陷阱放置1.5秒后触发，范围内敌人被冻结"
    }
}
```
**验证指标**:
- [ ] 陷阱延迟1.5秒触发
- [ ] 冻结范围内敌人
- [ ] 冻结持续2秒

#### 测试场景 2: Lv2 冻结时间提升验证
**验证指标**:
- [ ] 冻结时间提升至3秒

#### 测试场景 3: Lv3 冰封剧毒验证
```gdscript
{
    "id": "test_snowman_lv3_ice_poison",
    "core_type": "viper_totem",
    "duration": 25.0,
    "units": [
        {"id": "snowman", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "poisoned_enemy", "hp": 100, "debuffs": [{"type": "poison", "stacks": 5}], "count": 3}
    ],
    "expected_behavior": {
        "description": "冰冻结束时敌人受到Debuff层数伤害",
        "verification": "冻结结束时，敌人受到5层中毒的伤害"
    }
}
```
**验证指标**:
- [ ] 冰冻结束时造成伤害
- [ ] 伤害与Debuff层数相关

---

## 六、鹰图腾流派单位测试

### 6.1 角雕 (harpy_eagle)

**核心机制**: 三连击

#### 测试场景 1: Lv1 三连击验证
```gdscript
{
    "id": "test_harpy_eagle_lv1_triple",
    "core_type": "eagle_totem",
    "duration": 15.0,
    "units": [
        {"id": "harpy_eagle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "快速3次攻击，第3次暴击概率*2",
        "verification": "攻击周期内有3次伤害事件，第3次暴击率更高"
    }
}
```
**验证指标**:
- [ ] 每次攻击周期3次伤害
- [ ] 第3次暴击概率翻倍

#### 测试场景 2: Lv2 暴击概率提升验证
**验证指标**:
- [ ] 第3次暴击概率*3

#### 测试场景 3: Lv3 必定暴击验证
```gdscript
{
    "id": "test_harpy_eagle_lv3_crit",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "harpy_eagle", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "第3次攻击必定暴击并触发图腾回响",
        "verification": "第3次攻击必定暴击，触发鹰图腾的额外攻击"
    }
}
```
**验证指标**:
- [ ] 第3次必定暴击
- [ ] 触发图腾回响

---

### 6.2 红隼 (kestrel)

**核心机制**: 眩晕

#### 测试场景 1: Lv1 俯冲眩晕验证
```gdscript
{
    "id": "test_kestrel_lv1_dive",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "kestrel", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "攻击有20%概率造成1秒眩晕",
        "verification": "约20%的攻击使敌人眩晕1秒"
    }
}
```
**验证指标**:
- [ ] 眩晕概率20%
- [ ] 眩晕持续1秒

#### 测试场景 2: Lv2 概率和时间提升验证
**验证指标**:
- [ ] 眩晕概率30%
- [ ] 眩晕时间1.2秒

#### 测试场景 3: Lv3 音爆验证
```gdscript
{
    "id": "test_kestrel_lv3_sonic",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "kestrel", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 2, "y": 0}, {"x": 2, "y": 1}]}
    ],
    "expected_behavior": {
        "description": "眩晕触发时造成小范围震荡伤害",
        "verification": "眩晕触发时，周围敌人也受到伤害"
    }
}
```
**验证指标**:
- [ ] 眩晕时触发范围伤害
- [ ] 范围内敌人受到伤害

---

### 6.3 猫头鹰 (owl)

**核心机制**: 增加友军暴击率

#### 测试场景 1: Lv1 洞察验证
```gdscript
{
    "id": "test_owl_lv1_insight",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "owl", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 相邻友军
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "增加相邻友军12%暴击率",
        "verification": "松鼠暴击率增加12%"
    }
}
```
**验证指标**:
- [ ] 相邻友军暴击率+12%
- [ ] 仅影响相邻单位

#### 测试场景 2: Lv2 效果和范围提升验证
**验证指标**:
- [ ] 暴击率加成20%
- [ ] 影响范围2格

#### 测试场景 3: Lv3 回响洞察验证
```gdscript
{
    "id": "test_owl_lv3_echo",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "owl", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "相邻友军触发图腾回响时攻速+15%持续3秒",
        "verification": "松鼠触发回响时，攻速提升15%持续3秒"
    }
}
```
**验证指标**:
- [ ] 触发回响时攻速+15%
- [ ] 持续3秒

---

### 6.4 喜鹊 (magpie)

**核心机制**: 偷取属性

#### 测试场景 1: Lv1 闪光物验证
```gdscript
{
    "id": "test_magpie_lv1_steal",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "magpie", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10, "attack": 20}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "攻击有15%概率偷取敌人属性",
        "verification": "约15%的攻击偷取敌人攻击力或攻速"
    }
}
```
**验证指标**:
- [ ] 偷取概率15%
- [ ] 偷取属性增加自身
- [ ] 敌人属性暂时降低

#### 测试场景 2: Lv2 偷取效果提升验证
**验证指标**:
- [ ] 偷取概率25%
- [ ] 偷取效果+50%

#### 测试场景 3: Lv3 报喜验证
```gdscript
{
    "id": "test_magpie_lv3_reward",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "core_health": 400,
    "max_core_health": 500,
    "initial_gold": 100,
    "units": [
        {"id": "magpie", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 10}
    ],
    "expected_behavior": {
        "description": "偷取成功时随机给核心回复10HP或10金币",
        "verification": "偷取触发时，核心血量或金币增加"
    }
}
```
**验证指标**:
- [ ] 偷取成功时核心回血10点或金币+10
- [ ] 效果随机触发

---

### 6.5 鸽子 (pigeon)

**核心机制**: 闪避

#### 测试场景 1: Lv1 闪避验证
```gdscript
{
    "id": "test_pigeon_lv1_dodge",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "pigeon", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "attacker_enemy", "count": 10, "attack_speed": 2.0}  # 多次攻击触发概率
    ],
    "expected_behavior": {
        "description": "敌人攻击有12%概率Miss",
        "verification": "约12%的敌人攻击Miss"
    }
}
```
**验证指标**:
- [ ] 闪避概率12%
- [ ] 闪避时不受伤害

#### 测试场景 2: Lv2 闪避提升和无敌验证
**验证指标**:
- [ ] 闪避概率20%
- [ ] 闪避后0.3秒内无敌

#### 测试场景 3: Lv3 闪避反击验证
```gdscript
{
    "id": "test_pigeon_lv3_counter",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "pigeon", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "attacker_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "闪避时反击，反击可暴击并触发图腾回响",
        "verification": "闪避时自动反击敌人，伤害可暴击"
    }
}
```
**验证指标**:
- [ ] 闪避时自动反击
- [ ] 反击可暴击
- [ ] 触发图腾回响

---

### 6.6 啄木鸟 (woodpecker)

**核心机制**: 叠加伤害

#### 测试场景 1: Lv1 钻孔验证
```gdscript
{
    "id": "test_woodpecker_lv1_drill",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "woodpecker", "x": 0, "y": 1, "level": 1, "attack": 10}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 500}
    ],
    "expected_behavior": {
        "description": "攻击同一目标时每次伤害+10%(上限+100%)",
        "verification": "连续攻击同一敌人，伤害逐渐增加到20点"
    }
}
```
**验证指标**:
- [ ] 每次攻击同一目标伤害+10%
- [ ] 上限+100%(伤害翻倍)
- [ ] 切换目标重置叠加

#### 测试场景 2: Lv2 叠加速度和上限提升验证
**验证指标**:
- [ ] 叠加速度+50%(每次+15%)
- [ ] 上限150%

#### 测试场景 3: Lv3 必定暴击验证
```gdscript
{
    "id": "test_woodpecker_lv3_crit",
    "core_type": "eagle_totem",
    "duration": 30.0,
    "units": [
        {"id": "woodpecker", "x": 0, "y": 1, "level": 3}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 1000}
    ],
    "expected_behavior": {
        "description": "叠满后下3次攻击必定暴击并触发图腾回响",
        "verification": "叠满后3次攻击必定暴击，触发回响"
    }
}
```
**验证指标**:
- [ ] 叠满后3次攻击必定暴击
- [ ] 必定触发图腾回响

---

### 6.7 鹦鹉 (parrot)

**核心机制**: 模仿友军攻击特效

#### 测试场景 1: Lv1 模仿验证
```gdscript
{
    "id": "test_parrot_lv1_mimic",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "parrot", "x": 0, "y": 1, "level": 1},
        {"id": "woodpecker", "x": 1, "y": 0, "level": 1}  # 被模仿单位
    ],
    "setup_actions": [
        {"type": "mimic", "source": "parrot", "target": "woodpecker"}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "count": 1, "hp": 500}
    ],
    "expected_behavior": {
        "description": "模仿相邻友军的攻击特效",
        "verification": "鹦鹉获得啄木鸟的钻孔效果"
    }
}
```
**验证指标**:
- [ ] 可复制相邻友军特效
- [ ] 模仿后获得相同效果

#### 测试场景 2: Lv2 模仿效果提升验证
**验证指标**:
- [ ] 模仿效果+50%

#### 测试场景 3: Lv3 完美模仿验证
**验证指标**:
- [ ] 可模仿Lv.3单位的特效

---

### 6.8 孔雀 (peacock)

**核心机制**: 范围攻速加成

#### 测试场景 1: Lv1 开屏验证
```gdscript
{
    "id": "test_peacock_lv1_display",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "peacock", "x": 0, "y": 1, "level": 1},
        {"id": "squirrel", "x": 1, "y": 0}  # 范围内友军
    ],
    "expected_behavior": {
        "description": "每5秒展开尾屏，范围内友军攻速+10%",
        "verification": "每5秒松鼠攻速提升10%持续一定时间"
    }
}
```
**验证指标**:
- [ ] 每5秒触发一次
- [ ] 范围内友军攻速+10%

#### 测试场景 2: Lv2 效果和范围提升验证
**验证指标**:
- [ ] 攻速加成+20%
- [ ] 范围扩大

#### 测试场景 3: Lv3 鼓舞验证
```gdscript
{
    "id": "test_peacock_lv3_inspire",
    "core_type": "eagle_totem",
    "duration": 25.0,
    "units": [
        {"id": "peacock", "x": 0, "y": 1, "level": 3},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "enemies": [
        {"type": "buffed_enemy", "buffs": [{"type": "armor", "stacks": 3}], "count": 3}
    ],
    "expected_behavior": {
        "description": "范围内友军攻击附带驱散效果",
        "verification": "松鼠攻击驱散敌人的Buff"
    }
}
```
**验证指标**:
- [ ] 攻击附带驱散
- [ ] 驱散敌人Buff

---

### 6.9 疾风鹰 (gale_eagle)

**核心机制**: 多道风刃

#### 测试场景 1: Lv1 风刃连击验证
```gdscript
{
    "id": "test_gale_eagle_lv1_wind",
    "core_type": "eagle_totem",
    "duration": 15.0,
    "units": [
        {"id": "gale_eagle", "x": 0, "y": 1, "level": 1, "attack": 100}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "每次攻击发射2道风刃，每道60%伤害",
        "verification": "每次攻击造成2次60点伤害"
    }
}
```
**验证指标**:
- [ ] 每次攻击2道风刃
- [ ] 每道60%伤害

#### 测试场景 2: Lv2 风刃数量和伤害提升验证
**验证指标**:
- [ ] 风刃数量3道
- [ ] 每道80%伤害

#### 测试场景 3: Lv3 风刃暴击验证
**验证指标**:
- [ ] 风刃可暴击
- [ ] 暴击触发图腾回响

---

### 6.10 老鹰 (eagle)

**核心机制**: 优先攻击高HP敌人

#### 测试场景 1: Lv1 鹰眼验证
```gdscript
{
    "id": "test_eagle_lv1_eye",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "eagle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "hp": 50, "count": 2},
        {"type": "high_hp_enemy", "hp": 200, "count": 1}
    ],
    "expected_behavior": {
        "description": "射程极远，优先攻击HP最高的敌人",
        "verification": "老鹰优先攻击高血量敌人"
    }
}
```
**验证指标**:
- [ ] 射程极远
- [ ] 优先攻击HP最高的敌人

#### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 射程+20%
- [ ] 对高HP敌人伤害+30%

#### 测试场景 3: Lv3 空中处决验证
```gdscript
{
    "id": "test_eagle_lv3_execute",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "eagle", "x": 0, "y": 1, "level": 3, "attack": 100}
    ],
    "enemies": [
        {"type": "full_hp_enemy", "hp": 100, "count": 3}
    ],
    "expected_behavior": {
        "description": "对HP>80%敌人的第一次攻击造成250%伤害",
        "verification": "满血敌人第一次受到250点伤害"
    }
}
```
**验证指标**:
- [ ] 对>80%HP敌人第一次攻击250%伤害
- [ ] 仅第一次攻击触发

---

### 6.11 秃鹫 (vulture)

**核心机制**: 优先攻击低HP敌人

#### 测试场景 1: Lv1 死神验证
```gdscript
{
    "id": "test_vulture_lv1_reaper",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "vulture", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "hp": 100, "count": 2},
        {"type": "low_hp_enemy", "hp": 30, "count": 1}
    ],
    "expected_behavior": {
        "description": "优先攻击HP最低的敌人",
        "verification": "秃鹫优先攻击低血量敌人"
    }
}
```
**验证指标**:
- [ ] 优先攻击HP最低的敌人

#### 测试场景 2: Lv2 伤害和击杀成长验证
**验证指标**:
- [ ] 对低HP敌人伤害+30%
- [ ] 击杀后永久攻击力+1

#### 测试场景 3: Lv3 腐肉大餐验证
**验证指标**:
- [ ] 击杀敌人后永久增加自身攻击力
- [ ] 可无限叠加

---

### 6.12 风暴鹰 (storm_eagle)

**核心机制**: 召唤雷电

#### 测试场景 1: Lv1 雷暴验证
```gdscript
{
    "id": "test_storm_eagle_lv1_storm",
    "core_type": "eagle_totem",
    "duration": 20.0,
    "units": [
        {"id": "storm_eagle", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 5}
    ],
    "expected_behavior": {
        "description": "召唤雷电攻击随机敌人",
        "verification": "随机敌人受到雷电伤害"
    }
}
```
**验证指标**:
- [ ] 召唤雷电攻击
- [ ] 目标随机

#### 测试场景 2: Lv2 伤害提升验证
**验证指标**:
- [ ] 雷电伤害提升

#### 测试场景 3: Lv3 范围扩大验证
**验证指标**:
- [ ] 雷暴范围扩大
- [ ] 可命中更多敌人

---

## 七、核心系统测试

### 7.1 魂魄系统 (wolf_totem)

#### 测试场景 1: 敌人阵亡获得魂魄
```gdscript
{
    "id": "test_soul_system_enemy",
    "core_type": "wolf_totem",
    "duration": 20.0,
    "units": [
        {"id": "squirrel", "x": 0, "y": 1}
    ],
    "enemies": [
        {"type": "weak_enemy", "count": 5, "hp": 30}
    ],
    "expected_behavior": {
        "description": "敌人阵亡时增加1个魂魄",
        "verification": "敌人死亡时魂魄数+1"
    }
}
```

#### 测试场景 2: 单位吞噬获得魂魄
```gdscript
{
    "id": "test_soul_system_devour",
    "core_type": "wolf_totem",
    "duration": 20.0,
    "units": [
        {"id": "tiger", "x": 0, "y": 1},
        {"id": "squirrel", "x": 1, "y": 0}
    ],
    "scheduled_actions": [
        {"time": 5.0, "type": "skill", "source": "tiger", "target": "squirrel"}
    ],
    "expected_behavior": {
        "description": "我方单位被吞噬增加10个魂魄",
        "verification": "吞噬松鼠后魂魄数+10"
    }
}
```

#### 测试场景 3: 图腾攻击附加魂魄伤害
```gdscript
{
    "id": "test_soul_system_attack",
    "core_type": "wolf_totem",
    "duration": 15.0,
    "initial_souls": 10,
    "units": [],
    "enemies": [
        {"type": "basic_enemy", "count": 3}
    ],
    "expected_behavior": {
        "description": "图腾每5秒攻击附带魂魄数*100%的伤害",
        "verification": "图腾攻击造成15+10=25点伤害"
    }
}
```

---

### 7.2 嘲讽系统 (cow_totem)

#### 测试场景 1: 嘲讽切换目标
```gdscript
{
    "id": "test_taunt_system_switch",
    "core_type": "cow_totem",
    "duration": 15.0,
    "units": [
        {"id": "squirrel", "x": 0, "y": -1},
        {"id": "yak_guardian", "x": 0, "y": 1, "level": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "count": 1}
    ],
    "expected_behavior": {
        "description": "敌人初始攻击松鼠，5秒后转为攻击牦牛守护",
        "verification": "敌人目标从松鼠切换到牦牛守护"
    }
}
```

---

### 7.3 流血吸血系统 (bat_totem)

#### 测试场景 1: 流血叠加
```gdscript
{
    "id": "test_bleed_stacks",
    "core_type": "bat_totem",
    "duration": 20.0,
    "units": [
        {"id": "mosquito", "x": 0, "y": 1}
    ],
    "enemies": [
        {"type": "high_hp_enemy", "hp": 500, "count": 1}
    ],
    "expected_behavior": {
        "description": "图腾每5秒攻击施加流血标记，可叠加",
        "verification": "敌人流血层数随时间增加"
    }
}
```

#### 测试场景 2: 攻击流血敌人吸血
```gdscript
{
    "id": "test_bleed_lifesteal",
    "core_type": "bat_totem",
    "duration": 20.0,
    "core_health": 400,
    "max_core_health": 500,
    "units": [
        {"id": "mosquito", "x": 0, "y": 1}
    ],
    "enemies": [
        {"type": "basic_enemy", "debuffs": [{"type": "bleed", "stacks": 5}], "count": 3}
    ],
    "expected_behavior": {
        "description": "攻击流血敌人可按流血层数回复核心生命",
        "verification": "蚊子攻击后核心血量增加"
    }
}
```

---

### 7.4 中毒系统 (viper_totem)

#### 测试场景 1: 图腾毒液攻击
```gdscript
{
    "id": "test_poison_system",
    "core_type": "viper_totem",
    "duration": 20.0,
    "units": [],
    "enemies": [
        {"type": "basic_enemy", "count": 3, "positions": [{"x": 3, "y": 3}, {"x": -3, "y": -3}]}
    ],
    "expected_behavior": {
        "description": "每5秒对距离最远的3个敌人降下毒液，施加3层中毒",
        "verification": "最远的3个敌人每5秒叠加3层中毒"
    }
}
```

---

### 7.5 商店阵营刷新系统

#### 测试场景 1: 狼图腾商店
```gdscript
{
    "id": "test_shop_wolf",
    "core_type": "wolf_totem",
    "duration": 5.0,
    "test_shop": true,
    "validate_shop_faction": "wolf_totem",
    "expected_behavior": {
        "description": "商店展示狼阵营单位和通用单位",
        "verification": "商店中出现tiger、dog、wolf等狼阵营单位"
    }
}
```

---

## 八、测试框架扩展需求

### 8.1 需要扩展的动作类型

| 动作类型 | 说明 | 优先级 |
|---------|------|--------|
| `damage_core` | 扣除核心血量 | P0 |
| `heal_core` | 回复核心血量 | P0 |
| `record_attack_speed` | 记录攻击速度 | P1 |
| `record_damage` | 记录伤害数值 | P0 |
| `record_lifesteal` | 记录吸血量 | P1 |
| `verify_form` | 验证形态 | P2 |
| `verify_shield` | 验证护盾值 | P1 |
| `verify_hp` | 验证血量 | P1 |
| `add_soul` | 添加魂魄 | P1 |
| `devour` | 吞噬单位 | P1 |
| `merge` | 合并单位 | P1 |
| `attach` | 附身/连接 | P2 |
| `mimic` | 模仿特效 | P2 |
| `apply_buff` | 施加Buff | P0 |
| `place_trap` | 放置陷阱 | P1 |
| `end_wave` | 结束波次 | P1 |

### 8.2 需要扩展的敌人类型

| 敌人类型 | 说明 | 属性 |
|---------|------|------|
| `weak_enemy` | 低血量敌人 | hp: 30-50 |
| `high_hp_enemy` | 高血量敌人 | hp: 500+ |
| `full_hp_enemy` | 满血敌人 | hp: 100, full_hp |
| `fast_enemy` | 快速敌人 | speed: 100+ |
| `attacker_enemy` | 会攻击的敌人 | attack_speed: 2.0 |
| `poisoned_enemy` | 带中毒的敌人 | debuffs: [poison] |
| `buffed_enemy` | 带Buff的敌人 | buffs: [armor] |

### 8.3 需要扩展的验证方法

| 验证方法 | 说明 |
|---------|------|
| `assert_damaged` | 验证受到伤害 |
| `assert_buff_applied` | 验证Buff已施加 |
| `assert_debuff_applied` | 验证Debuff已施加 |
| `assert_hp_changed` | 验证血量变化 |
| `assert_mp_changed` | 验证法力变化 |
| `assert_target_switched` | 验证目标切换 |
| `assert_clone_spawned` | 验证克隆体生成 |

---

## 九、测试优先级

### P0 - 核心机制测试
- 魂魄系统
- 嘲讽系统
- 流血吸血系统
- 中毒系统
- 各单位的Lv1基础机制

### P1 - 进阶机制测试
- 各单位的Lv2机制升级
- 主动技能测试
- Buff/Debuff系统
- 商店系统

### P2 - 特殊机制测试
- 各单位的Lv3终极机制
- 单位间交互
- 特殊场景测试

---

*文档创建时间: 2026-02-20*
*覆盖单位: 56个*
*测试场景: 150+*

**测试记录**:
- 测试日期: 2026-02-20
- 测试人员: Jules
- 测试结果: 通过
- 备注: 蜘蛛 (spider) Lv1/Lv2/Lv3 测试通过
