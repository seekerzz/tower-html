# 游戏设计文档

## 目录
1. [核心机制](#核心机制)
2. [BUFF/DEBUFF系统](#buffdebuff系统)
3. [击退机制](#击退机制)
4. [商店机制](#商店机制)
5. [单位设计](#单位设计按图腾流派分类)

---

## 核心机制

### 开局设定

| 属性 | 数值/说明 | 备注 |
|------|----------|------|
| 初始单位 | **无** | 玩家需自行购买第一个单位 |
| 初始金币 | 150 | 用于购买初始单位 |
| 初始法力 | 500/1000 | 当前500，上限1000 |
| 初始血量 | 500/500 | 基础血量500，开局无单位加成 |

### 血量(HP)机制

**计算公式：**
```
max_core_health = BASE_CORE_HP(500) + 所有单位max_hp之和 + permanent_health_bonus
core_health = 根据最大血量动态调整
```

| 机制 | 说明 |
|------|------|
| 基础核心血量 | 500（固定值，Constants.BASE_CORE_HP） |
| 单位加成 | 每个放置在格子上的单位的max_hp累加 |
| 实时计算 | 放置/移除单位时，max_core_health立即重新计算 |
| 当前血量调整 | 增减单位时，core_health同步增减相同数值 |
| **单位不死** | **重要：单个单位不会死亡，只有核心血量归零时游戏才失败** |
| 游戏结束条件 | core_health ≤ 0 时触发game_over |

> **重要机制说明**：
> - 单位**不会**因为受到敌人攻击而死亡
> - 单位只会被**吞噬**（用于升级）或**出售**
> - 敌人攻击**核心**造成伤害，当核心血量归零时游戏失败
> - 单位的血量只影响**核心最大血量**的计算

**示例：**
- 开局无单位：max = 500, current = 500
- 放置单位(100hp)：max = 600, current = 600
- 移除单位：max = 500, current = 500

### 法力(MP)机制

| 属性 | 数值 | 说明 |
|------|------|------|
| 初始法力 | 500 | 开局拥有 |
| 最大法力 | 1000 | 固定上限 |
| 战斗中回复 | 10点/秒 | 仅在波次进行中有效 |
| 波次结束回复 | 回满至1000 | 每波结束后自动恢复 |

### 金币机制

| 机制 | 数值 |
|------|------|
| 初始金币 | 150 |
| 击杀奖励 | +1金币/敌人 |
| 波次结束奖励 | 20 + 波次×5 |

### 格子扩建规则

| 规则 | 说明 |
|------|------|
| 初始扩建成本 | 50金币 |
| 成本递增 | 每次扩建后+10金币（50→60→70→...） |
| 扩建范围限制 | 仅限中心5×5区域（坐标范围：x∈[-2,2], y∈[-2,2]） |
| 扩建条件 | 只能扩建与**已解锁格子相邻**的锁定格子 |
| 操作方式 | 点击商店"扩建"按钮进入扩建模式，点击高亮格子进行扩建 |
| 遗物加成 | rapid_expansion遗物可减少30%扩建成本 |

**扩建流程：**
1. 波次进行中无法扩建
2. 点击商店"🏗️扩建"按钮进入扩建模式
3. 可扩建的格子会显示高亮提示
4. 点击目标格子，扣除金币后即可解锁
5. 再次点击"扩建"按钮退出扩建模式

### 回血方式

| 方式 | 来源 | 说明 |
|------|------|------|
| 单位技能 | 奶牛、蚊子等 | 特定单位技能可治疗核心 |
| 升级奖励 | 波次结束升级 | 选择"治疗核心"恢复10%最大血量 |
| 流血吸血 | 攻击流血敌人 | 根据流血层数回复生命值 |

### 防御机制

| 机制 | 效果 | 来源 |
|------|------|------|
| 不屈意志 | 血量归零时锁定为1点，5秒无敌 | indomitable_will遗物 |
| 生物质护甲 | 单次伤害上限为最大血量的5% | biomass_armor遗物 |
| 上帝模式 | 免疫所有伤害 | 作弊模式 |

### 核心图腾类型

> 以下图腾可在开局或特定条件下选择，提供不同的核心机制

| 图腾名称 | 效果描述 |
|---------|---------|
| 牛图腾 (cow_totem) | 受伤充能，5秒一次全屏反击 |
| 蝙蝠图腾 (bat_totem) | 每5秒攻击3个最近的敌人，施加流血标记。攻击流血敌人可回复核心生命 |
| 毒蛇图腾 (viper_totem) | 每5秒对距离最远的3个敌人降下毒液，造成伤害并施加3层中毒 |
| 蝴蝶图腾 (butterfly_totem) | 生成3颗环绕法球，无限穿透。命中敌人造成20伤害并恢复20法力 |
| 鹰之图腾 (eagle_totem) | 暴击时有30%概率触发一次回响，造成等额伤害并施加攻击特效 |

---

## BUFF/DEBUFF系统

### 我方BUFF（增益效果）

| BUFF名称 | 效果 | 是否堆叠 | 堆叠说明 | 来源单位 |
|---------|------|---------|---------|---------|
| range | 射程+25% | 否 | 重复获得无效 | 配置中定义 |
| speed | 攻速+20% | 否 | 重复获得无效 | 战鼓(Drum) |
| crit | 暴击率+25% | 否 | 重复获得无效 | 配置中定义 |
| bounce | 子弹弹射次数+1 | 是 | 每次获得+1次，可无限叠加 | 兔子(Rabbit)、反射魔镜(Mirror) |
| split | 子弹分裂次数+1 | 是 | 每次获得+1次，可无限叠加 | 多重棱镜(Splitter) |
| multishot | 额外发射2发子弹（散射） | 否 | 重复获得无效 | 八爪鱼(Octopus) |
| guardian_shield | 受到伤害减少5~15% | 否 | 重复获得无效 | 牦牛守护(Yak Guardian) |
| wealth | 击杀敌人获得金币 | 否 | 重复获得无效 | 招财猫(Lucky Cat) |
| fire | 攻击附加燃烧效果 | 否 | 重复获得无效 | 红莲火炬(Torch) |
| poison | 攻击附加中毒效果 | 否 | 重复获得无效 | 剧毒大锅(Cauldron)、毒蛇(Viper) |

**传播机制**：
- **范围**：周围1格范围内的所有友方单位都可以获得BUFF
- **方式**：放置Buff提供者单位后，**需要手动选择**目标单位赋予BUFF
- 每个Buff提供者可以同时影响范围内的**多个单位**
- 被赋予的BUFF持续存在，直到Buff提供者被移除

### 敌方DEBUFF（减益效果）

| DEBUFF名称 | 伤害类型 | 基础数值 | 是否堆叠 | 堆叠说明 | 特殊机制 | 视觉效果 |
|-----------|---------|---------|---------|---------|---------|---------|
| 中毒(Poison) | DOT持续伤害 | 10点/秒 | 是 | 层数叠加，最大50层 | 伤害=基础×层数 | 绿色色调，随层数加深 |
| 燃烧(Burn) | DOT持续伤害 | 10点/0.5秒 | 是 | 层数叠加，无上限 | 死亡时范围爆炸，伤害=基础×3×层数 | 橙色十字斩击效果 |
| 减速(Slow) | 无伤害 | 移速×0.5 | 否 | 保留更强效果（取最小factor） | 效果结束自动恢复速度 | 蓝色色调 |
| 流血(Bleed) | DOT持续伤害 | 可配置 | 是 | 层数叠加 | 攻击流血敌人可吸血回复核心生命 | - |
| 晕眩(Stun) | 控制效果 | - | - | 直接设置定时器 | 无法移动和攻击 | - |
| 冻结(Freeze) | 控制效果 | - | - | 直接设置定时器 | 完全停止移动 | 蓝色色调 |

---

## 击退机制

### 概述

击退系统是游戏中的核心物理交互机制，通过施加瞬间冲击力改变敌人位置，可触发墙撞伤害、连锁碰撞等战术效果。

### 核心参数

| 参数 | 数值 | 说明 |
|------|------|------|
| 减速度 | 500.0 单位/秒 | 击退速度衰减率 |
| 最小击退阈值 | 10.0 | 低于此值视为静止 |
| 墙撞伤害系数 | 0.5 | 撞墙伤害 = 原始伤害 × 0.5 |
| 重击阈值 | 50.0 | 触发重击效果的动量阈值 |
| 传递效率 | 0.8 | 敌人碰撞时的击退传递比例 |

### 击退抗性

不同敌人拥有不同的击退抗性，影响击退效果：

| 敌人类型 | 抗性值 | 说明 |
|----------|--------|------|
| 普通敌人 | 1.0 | 标准抗性 |
| Boss/坦克 | 10.0 | 极难击退 |
| 螃蟹类 | 8.0 | 高抗性 |

**计算公式：**
```
实际击退力 = 击退力 / max(0.1, 击退抗性)
击退抗性 *= 质量修正系数(mass_mod)
```

### 击退来源

| 来源 | 击退计算 | 特殊效果 |
|------|----------|----------|
| 普通子弹 | 伤害 × 速度 × 0.005 | 标准击退 |
| 龙吼(roar) | 基础击退 × 2.0 | 双倍击退 |
| 雪球(snowball) | 基础击退 × 1.5 | 高击退 |
| 诱捕蛇(LureSnake) | 方向 × 拉动速度 | 将敌人拉向陷阱 |
| 黑洞(Black Hole) | 引力/距离 × 质量倒数 | 持续牵引效果 |

### 碰撞效果

#### 1. 撞墙检测

当击退中的敌人撞击墙壁时：
- 触发"Slam!"文字特效
- 造成额外伤害（原始伤害 × 0.5）
- 高动量撞击时触发屏幕震动
- 击退速度归零

#### 2. 敌人碰撞传递

击退中的敌人撞击其他敌人时：
- 根据质量比计算动量传递
- 传递效率为80%（TRANSFER_RATE）
- 被撞敌人获得部分击退速度
- 可能触发连锁碰撞反应

**动量计算公式：**
```gdscript
momentum = mass × knockback_velocity.length()
```

### 状态影响

击退状态会影响敌人行为：

| 状态 | 效果 |
|------|------|
| 移动控制 | 击退期间无法自主移动 |
| 攻击行为 | 击退期间停止攻击 |
| 技能咏唱 | 击退会打断支援单位的咏唱(SupportEnemy) |
| 传送判定 | 仙女龙传送成功率 = 基础概率 / 击退抗性 |

### 视觉反馈

虽然游戏没有专门的击退动画文件，但通过以下方式提供视觉反馈：

| 效果类型 | 实现方式 | 触发条件 |
|----------|----------|----------|
| 缩放抖动 | VisualController.wobble_scale | 击退发生时 |
| 旋转效果 | 物理碰撞后的朝向变化 | 碰撞后 |
| 文字特效 | "Slam!"浮动文字 | 撞墙时 |
| 屏幕震动 | GameManager.trigger_impact() | 重击阈值以上 |

### 代码位置

| 功能 | 文件路径 |
|------|----------|
| 击退核心逻辑 | `src/Scripts/Enemy.gd` (lines 32-33, 248-255, 373-417, 510-512) |
| 子弹击退计算 | `src/Scripts/Projectile.gd` (lines 269-290, 359-364) |
| 诱捕拉动效果 | `src/Scripts/Units/Behaviors/LureSnake.gd` (lines 92-94) |
| 传送抗性判定 | `src/Scripts/Units/Behaviors/FairyDragon.gd` (lines 8-21) |
| 咏唱打断检测 | `src/Scripts/Units/SupportEnemy.gd` (lines 31-36) |

---

## 商店机制

### 商店刷新机制 (P2-01)

商店卡牌根据当前选择的图腾类型展示对应阵营的单位：

| 图腾类型 | 主要阵营单位 | 通用单位 | 特殊规则 |
|----------|-------------|----------|----------|
| 狼图腾 | 狼阵营单位 (tiger, dog, wolf, hyena, fox, sheep_spirit, lion) | squirrel, octopus, bee, drum, mirror, splitter, lucky_cat | 全阵营单位展示 |
| 牛图腾 | 牛阵营单位 (plant, iron_turtle, hedgehog, yak_guardian, cow_golem, rock_armor_cow, oxpecker, mushroom_healer, cow, ascetic) | squirrel, octopus, bee, drum, mirror, splitter, lucky_cat | 苦修者(ascetic)完整展示 |
| 蝙蝠图腾 | 蝙蝠阵营单位 (mosquito, gargoyle, blood_mage, life_chain, plague_spreader, blood_chalice, blood_ancestor, blood_ritualist) | squirrel, octopus, bee, drum, mirror, splitter, lucky_cat | 血祭术士完整展示 |
| 毒蛇图腾 | 毒蛇阵营单位 (spider, scorpion, viper, arrow_frog, rat, toad, medusa, snowman) | squirrel, octopus, bee, drum, mirror, splitter, lucky_cat | 蟾蜍(toad)完整展示 |
| 蝴蝶图腾 | 蝴蝶阵营单位 (torch, butterfly, ice_butterfly, fairy_dragon, firefly, phoenix, eel, dragon, forest_sprite) | squirrel, octopus, bee, drum, mirror, splitter, lucky_cat | 冰晶蝶/萤火虫完整展示 |
| 鹰图腾 | 鹰阵营单位 (harpy_eagle, gale_eagle, kestrel, owl, eagle, vulture, magpie, pigeon, woodpecker, parrot, peacock, oxpecker, storm_eagle) | squirrel, octopus, bee, drum, mirror, splitter, lucky_cat | 红隼/猫头鹰/喜鹊/鸽子完整展示 |

### 商店界面

- 每次展示3张卡牌
- 每张卡牌显示单位图标、名称、价格和阵营标识
- 点击卡牌购买单位，放置到战场上
- 金币不足时卡牌显示为禁用状态

---

## 代码文件说明

| 功能 | 文件路径 |
|-----|---------|
| BUFF系统 | `src/Scripts/Unit.gd` |
| DEBUFF系统 | `src/Scripts/Enemy.gd` |
| 击退系统 | `src/Scripts/Enemy.gd`, `src/Scripts/Projectile.gd` |
| 核心血量计算 | `src/Autoload/GameManager.gd` - `recalculate_max_health()` |
| 开局设定 | `src/Scripts/MainGame.gd` - `_ready()` |
| 单位配置 | `data/game_data.json` |
| 图腾机制 | `src/Scripts/CoreMechanics/Mechanic*.gd` |

---

## 单位设计（按图腾流派分类）

> **图例说明**：
> - ✅ = 已实现
> - ⚠️ = 部分实现
> - ❌ = 未实现

### 🐮 牛图腾流派
**图腾效果**：受伤充能，5秒一次全屏反击

| 单位 | 定位 | 状态 | LV.1 | LV.2 | LV.3 |
|------|------|------|------|------|------|
| 树苗 (plant) | 辅助单位 | ⚠️ | 扎根：每波自身的Max HP+5% | 数值提升：Max HP加成 5%→8% | 世界树：周围一圈单位Max HP加成5% |
| 铁甲龟 (iron_turtle) | 攻击单位 | ⚠️ | 硬化皮肤：受到伤害减去固定数值20 | 数值提升：减伤 20→35 | 绝对防御：减伤提升至50，若伤害被减为0或者Miss则回复1%核心HP |
| 刺猬 (hedgehog) | 攻击单位 | ⚠️ | 尖刺：30%概率反弹敌人伤害 | 数值提升：50%概率反弹 | 刚毛散射：反伤时向周围发射3枚尖刺 |
| 牦牛守护 (yak_guardian) | 攻击单位 | ✅ | 每隔5s吸引周围的敌人攻击自己 | 每隔4s吸引周围的敌人攻击自己 | 图腾反击时牦牛攻击范围内敌人额外受到牦牛血量15%伤害 |
| 牛魔像 (cow_golem) | 攻击单位 | ✅ | 怒火中烧：每受击1次攻击力+3%（上限30%） | 数值提升：叠加上限 30%→50% | 充能震荡：受击时20%概率给敌人叠加一层瘟疫易伤Debuff |
| 岩甲牛 (rock_armor_cow) | 攻击单位 | ⚠️ | 岩甲护盾：每波开始时生成HP 100%护盾，攻击附加护盾50%的伤害 | 数值提升：护盾值100%→150% | 血量满时将溢出回血10%转为护盾 |
| 牛椋鸟 (oxpecker) | Buff单位 | ⚠️ | 被附身单位攻击时额外攻击1次 | 数值提升：额外攻击伤害+50% | 给敌人叠加一层易伤Debuff |
| 菌菇治愈者 (mushroom_healer) | Buff单位 | ⚠️ | 孢子护盾：为周围友方添加1层孢子Buff(抵消敌人1次伤害，敌人叠加3层中毒Debuff) | 数值提升：孢子层数 3层 | 孢子耗尽时额外造成一次中毒伤害 |
| 奶牛 (cow) | 辅助单位 | ⚠️ | 治疗核心产奶：每5秒回复1%核心HP | 数值提升：触发频率 5秒→4秒 | 根据核心已损失血量额外回复 |
| 苦修者 (ascetic) | 辅助单位 | ✅ | 选择一个单位给予苦修者Buff，将受到伤害的12%转为MP | 将受到伤害的18%转为MP | 选择两个单位 |

---

### 🦇 蝙蝠图腾流派
**图腾效果**：每5秒攻击3个最近的敌人，施加流血标记。攻击流血敌人可按流血层数回复核心生命。

| 单位 | 定位 | 状态 | LV.1 | LV.2 | LV.3 |
|------|------|------|------|------|------|
| 蚊子 (mosquito) | 攻击单位 | ✅ | 吸食：造成30%攻击力伤害，攻击回复该单位HP的10% | 数值提升：伤害 30%→50%，回复比例 10%→30% | 登革热：对流血敌人伤害+100%，击杀时爆炸造成范围伤害 |
| 石像鬼 (gargoyle) | 攻击单位 | ✅ | 石化：核心HP<35%时进入石像形态，停止主动攻击，反弹敌人15%伤害；>65%HP时变回正常形态 | 反弹次数 2 | 反弹次数 3 |
| 血法师 (blood_mage) | 辅助单位 | ✅ | 血池降临：召唤血池区域，区域内敌人每秒受到dot伤害 | 数值提升 | 血池内敌人流血层数+1/秒 |
| 生命链条 (life_chain) | Buff单位 | ✅ | 连接1个最远敌人，每秒偷取生命值 | 连接敌人数量 2 | 痛苦传递：被连接敌人分摊受到伤害 |
| 瘟疫使者 (plague_spreader) | 辅助单位 | ✅ | 腐坏：敌人每次进入攻击范围内获得易伤debuff | 数值提升 | 传染：有瘟疫Buff的敌人每3秒传播给周围最近一个敌人 |
| 鲜血圣杯 (blood_chalice) | 辅助单位 | ✅ | 附近单位的吸血可以超过HP上限，但会缓慢流失，流失速度每0.5s 15% | 流失速度每0.5s 10% | 敌人每0.5s受到核心损失HP的伤害 |
| 血祖 (blood_ancestor) | Buff单位 | ✅ | 鲜血领域：每有受伤敌人，附身单位攻击+5%（上限+30%） | 数值提升 | 血怒：核心HP<50%时流血敌人受到伤害+25% |
| 血祭术士 (blood_ritualist) | 辅助单位 | ✅ | 鲜血仪式：主动技能，消耗20%核心HP，对攻击范围内敌人施加2层流血 | 流血层数 3层 | 血祭后5秒内吸血效果翻倍 |

---

### 🦋 蝴蝶图腾流派
**图腾效果**：生成3颗环绕法球，无限穿透。命中敌人造成20伤害并恢复造成伤害100%的法力。

| 单位 | 定位 | 状态 | LV.1 | LV.2 | LV.3 |
|------|------|------|------|------|------|
| 红莲火炬 (torch) | 辅助单位 | ✅ | 赋予周围一个单位燃烧Buff，燃烧可叠加5层 | 数值提升：额外可以赋予一个单位Buff | 爆燃：燃烧叠加到5层时引爆，造成目标10%最大HP伤害 |
| 蝴蝶 (butterfly) | 攻击单位 | ⚠️ | 法力光辉：消耗5%最大法力,并附加消耗法力100%的伤害 | 数值提升：附加150%的伤害 | 每次击杀敌人恢复10%最大法力 |
| 冰晶蝶 (ice_butterfly) | Buff单位 | ✅ | 极寒：攻击给敌人叠加一层冰冻debuff，叠满3层冻结1秒 | 数值提升：冻结时间 1→2秒 | 极寒增幅：法球命中冻结敌人时伤害翻倍 |
| 仙女龙 (fairy_dragon) | 攻击单位 | ⚠️ | 传送：25%概率将敌人传送至3格外 | 数值提升：传送概率 25%→40% | 相位崩塌：被传送敌人叠加两层瘟疫debuff |
| 萤火虫 (firefly) | 攻击单位 | ✅ | 闪光：攻击不造成伤害，给敌人一层致盲debuff | 数值提升：致盲持续时间+2秒 | 闪光回蓝：致盲敌人每次Miss回复8法力 |
| 凤凰 (phoenix) | 攻击单位 | ⚠️ | 火雨AOE，持续3秒 | 数值提升：火雨伤害+50% | 燃烧回蓝+临时法球 |
| 电鳗 (eel) | 攻击单位 | ⚠️ | 闪电链，最多弹射4次 | 闪电伤害+50% | 法力震荡：每次弹射回复3法力 |
| 龙 (dragon) | 辅助单位 | ✅ | 黑洞控制，持续4秒 | 数值提升：黑洞范围+20%，持续时间 4→6秒 | 星辰坠落：黑洞结束时根据吸入敌人数量造成伤害 |
| 森林精灵 (forest_sprite) | Buff单位 | ✅ | 单位攻击给敌人增加随机Debuff | 数值提升 | 额外增加概率 |

---

### 🐺 狼图腾流派
**图腾效果**：敌人阵亡时会增加1个魂魄，我方单位被吞噬增加10个，图腾每5s攻击一次，附带魂魄数*100%的伤害

| 单位 | 定位 | 状态 | LV.1 | LV.2 | LV.3 |
|------|------|------|------|------|------|
| 猛虎 (tiger) | 攻击单位 | ⚠️ | 主动技能：全屏流星雨 | 机制保留：血怒：每层血魂使暴击率+3% | 猛虎吞噬：击杀敌人时可选择是否吞噬相邻友方 |
| 恶霸犬 (dog) | 攻击单位 | ⚠️ | 狂暴：核心HP每降低10%，攻速+5% | 核心HP每降低10%，攻速+10% | 攻速+80%以上时，可以造成溅射 |
| 狼 (wolf) | 攻击单位 | ❌ | 登场时必须选择一个单位吞噬，继承50%攻击力和血量及攻击机制 | 合并升级时保留两只狼各自的攻击机制 | 无法升到Lv.3 |
| 鬣狗 (hyena) | 攻击单位 | ❌ | 残血收割：攻击HP<30%敌人时额外附加1次20%伤害 | 残血收割：攻击HP<30%敌人时额外附加1次50%伤害 | 残血收割：攻击HP<30%敌人时额外附加2次50%伤害 |
| 狐狸 (fox) | Buff单位 | ❌ | 魅惑：被攻击敌人有20%概率立即获得1层魂魄为你作战3秒 | 机制保留：献祭魅惑：魅惑敌人被核心击杀时获得1层血魂 | 群体魅惑：可同时魅惑2个敌人 |
| 羊灵 (sheep_spirit) | 辅助单位 | ✅ | 附近敌人阵亡时复制1个40%属性的克隆体为你作战 | 附近敌人阵亡时复制1个60%属性的克隆体为你作战 | 附近敌人阵亡时复制2个60%属性的克隆体为你作战 |
| 狮子 (lion) | 攻击单位 | ⚠️ | 攻击变为圆形冲击波 | TODO | TODO |

---

### 🐍 眼镜蛇图腾流派
**图腾效果**：每5秒对距离最远的3个敌人降下毒液，造成伤害并施加3层中毒。

| 单位 | 定位 | 状态 | LV.1 | LV.2 | LV.3 |
|------|------|------|------|------|------|
| 蜘蛛 (spider) | 攻击单位 | ⚠️ | 减速蛛网：攻击使敌人减速40% | 数值提升：减速效果 40%→60% | 剧毒茧：被网住并死亡的敌人生成小蜘蛛 |
| 雪人 (snowman) | 辅助单位 | ✅ | 可以制造冰冻陷阱，延迟1.5秒后冰冻陷阱触发 | 数值提升：冰冻时间 2→3秒 | 冰封剧毒：冰冻结束时敌人受到Debuff层数伤害 |
| 蝎子 (scorpion) | 辅助单位 | ⚠️ | 尖刺陷阱：敌人经过时受到伤害 | 增加倒钩伤害 | 经过时叠加一层流血Debuff |
| 毒蛇 (viper) | 辅助 | ✅ | 赋予中毒Buff，攻击附加2层中毒 | 数值提升：中毒层数 2→3层/次 | 可以选择周围两个单位赋予中毒Buff |
| 箭毒蛙 (arrow_frog) | 攻击单位 | ⚠️ | 若敌人HP<Debuff层数*200%，则引爆斩杀 | 引爆伤害250% | 传染引爆：斩杀时将中毒层数传播给周围敌人 |
| 老鼠 (rat) | Buff单位 | ✅ | 散播瘟疫：命中敌人在4秒内死亡时传递2层毒给周围敌人 | 数值提升 | 传递时额外增加其他Debuff |
| 蟾蜍 (toad) | 辅助单位 | ✅ | 放毒陷阱 | 可以放置2个毒陷阱 | 敌人获得Debuff：每0.5s受到额外伤害 |
| 美杜莎 (medusa) | 辅助单位 | ⚠️ | 石化凝视：每5s石化最近敌人1秒 | 数值提升 | 石块额外造成敌人MaxHP的伤害 |

---

### 🦅 鹰图腾流派
**图腾效果**：暴击时有30%概率触发一次回响，造成等额伤害并施加攻击特效。

| 单位 | 定位 | 状态 | LV.1 | LV.2 | LV.3 |
|------|------|------|------|------|------|
| 角雕 (harpy_eagle) | 攻击单位 | ✅ | 三连爪击：快速3次攻击，第3次暴击概率*2 | 三连爪击：快速3次攻击，第3次暴击概率*3 | 暴击爪击：第3次攻击必定暴击并触发图腾回响 |
| 疾风鹰 (gale_eagle) | 攻击单位 | ✅ | 风刃连击：每次攻击发射2道风刃，每道60%伤害 | 数值提升：风刃数量 2→3道，每道伤害 60%→80% | 风刃暴击：风刃可以暴击并触发图腾回响；风暴风刃 |
| 红隼 (kestrel) | 攻击单位 | ✅ | 俯冲：攻击有20%概率造成1秒眩晕 | 数值提升：眩晕概率 30%，眩晕时间 1.2秒 | 音爆：眩晕触发时造成小范围震荡伤害 |
| 猫头鹰 (owl) | 辅助单位 | ✅ | 洞察：增加相邻友军12%暴击率 | 数值提升：暴击率加成 20%，影响范围 相邻→2格 | 回响洞察：相邻友军触发图腾回响时攻速+15%持续3秒 |
| 老鹰 (eagle) | 攻击单位 | ✅ | 鹰眼：射程极远，优先攻击HP最高的敌人 | 数值提升：射程+20%，对高HP敌人伤害+30% | 空中处决：对HP>80%敌人的第一次攻击造成250%伤害 |
| 秃鹫 (vulture) | Buff单位 | ✅ | 死神：优先攻击HP最低的敌人 | 数值提升：对低HP敌人伤害+30%，击杀后永久攻击力+1 | 腐肉大餐：击杀敌人后永久增加自身攻击力 |
| 喜鹊 (magpie) | Buff单位 | ✅ | 闪光物：攻击有15%概率偷取敌人属性 | 数值提升：偷取概率 25%，偷取效果+50% | 报喜：偷取成功时随机给核心回复10HP或10金币 |
| 鸽子 (pigeon) | 辅助单位 | ✅ | 敌人攻击有12%概率Miss | 数值提升：闪避概率 20%，闪避后0.3秒内无敌 | 闪避反击：闪避时反击，反击可暴击并触发图腾回响 |
| 啄木鸟 (woodpecker) | 攻击单位 | ✅ | 钻孔：攻击同一目标时每次伤害+10%（上限+100%） | 数值提升：叠加速度+50%，叠加上限 100%→150% | 钻孔精通：叠满后下3次攻击必定暴击并触发图腾回响 |

---

*文档更新时间：2026-02-19 (P0-P2 阶段完成)*

---

## 实现状态对照表

> 以下表格记录了设计文档中的单位与机制在实际代码中的实现状态。
> - ✅ = 已实现
> - ⚠️ = 部分实现
> - ❌ = 未实现

### 图腾机制

| 图腾 | 状态 | 说明 |
|-----|------|------|
| 牛图腾 | ✅ | 受伤充能，5秒一次全屏反击，伤害公式为`受击次数*5` |
| 蝙蝠图腾 | ✅ | 5秒攻击3个最近敌人施加流血，攻击流血敌人回血由LifestealManager处理 |
| 毒蛇图腾 | ✅ | 每5秒对距离最远的3个敌人降下毒液，造成伤害并施加3层中毒 |
| 蝴蝶图腾 | ✅ | 生成3颗环绕法球，无限穿透，命中敌人造成20伤害并恢复20法力 |
| 鹰之图腾 | ✅ | 暴击时有30%概率触发一次回响，造成等额伤害并施加攻击特效 |
| 狼图腾 | ✅ | 敌人阵亡获得1魂魄，单位吞噬获得10魂魄，图腾每5秒攻击附带魂魄数伤害 |

### 牛图腾流派

| 单位 | 状态 | 说明 |
|-----|------|------|
| 树苗 (plant) | ⚠️ | 基础实现，Lv3世界树周围加成需验证 |
| 铁甲龟 (iron_turtle) | ⚠️ | 基础减伤实现，Lv3伤害减为0回复HP未实现 |
| 刺猬 (hedgehog) | ⚠️ | 基础反弹实现，Lv3刚毛散射未实现 |
| 牦牛守护 (yak_guardian) | ✅ | 嘲讽机制已实现，Lv3图腾联动已实现 |
| 牛魔像 (cow_golem) | ✅ | 怒火中烧机制完整实现 |
| 岩甲牛 (rock_armor_cow) | ⚠️ | 护盾机制实现，攻击附加护盾伤害待验证 |
| 牛椋鸟 (oxpecker) | ⚠️ | 额外攻击实现，Lv3易伤Debuff待验证 |
| 菌菇治愈者 (mushroom_healer) | ⚠️ | 孢子护盾实现，需与设计文档对齐 |
| 奶牛 (cow) | ⚠️ | 基础治疗实现，Lv3根据损失血量额外回复待验证 |
| 苦修者 (ascetic) | ✅ | 完整实现，受到伤害转MP机制 |

### 蝙蝠图腾流派

| 单位 | 状态 | 说明 |
|-----|------|------|
| 蚊子 (mosquito) | ✅ | 吸食机制完整实现，Lv3对流血增伤和击杀爆炸已实现 |
| 石像鬼 (gargoyle) | ✅ | 石化机制完整实现，反弹伤害和次数升级 |
| 血法师 (blood_mage) | ✅ | 血池机制实现，Lv3流血层数叠加已实现 |
| 生命链条 (life_chain) | ✅ | 生命偷取和伤害分摊机制完整实现 |
| 瘟疫使者 (plague_spreader) | ✅ | 易伤debuff和传染机制完整实现 |
| 鲜血圣杯 (blood_chalice) | ✅ | 吸血溢出和流失机制完整实现，Lv3核心损失伤害已实现 |
| 血祖 (blood_ancestor) | ✅ | 鲜血领域机制实现，Lv3血怒效果已实现 |
| 血祭术士 (blood_ritualist) | ✅ | 鲜血仪式主动技能完整实现，Lv3吸血翻倍已实现 |

### 蝴蝶图腾流派

| 单位 | 状态 | 说明 |
|-----|------|------|
| 红莲火炬 (torch) | ✅ | 燃烧buff赋予实现，Lv3爆燃待验证 |
| 蝴蝶 (butterfly) | ⚠️ | 基础实现，技能效果需验证 |
| 冰晶蝶 (ice_butterfly) | ✅ | 极寒冻结机制完整实现 |
| 仙女龙 (fairy_dragon) | ⚠️ | 传送机制实现，Lv3瘟疫debuff待验证 |
| 萤火虫 (firefly) | ✅ | 致盲和回蓝机制完整实现 |
| 凤凰 (phoenix) | ⚠️ | 火雨AOE实现，Lv3燃烧回蓝+临时法球待验证 |
| 电鳗 (eel) | ⚠️ | 闪电链实现，Lv3法力回复待验证 |
| 龙 (dragon) | ✅ | 黑洞控制完整实现，Lv3星辰坠落已实现 |
| 森林精灵 (forest_sprite) | ✅ | 随机debuff机制完整实现 |

### 狼图腾流派

| 单位 | 状态 | 说明 |
|-----|------|------|
| 猛虎 (tiger) | ⚠️ | 流星雨技能实现，血魂系统待完善 |
| 恶霸犬 (dog) | ⚠️ | 狂暴机制实现，Lv3溅射待验证 |
| 狼 (wolf) | ❌ | 吞噬继承机制待实现 |
| 鬣狗 (hyena) | ❌ | 残血收割机制待实现 |
| 狐狸 (fox) | ❌ | 魅惑机制待实现 |
| 羊灵 (sheep_spirit) | ✅ | 克隆体机制完整实现，通过SummonManager |
| 狮子 (lion) | ⚠️ | 圆形冲击波实现，Lv2/Lv3待完善 |

### 眼镜蛇图腾流派

| 单位 | 状态 | 说明 |
|-----|------|------|
| 蜘蛛 (spider) | ⚠️ | 减速蛛网实现，Lv3小蜘蛛生成待验证 |
| 雪人 (snowman) | ✅ | 冰冻陷阱完整实现 |
| 蝎子 (scorpion) | ⚠️ | 尖刺陷阱实现，Lv2动量伤害、Lv3流血待验证 |
| 毒蛇 (viper) | ⚠️ | 中毒buff赋予实现，Lv3双目标选择待验证 |
| 箭毒蛙 (arrow_frog) | ⚠️ | 斩杀机制实现，Lv3传播待验证 |
| 老鼠 (rat) | ✅ | 瘟疫传播机制完整实现 |
| 蟾蜍 (toad) | ✅ | 毒陷阱机制完整实现 |
| 美杜莎 (medusa) | ⚠️ | 石化凝视实现，石块机制待完善 |

### 鹰图腾流派

| 单位 | 状态 | 说明 |
|-----|------|------|
| 角雕 (harpy_eagle) | ✅ | 三连爪击完整实现，Lv3必暴击+回响已实现 |
| 疾风鹰 (gale_eagle) | ✅ | 风刃连击完整实现 |
| 红隼 (kestrel) | ✅ | 俯冲眩晕和音爆伤害完整实现 |
| 猫头鹰 (owl) | ✅ | 暴击率加成和回响洞察完整实现 |
| 老鹰 (eagle) | ✅ | 鹰眼机制完整实现 |
| 秃鹫 (vulture) | ✅ | 死神机制和永久成长完整实现 |
| 喜鹊 (magpie) | ✅ | 属性偷取和报喜机制完整实现 |
| 鸽子 (pigeon) | ✅ | 闪避和反击机制完整实现 |
| 啄木鸟 (woodpecker) | ✅ | 钻孔叠加机制完整实现 |

---

### 已实现核心系统

| 系统 | 状态 | 说明 |
|------|------|------|
| 魂魄系统 (SoulManager) | ✅ | 敌人阵亡+1魂魄，单位吞噬+10魂魄，图腾攻击附带魂魄伤害 |
| 嘲讽/仇恨系统 (AggroManager) | ✅ | 牦牛守护等单位可实现嘲讽，强制敌人改变目标 |
| 召唤物系统 (SummonManager) | ✅ | 支持小蜘蛛、克隆体等召唤单位，上限8个/源 |
| 流血吸血系统 (LifestealManager) | ✅ | 蝙蝠图腾单位攻击流血敌人时回复核心生命 |
| 属性偷取系统 | ✅ | 喜鹊已实现攻速/移速/防御偷取 |

### 待实现系统

| 系统 | 状态 | 影响单位 |
|------|------|----------|
| 魅惑/控制敌人系统 | ❌ | 狐狸 |
| 吞噬继承系统 | ❌ | 狼 |
| 石块/尸体利用系统 | ⚠️ | 美杜莎 |

---

## 自动化测试框架

本项目包含自动化测试框架，用于调试新单位、验证游戏机制，并确保在 Headless 环境（CI/CD）中的稳定性。

### 如何调试新单位

当你向游戏中添加新单位时，可以创建特定的测试用例来验证其行为、交互和属性，无需手动游玩。

#### 1. 定义测试用例

打开 `src/Scripts/Tests/TestSuite.gd` 并在 `get_test_config` 函数中添加新用例。

**测试用例命名规范：**
- 新单位测试: `test_{单位名}` 或 `test_{图腾名}_{单位名}`
- 系统测试: `test_{系统名}_system`
- 示例: `test_bat_totem_mosquito`, `test_taunt_system`

**完整配置示例：**

```gdscript
# ✅ 好的示例：蝙蝠图腾单位（需要等待图腾触发流血）
"test_bat_totem_mosquito":
    return {
        "id": "test_bat_totem_mosquito",
        "core_type": "bat_totem",           # 与被测单位阵营匹配
        "initial_gold": 1000,                # 充足的金币
        "start_wave_index": 1,               # 第一波敌人
        "duration": 20.0,                    # ⚠️ 关键：20秒让图腾施加流血
        "units": [
            {"id": "mosquito", "x": 0, "y": 1},  # 被测单位
            {"id": "yak_guardian", "x": 0, "y": 0}  # 辅助坦克吸引仇恨，让敌人存活更久
        ],
        "description": "测试蚊子单位的吸血和登革热技能（需要等待蝙蝠图腾流血）"
    }

# ❌ 不好的示例：时间太短，无法触发图腾机制
"test_bat_totem_mosquito_bad":
    return {
        "id": "test_bat_totem_mosquito_bad",
        "core_type": "bat_totem",
        "duration": 5.0,                     # ❌ 太短！蝙蝠图腾来不及攻击
        "units": [{"id": "mosquito", "x": 0, "y": 1}]
    }

# ✅ 好的示例：测试第二波（如果单位有波次相关机制）
"test_unit_wave2":
    return {
        "id": "test_unit_wave2",
        "core_type": "cow_totem",
        "start_wave_index": 2,               # 从第二波开始测试
        "duration": 25.0,
        "units": [{"id": "plant", "x": 0, "y": 1}]
    }
```

**关键字段说明：**

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | ✅ | 测试标识符，与用例名一致 |
| `core_type` | ✅ | 图腾类型，**必须与被测单位阵营匹配** |
| `initial_gold` | ✅ | 初始金币，建议 1000 |
| `start_wave_index` | ✅ | 起始波次，建议 1（波次相关机制可测 2） |
| `duration` | ✅ | 测试时长(秒)，**最低15，依赖图腾的用20-30** |
| `units` | ✅ | 要放置的单位数组，建议加辅助坦克 |
| `scheduled_actions` | ⚪ | 计划执行的动作 |
| `description` | ⚪ | 测试描述，注明特殊要求 |

**单位放置坐标参考：**
- 中心格子: `(0, 0)`
- 周围8格: `(0, 1)`, `(0, -1)`, `(1, 0)`, `(-1, 0)`, `(1, 1)`, `(-1, -1)`, `(1, -1)`, `(-1, 1)`
- 范围外: `(0, 2)`, `(2, 0)` 等

#### 2. Headless 模式运行（强制要求）

**这是 Jules 任务完成的必要条件。** 使用此模式验证单位逻辑、伤害计算和稳定性，无需渲染图形。

```bash
godot --path . --headless -- --run-test=test_new_unit
```

**测试通过标准：**
- 命令退出码为 0
- 终端输出无 `SCRIPT ERROR`
- 终端输出无 `ERROR:`
- 测试日志正常生成

**常见错误及修复：**

| 错误类型 | 示例 | 修复方法 |
|----------|------|----------|
| 信号未定义 | `Invalid access to property 'enemy_died'` | 在 GameManager 中添加信号定义 |
| 重复连接 | `Signal 'died' is already connected` | 检查 `connect()` 前添加 `is_connected()` 判断 |
| 资源不存在 | `Cannot open file 'Enemy.tscn'` | 检查场景文件路径是否正确 |
| 空引用 | `Cannot call method on null instance` | 添加 `is_instance_valid()` 检查 |

#### 3. GUI 模式运行（可视化检查）

可选，用于人工检查单位动画、弹道行为和视觉效果。

```bash
godot --path . -- --run-test=test_new_unit
```

*   游戏将直接启动进入测试场景
*   单位将自动放置
*   波次立即开始
*   游戏将在持续时间后自动关闭

#### 4. 分析测试日志

测试完成后，详细的 JSON 日志将生成在用户数据目录。

**日志位置：**
*   **Windows:** `%APPDATA%\Godot\app_userdata\Core Ranch_ Ultimate Battle\test_logs\`
*   **macOS:** `~/Library/Application Support/Godot/app_userdata/Core Ranch_ Ultimate Battle/test_logs/`
*   **Linux:** `~/.local/share/godot/app_userdata/Core Ranch_ Ultimate Battle/test_logs/`

**验证日志内容：**

```bash
# 检查日志文件是否存在
ls %APPDATA%/Godot/app_userdata/Core*Ranch*/test_logs/

# 查看日志中的伤害事件
cat test_new_unit.json | grep -o '"type": "hit"' | wc -l
```

**日志结构：**
日志文件（`test_new_unit.json`）包含帧快照数组。关键字段：

| 字段 | 说明 |
|------|------|
| `frame` | 帧编号 |
| `time` | 测试开始后的经过时间 |
| `core_health` | 核心当前血量 |
| `gold` | 当前金币 |
| `units` | 放置的单位列表 |
| `enemies` | 活跃敌人列表 |
| `events` | 事件列表 |

**事件类型：**
- `spawn`: 敌人生成
- `hit`: 敌人受到伤害（包含 `source` 来源单位和 `damage` 伤害值）

**验证要点：**
1. 日志中存在 `hit` 事件，证明单位正常攻击
2. `source` 字段与被测单位一致
3. 伤害数值符合预期
4. 无异常的错误事件

**日志条目示例：**
```json
{
    "frame": 60,
    "time": 1.0,
    "events": [
        {
            "type": "hit",
            "target_id": 12345,
            "source": "mosquito",
            "damage": 30,
            "target_hp_after": 70
        }
    ]
}
```

---

## Jules API 使用指南

### 概述

本项目使用 [Google Jules API](https://developers.google.com/jules/api) 自动化代码实现。Jules 是一个异步 AI 编程助手，可以并行处理多个独立的代码任务。

### 重要原则

1. **任务独立性**: 每个 Jules 任务都是独立的，没有共享上下文
2. **单任务原则**: 不要把多项任务集中到同一个 Jules 任务中，失败概率较高
3. **并行执行**: 可以大量并行执行多个独立的 Jules 任务
4. **进度同步**: 每个任务需要将进度刷新到 `docs/progress.md`
5. **测试要求**: 每个任务必须按照自动化测试框架规范进行测试
6. **GitHub同步**: Jules基于GitHub代码版本执行，必须及时合并分支并推送到GitHub

### GitHub同步和合并流程 (关键!)

**重要**: Jules是基于GitHub上的代码版本执行任务的。因此必须遵循以下流程：

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. 提交Jules任务  │ ──▶ │  2. 等待任务完成   │ ──▶ │  3. 代码审查     │
│  (创建feature分支) │     │  (Jules执行中)    │     │  (检查PR)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                         │
┌─────────────────┐     ┌─────────────────┐              │
│  6. 后续任务基于   │ ◀── │  5. 推送到GitHub  │ ◀────────┘
│    更新后的代码   │     │  (git push)     │
└─────────────────┘     └─────────────────┘
       │
       ▼
┌─────────────────┐
│  4. 合并到main   │
│  (Merge PR)     │
└─────────────────┘
```

#### 详细步骤

**步骤1: 提交Jules任务**
```bash
# 创建并切换到特性分支
git checkout -b feature/P0-01-soul-system

# 提交分支到GitHub（空分支或包含基础配置）
git push -u origin feature/P0-01-soul-system

# 提交Jules任务
python docs/jules_prompts/run_jules_task.py \
    --prompt docs/jules_prompts/P0_01_wolf_totem_soul_system.md \
    --task-id P0-01 \
    --wait
```

**步骤2: Jules任务完成后**

Jules会创建Pull Request。检查PR内容：
```bash
# 获取PR信息
gh pr list --head feature/P0-01-soul-system

# 查看PR详情
gh pr view feature/P0-01-soul-system
```

**步骤3: 代码审查**

必须验证以下内容：
- [ ] 所有测试通过
- [ ] 代码符合项目规范
- [ ] 没有引入安全问题
- [ ] 没有破坏现有功能

```bash
# 拉取PR分支进行本地测试
git fetch origin feature/P0-01-soul-system
git checkout feature/P0-01-soul-system

# 运行测试
godot --path . --headless -- --run-test=test_soul_system

# 返回main分支
git checkout main
```

**步骤4: 合并到main**

```bash
# 使用GitHub CLI合并PR
gh pr merge feature/P0-01-soul-system --squash --delete-branch

# 或者手动合并
git checkout main
git pull origin main
git merge --squash feature/P0-01-soul-system
git commit -m "[P0-01] 实现狼图腾魂魄系统"
git push origin main
```

**步骤5: 推送到GitHub**

确保main分支已推送：
```bash
git push origin main
```

**步骤6: 基于更新后的代码继续后续任务**

后续任务（如P1-A狼图腾单位）依赖于P0-01的代码，必须等待P0-01合并后才能提交：

```bash
# 确认P0-01已合并
git pull origin main

# 现在可以提交P1-A
git checkout -b feature/P1-A-wolf-units
git push -u origin feature/P1-A-wolf-units

python docs/jules_prompts/run_jules_task.py \
    --prompt docs/jules_prompts/P1_01_wolf_units_implementation.md \
    --task-id P1-A \
    --wait
```

### 依赖管理

由于GitHub同步要求，任务执行顺序受到依赖关系限制：

| 任务 | 依赖 | GitHub状态要求 |
|------|------|----------------|
| P0-01, P0-02, P0-03, P0-04 | 无 | 可同时提交，各自独立分支 |
| P1-A (狼单位) | P0-01, P0-03 | P0-01和P0-03必须已合并到main |
| P1-B (眼镜蛇单位) | 无 | 可立即提交 |
| P1-C (蝙蝠单位) | P0-04 | P0-04必须已合并到main |
| P1-D (蝴蝶单位) | 无 | 可立即提交 |
| P1-E (鹰单位) | 无 | 可立即提交 |
| P1-F (牛单位) | P0-02 | P0-02必须已合并到main |

### 推荐的执行计划

**第1波 - P0基础系统** (可并行提交，各自独立)
```bash
# 同时提交4个P0任务，各自独立分支
python docs/jules_prompts/run_jules_batch.py --phase P0

# 等待全部完成后，按顺序合并（避免冲突）
gh pr merge feature/P0-01-soul-system --squash --delete-branch
gh pr merge feature/P0-02-aggro-system --squash --delete-branch
gh pr merge feature/P0-03-summon-system --squash --delete-branch
gh pr merge feature/P0-04-lifesteal-system --squash --delete-branch
```

**第2波 - P1独立单位组** (无需等待P0的组)
```bash
# 提交不依赖P0的单位组
python docs/jules_prompts/run_jules_batch.py --tasks P1-B,P1-D,P1-E

# 合并到main
gh pr merge feature/P1-B-viper-units --squash --delete-branch
gh pr merge feature/P1-D-butterfly-units --squash --delete-branch
gh pr merge feature/P1-E-eagle-units --squash --delete-branch
```

**第3波 - P1依赖单位组** (必须等待P0合并)
```bash
# 确认P0已全部合并
git pull origin main

# 提交依赖P0的单位组
python docs/jules_prompts/run_jules_batch.py --tasks P1-A,P1-C,P1-F
```

### API 认证

#### 安全存储 API 密钥

1. 复制模板文件:
   ```bash
   cp docs/secrets/.env.example docs/secrets/.env
   ```

2. 编辑 `.env` 文件，填入 API 密钥:
   ```
   JULES_API_KEY=YOUR_JULES_API_KEY_HERE
   ```

3. **警告**: 不要将 `.env` 文件提交到 Git!

### 执行流程

```
Phase 1 (P0 基础系统 - 串行):
  P0-01 狼图腾魂魄系统 → P0-04 流血吸血系统 → P0-02 嘲讽系统 → P0-03 召唤系统

Phase 2 (P1 单位实现 - 并行):
  组A: 狼图腾单位 (等待 P0-01, P0-03)
  组B: 眼镜蛇单位 (可立即执行)
  组C: 蝙蝠单位 (等待 P0-04)
  组D: 蝴蝶单位 (可立即执行)
  组E: 鹰单位 (可立即执行)
  组F: 牛图腾单位 (等待 P0-02)
```

### 提交单个任务

```bash
# 基本用法
python docs/jules_prompts/run_jules_task.py \
    --prompt docs/jules_prompts/P0_01_wolf_totem_soul_system.md \
    --task-id P0-01

# 提交并等待完成
python docs/jules_prompts/run_jules_task.py \
    --prompt docs/jules_prompts/P0_01_wolf_totem_soul_system.md \
    --task-id P0-01 \
    --wait

# 自动批准计划
python docs/jules_prompts/run_jules_task.py \
    --prompt docs/jules_prompts/P0_01_wolf_totem_soul_system.md \
    --task-id P0-01 \
    --wait \
    --approve-plan
```

### 批量提交任务

```bash
# 查看所有可用任务
python docs/jules_prompts/run_jules_batch.py --list

# 提交所有 P0 任务
python docs/jules_prompts/run_jules_batch.py --phase P0

# 提交所有 P1 任务（并行）
python docs/jules_prompts/run_jules_batch.py --phase P1 --max-workers 6

# 提交特定组
python docs/jules_prompts/run_jules_batch.py --tasks P1-A,P1-B,P1-C

# 提交并等待完成
python docs/jules_prompts/run_jules_batch.py --phase P1 --wait
```

### Jules Prompt 模板要求

每个提交给 Jules 的 Prompt **必须包含**以下内容:

1. **进度同步指令**:
   ```markdown
   ## 进度同步要求

   你正在执行的任务ID是: {task_id}

   每次完成一个重要步骤后，立即更新 `docs/progress.md`:
   - 找到你的任务ID对应的条目
   - 更新状态: `in_progress` | `completed` | `failed`
   - 添加简短描述
   ```

2. **自动化测试要求**:
   ```markdown
   ## 自动化测试要求

   每个 Jules 任务实现的新单位或系统必须包含完整的自动化测试，测试通过是任务完成的必要条件。

   ### 测试用例设计规范

   测试用例必须覆盖以下方面：

   1. **构造测试条件**
      - 在 `src/Scripts/Tests/TestSuite.gd` 的 `get_test_config()` 中添加测试配置
      - **选择合适的图腾类型** (`core_type`)，与实现的单位阵营匹配
        - 牛图腾单位 → `cow_totem`
        - 蝙蝠图腾单位 → `bat_totem`
        - 蝴蝶图腾单位 → `butterfly_totem`
        - 狼图腾单位 → `wolf_totem`
        - 眼镜蛇图腾单位 → `viper_totem`
        - 鹰图腾单位 → `eagle_totem`
      - 设置充足的初始资源 (`initial_gold: 1000`)
      - 设置合理的波次 (`start_wave_index: 1`)

   2. **放置被测单位**
      - 在 `units` 数组中放置需要测试的单位
      - 如有需要，放置辅助单位（如坦克、buff提供者）
      - 示例:
        ```gdscript
        "units": [
            {"id": "new_unit_id", "x": 0, "y": 1},  # 被测单位
            {"id": "yak_guardian", "x": 0, "y": 0}   # 辅助坦克
        ]
        ```

   3. **设置测试动作（关键！对于有主动技能的单位）**
      - **必须测试主动技能**：如果单位有主动技能（`unit_data.skill` 不为空），必须在 `scheduled_actions` 中配置技能测试
      - 示例:
        ```gdscript
        "scheduled_actions": [
            {
                "time": 5.0,              # 波次开始后5秒触发
                "type": "skill",
                "source": "blood_mage",   # 技能释放者单位ID
                "target": {"x": 2, "y": 2}  # 技能目标位置（网格坐标）
            }
        ]
        ```
      - **技能测试时机**：
        - 第一波敌人出现后 `3-5` 秒释放，确保有目标
        - 如果技能CD较短，可以配置多个时间点测试多次释放
      - **注意**：未测试技能可能导致代码中的技能相关bug未被发现（如访问不存在的全局属性）

   4. **设置测试持续时间（关键！）**
      - `duration`: 测试运行秒数
      - **最低要求 15 秒**，确保：
        - 图腾机制有时间触发（如蝙蝠图腾每5秒攻击一次）
        - 敌人存活足够长时间，让debuff生效（如流血、中毒）
        - 单位能完成多次攻击循环
      - **推荐设置**:
        - 普通攻击单位：`15-20` 秒
        - 依赖图腾机制的单位：`20-30` 秒（如蝙蝠图腾需要等敌人获得流血层数）
        - 召唤/辅助单位：`25-30` 秒

   ### 测试通过标准

   测试必须同时满足以下条件才算通过：

   1. **无报错**: Headless 模式下无脚本错误、无信号连接错误、无资源加载错误
   2. **正常输出**: 游戏日志中无异常警告，单位行为符合预期
   3. **功能验证**: 通过日志验证单位造成伤害、触发技能等核心功能正常工作
   4. **稳定性**: 测试期间不崩溃，测试结束后正常退出

   ### 测试验证命令

   ```bash
   # 1. Headless 模式运行测试（必须无错误）
   godot --path . --headless -- --run-test=your_test_name

   # 2. GUI 模式检查视觉效果（可选，用于验证动画）
   godot --path . -- --run-test=your_test_name
   ```

   ### 测试失败处理

   如果测试失败，必须修复以下问题：
   - **SCRIPT ERROR**: 检查 GDScript 语法和运行时错误
   - **Invalid access to property/key**: 检查信号、变量名是否正确
   - **Signal already connected**: 确保信号只连接一次
   - **Resource loading failed**: 检查场景文件路径是否正确

   ### 测试覆盖要求

   **必须确保测试能触发单位的所有关键代码路径：**

   1. **图腾机制触发**
      - 牛图腾：受伤后5秒内触发反击 → 需要敌人攻击单位或核心
      - 蝙蝠图腾：每5秒给最近敌人施加流血 → 需要等待5秒以上
      - 蝴蝶图腾：法球环绕攻击 → 需要敌人进入范围
      - 狼图腾：敌人阵亡获得魂魄 → 需要击杀敌人
      - 毒蛇图腾：每5秒给最远敌人中毒 → 需要等待5秒以上
      - 鹰图腾：暴击触发回响 → 需要多次攻击触发暴击

   2. **Debuff/状态效果**
      - 流血效果：需要敌人存活到流血层数 > 0
      - 中毒效果：需要敌人存活到中 tick 伤害
      - 冰冻/眩晕：需要技能命中并生效

   3. **多波次测试（可选但推荐）**
      - 如果单位有波次相关机制（如每波开始时触发），设置 `start_wave_index: 2` 测试第二波
      - 确保单位在持续战斗中稳定工作

   4. **主动技能测试（关键！）**
      - **Bug案例**：血法师技能访问 `GameManager.skill_cost_reduction` 属性，但该属性不存在，导致技能释放时报错
      - **原因**：之前的测试只放置单位但不触发技能，代码路径未被覆盖
      - **教训**：任何有主动技能的单位必须通过 `scheduled_actions` 测试技能释放流程
      - **验证指标**：
        - 技能触发时无 `Invalid access to property/key` 错误
        - 技能效果正确（如血池创建、伤害/治疗生效）
        - 技能消耗正确计算（考虑 `skill_mana_cost_reduction` 全局buff）

   4. **失败案例分析**
      - `test_bat_totem_mosquito` 最初通过是因为敌人太快死亡，没有流血层数
      - `test_bat_totem_blood_mage` 暴露bug是因为血池持续伤害，敌人存活时间长，触发了吸血逻辑
      - **教训**：测试时间不足会遗漏关键代码路径

   ### 测试通过检查清单

   提交 PR 前确认：
   - [ ] Headless 测试运行完成且退出码为 0
   - [ ] 测试日志文件 `user://test_logs/your_test_name.json` 正常生成
   - [ ] 日志中包含单位造成的伤害事件（`"type": "hit"`）
   - [ ] 测试时长 >= 15 秒（依赖图腾机制的单位 >= 20 秒）
   - [ ] 无 "ERROR" 或 "WARNING" 级别的问题
   ```

3. **代码提交要求**:
   ```markdown
   ## 代码提交要求

   1. 在独立分支工作: `feature/{task_id}`
   2. 提交信息格式: `[{task_id}] 简要描述`
   3. 完成后创建 PR 到 main 分支
   4. PR 描述中必须包含测试结果截图或日志
   ```

### API 端点参考

| 端点 | 方法 | 描述 |
|------|------|------|
| `/v1alpha/sessions` | POST | 创建新会话 |
| `/v1alpha/sessions/{id}` | GET | 获取会话状态 |
| `/v1alpha/sessions/{id}:sendMessage` | POST | 发送消息 |
| `/v1alpha/sessions/{id}:approvePlan` | POST | 批准计划 |
| `/v1alpha/sessions/{id}/activities` | GET | 获取活动列表 |

### Session 状态

| 状态 | 说明 |
|------|------|
| `STATE_UNSPECIFIED` | 未指定 |
| `ACTIVE` | 活跃中 |
| `AWAITING_PLAN_APPROVAL` | 等待计划批准 |
| `COMPLETED` | 已完成 |
| `FAILED` | 失败 |
| `CANCELLED` | 已取消 |

### 代理设置

如果需要代理访问:

```bash
export HTTP_PROXY=http://127.0.0.1:10808
export HTTPS_PROXY=http://127.0.0.1:10808
```

或在 `.env` 文件中设置。

### 进度跟踪

所有任务进度记录在 `docs/progress.md`:

```markdown
| 任务ID | 状态 | 描述 | 更新时间 |
|--------|------|------|----------|
| P0-01 | completed | 魂魄系统实现完成 | 2026-02-19 10:00:00 |
| P0-02 | in_progress | 正在实现嘲讽逻辑 | 2026-02-19 11:30:00 |
```

### 故障排查

1. **API 密钥错误**: 检查 `JULES_API_KEY` 环境变量
2. **网络问题**: 配置代理设置
3. **任务失败**: 查看 Jules 控制台获取详细错误信息
4. **合并冲突**: 确保每个任务在独立分支上工作

### Python 客户端使用

```python
from docs.jules_prompts.jules_client import JulesClient, JulesTaskManager

# 创建客户端
client = JulesClient()

# 创建任务管理器
manager = JulesTaskManager(client)

# 提交任务
session_id = manager.submit_task(
    task_id="P0-01",
    prompt="docs/jules_prompts/P0_01_wolf_totem_soul_system.md",
    title="狼图腾魂魄系统"
)

# 等待完成
result = manager.wait_for_task("P0-01")
print(f"状态: {result['state']}")
```

---

## Bug 反馈与测试覆盖分析

### 2026-02-19 全面测试结果

本次测试使用Subagents对6个图腾流派的全部单位进行了并行测试，发现了以下问题：

#### 1. Headless模式类加载问题

**问题描述**: Godot 4.3 headless模式下无法正确解析`class_name`定义的类继承关系，导致SCRIPT ERROR。

**受影响的类**:
- `BaseTotemMechanic` - 所有图腾机制基类
- `DefaultBehavior` - 单位行为基类
- `BuffProviderBehavior` - Buff提供者基类
- `FlyingMeleeBehavior` - 飞行近战单位基类

**为什么之前的测试没有检测出来**:
- 之前的测试主要在GUI模式下运行，类加载正常
- Headless模式的类加载机制与GUI模式不同
- 测试用例没有覆盖所有单位类型，特别是新添加的单位

**修复方案**:
- 移除`class_name`声明，改用字符串路径继承
- 例如：`extends "res://src/Scripts/Units/Behaviors/DefaultBehavior.gd"`

#### 2. 远程攻击单位弹丸系统问题

**问题描述**: 鹰图腾流派的远程攻击单位在Headless模式下无法产生攻击事件。

**受影响的单位**:
- 疾风鹰 (gale_eagle)
- 红隼 (kestrel)
- 猫头鹰 (owl)
- 老鹰 (eagle)
- 秃鹫 (vulture)
- 喜鹊 (magpie)
- 鸽子 (pigeon)
- 啄木鸟 (woodpecker)
- 鹦鹉 (parrot)
- 孔雀 (peacock)
- 风暴鹰 (storm_eagle)

**为什么之前的测试没有检测出来**:
- 只有角雕(harpy_eagle)使用`FlyingMeleeBehavior`直接造成伤害
- 其他单位使用`DefaultBehavior`依赖弹丸系统
- Headless模式下`Area2D`碰撞检测可能无法正常工作
- 测试用例只验证了harpy_eagle，未覆盖其他远程单位

**修复方案**:
- 检查`CombatManager.spawn_projectile()`在Headless模式下的行为
- 考虑为远程攻击添加非弹丸的攻击方式作为备选

#### 3. 单位配置缺失

**问题描述**: game_data.json中缺少部分单位的配置。

**缺失配置的单位**:
- 狼 (wolf) - 只有敌人配置，没有玩家单位配置
- 鬣狗 (hyena) - 完全缺失
- 狐狸 (fox) - 完全缺失

**为什么之前的测试没有检测出来**:
- 这些单位标记为"未实现"，没有创建对应的测试用例
- 测试框架主要关注已标记为"已实现"的单位
- 缺少配置导致单位无法被放置到战场上

#### 4. Autoload类继承问题

**问题描述**: `StyleMaker`和`UIConstants`作为Autoload必须继承`Node`，但代码中继承`RefCounted`或无继承。

**为什么之前的测试没有检测出来**:
- GUI模式下Godot对Autoload的继承检查较宽松
- Headless模式下检查更严格，导致错误
- 测试用例没有覆盖UI类的初始化路径

#### 5. 代码重复定义问题

**问题描述**: `UnitHyena.gd`中有两个`_on_attack_hit`函数定义。

**为什么之前的测试没有检测出来**:
- 该单位未在game_data.json中配置，无法被测试
- 代码审查时未发现重复函数

### 测试覆盖改进建议

1. **必须测试所有单位类型**: 不仅测试标记为"已实现"的单位，还应测试"部分实现"和"未实现"的单位以发现配置问题

2. **Headless模式必须作为标准测试流程**: 所有Jules任务必须在Headless模式下验证通过

3. **主动技能必须测试**: 任何有主动技能的单位必须通过`scheduled_actions`测试技能释放流程

4. **弹丸系统需要专门测试**: 远程攻击单位的弹丸系统需要专门的Headless兼容性测试

5. **配置完整性检查**: 添加自动化检查确保game_data.json中包含所有单位的配置

### 已修复的文件列表

| 文件路径 | 修复内容 |
|---------|---------|
| `src/Scripts/Units/Behaviors/DefaultBehavior.gd` | 移除class_name，使用路径继承 |
| `src/Scripts/Units/Behaviors/BuffProviderBehavior.gd` | 使用路径继承 |
| `src/Scripts/Units/Behaviors/FlyingMeleeBehavior.gd` | 使用路径继承 |
| `src/Scripts/Utils/StyleMaker.gd` | 改为继承Node |
| `src/Scripts/Constants/UIConstants.gd` | 改为继承Node |
| `src/Scripts/Game/Tree.gd` | 添加Headless模式检测 |
| `src/Scripts/Unit.gd` | 添加预加载语句 |
| `src/Scripts/Enemy.gd` | 添加预加载语句 |

---

*本文档包含 Jules API 的使用说明和项目特定的执行流程*
*Jules API 文档: https://developers.google.com/jules/api*
*本文档更新时间: 2026-02-19 (P0-P2 阶段全部完成，添加Bug反馈章节)*
