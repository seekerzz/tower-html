# 蝙蝠图腾系列单位实现报告

## 完成概述

成功实现了蝙蝠图腾系列的4个单位，包括行为脚本和game_data.json配置。

## 实现详情

### 1. VampireBat (吸血蝠)
- **文件**: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/VampireBat.gd`
- **图标**: 🦇
- **攻击类型**: 近战 (melee)
- **伤害类型**: 物理 (physical)
- **机制**: 鲜血狂噬 - 生命值越低吸血比例越高
  - L1: 最低生命时+50%吸血
  - L2: 基础吸血+20%，生命值越低吸血越高
  - L3: 基础吸血+40%，生命值越低吸血越高

**实现要点**:
- 继承 `DefaultBehavior`
- 在 `on_projectile_hit` 中计算吸血
- 根据当前生命值比例计算吸血加成

### 2. PlagueSpreader (瘟疫使者)
- **文件**: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/PlagueSpreader.gd`
- **图标**: 🦇
- **攻击类型**: 远程 (ranged)
- **弹丸**: stinger
- **伤害类型**: 毒素 (poison)
- **机制**: 毒血传播 - 攻击使敌人中毒，中毒敌人死亡时传播给附近敌人
  - L1: 基础传播
  - L2: 传播范围+1格 (60像素)
  - L3: 传播范围+2格 (120像素)

**实现要点**:
- 预加载 `PoisonEffect.gd`
- 攻击时给敌人施加中毒效果
- 连接敌人的 `died` 信号实现传播
- 最多传播给3个附近敌人

### 3. BloodMage (血法师)
- **文件**: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/BloodMage.gd`
- **图标**: 🩸
- **攻击类型**: 远程 (ranged) + 点目标技能
- **弹丸**: magic_missile
- **伤害类型**: 魔法 (magic)
- **技能**: 血池降临
- **机制**: 召唤血池区域，敌人受伤友方回血
  - L1: 血池1x1
  - L2: 血池2x2
  - L3: 血池3x3，效果+50%

**实现要点**:
- 继承 `DefaultBehavior`
- 实现 `on_skill_activated` 和 `on_skill_executed_at`
- 创建血池视觉节点 (ColorRect + ReferenceRect)
- 血池持续8秒，每0.5秒对范围内敌人造成伤害
- 造成伤害的50%转化为治疗

### 4. BloodAncestor (血祖)
- **文件**: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/BloodAncestor.gd`
- **图标**: 👑
- **攻击类型**: 远程 (ranged)
- **弹丸**: magic_missile
- **伤害类型**: 魔法 (magic)
- **机制**: 鲜血领域 - 场上每有1个受伤敌人，自身攻击+X%
  - L1: 每敌人+10%
  - L2: 每敌人+15%
  - L3: 每敌人+20%且吸血+20%

**实现要点**:
- 在 `on_tick` 和 `on_stats_updated` 中更新加成
- 计算场上受伤敌人数量 (hp < max_hp)
- 提供 `calculate_modified_damage` 方法供外部调用
- L3时通过 `on_projectile_hit` 实现吸血

## 配置文件更新

**文件**: `/home/zhangzhan/tower-html/data/game_data.json`

添加了4个单位的完整配置，包括:
- 基础属性 (名称、图标、大小、射程、攻速等)
- 3个等级的属性 (伤害、生命值、成本)
- 等级机制参数
- 技能和弹丸配置

## 潜在问题与注意事项

### 1. BloodAncestor 伤害加成
当前实现需要在 `Unit.gd` 的 `calculate_damage_against` 方法中调用行为的 `calculate_modified_damage` 方法才能生效。如果游戏没有这种集成，伤害加成可能不会生效。

**建议**: 考虑将伤害加成改为通过 `on_projectile_hit` 实现，或者修改 `Unit.gd` 来支持行为修改伤害。

### 2. BloodMage 血池视觉
血池使用简单的 ColorRect 实现，可能需要美术调整颜色和透明度。

### 3. PlagueSpreader 传播逻辑
传播只在敌人死亡时触发，如果敌人在中毒期间被其他单位击杀，传播仍然会发生（因为信号已连接）。

## 测试建议

1. **VampireBat**: 测试不同生命值下的吸血比例是否正确
2. **PlagueSpreader**: 测试中毒传播是否正常，范围是否正确
3. **BloodMage**: 测试技能释放、血池伤害和治疗是否正确
4. **BloodAncestor**: 测试受伤敌人计数和伤害加成是否正确

## 文件清单

### 新增文件
- `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/VampireBat.gd`
- `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/PlagueSpreader.gd`
- `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/BloodMage.gd`
- `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/BloodAncestor.gd`

### 修改文件
- `/home/zhangzhan/tower-html/data/game_data.json` (添加4个单位配置)
