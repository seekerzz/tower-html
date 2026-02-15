# 鹰图腾系列单位实现报告

## 完成概述

成功实现了鹰图腾系列的4个单位，包括行为脚本和game_data.json配置。

## 实现单位详情

### 1. Storm Eagle (风暴鹰) - StormEagle.gd
- **图标**: ⚡
- **攻击类型**: 远程 (lightning)
- **机制**: 雷暴召唤
  - 监听全局暴击事件 (`projectile_crit` 信号)
  - 友方单位暴击时积累电荷
  - L1: 5层触发全场雷击
  - L2: 4层触发全场雷击
  - L3: 3层触发全场雷击，雷击可暴击
- **实现要点**:
  - 在 `on_setup()` 中连接到 GameManager 的暴击信号
  - 使用 `CombatManager.perform_lightning_attack()` 或自定义闪电效果
  - 在 `on_cleanup()` 中断开信号连接

### 2. Gale Eagle (疾风鹰) - GaleEagle.gd
- **图标**: 💨
- **攻击类型**: 远程 (feather)
- **机制**: 风刃连击
  - 每次攻击发射多道风刃
  - L1: 2道，每道60%伤害
  - L2: 3道，每道70%伤害
  - L3: 4道，每道80%伤害
- **实现要点**:
  - 覆盖 `on_combat_tick()` 实现自定义攻击
  - 使用 `spread_angle` 控制风刃散射角度
  - 通过 `spawn_projectile()` 创建多个弹丸

### 3. Harpy Eagle (角雕) - HarpyEagle.gd
- **图标**: 🦅
- **攻击类型**: 近战
- **机制**: 三连爪击
  - 快速进行3次爪击
  - L1: 每次60%伤害
  - L2: 每次70%伤害
  - L3: 每次80%且第三次附带流血
- **实现要点**:
  - 继承 `FlyingMeleeBehavior` 实现飞行近战效果
  - 重写攻击序列以支持三连击
  - 第三次攻击时施加 `BleedEffect`
  - 每次爪击显示序号提示 (CLAW 1/2/3)

### 4. Vulture (秃鹫) - Vulture.gd
- **图标**: 🦅
- **攻击类型**: 近战
- **机制**: 腐食增益
  - 周围有敌人死亡时获得攻击加成
  - L1: 攻击+5%
  - L2: 攻击+10%
  - L3: 攻击+10%且吸血+20%
- **实现要点**:
  - 继承 `FlyingMeleeBehavior`
  - 在 `on_tick()` 中检测范围内的敌人
  - 连接敌人的 `died` 信号来触发增益
  - 支持最多5层叠加，持续5秒
  - L3时显示吸血效果

## 文件清单

### 新增行为脚本
1. `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/StormEagle.gd`
2. `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/GaleEagle.gd`
3. `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/HarpyEagle.gd`
4. `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/Vulture.gd`

### 修改的配置文件
- `/home/zhangzhan/tower-html/data/game_data.json`
  - 在 `UNIT_TYPES` 中添加了4个新单位的完整配置

### 修改的核心文件（添加暴击信号支持）
- `/home/zhangzhan/tower-html/src/Autoload/GameManager.gd`
  - 添加了 `projectile_crit` 信号
- `/home/zhangzhan/tower-html/src/Scripts/Projectile.gd`
  - 在暴击时触发 `projectile_crit` 信号

## 技术实现细节

### 暴击监听机制 (Storm Eagle)
```gdscript
# 需要GameManager添加信号
signal projectile_crit(source_unit, target, damage)

# 在Projectile.gd中触发
if is_critical:
    if GameManager.has_signal("projectile_crit"):
        GameManager.projectile_crit.emit(source_unit, target, damage)
```

### 多段攻击实现 (Harpy Eagle)
- 使用状态机管理攻击阶段 (WINDUP -> ATTACK_OUT -> IMPACT -> RETURN)
- 通过 `_current_claw` 计数器追踪当前爪击次数
- 每次攻击后检查是否完成所有段数

### 敌人死亡监听 (Vulture)
- 定期检查范围内的敌人并连接 `died` 信号
- 使用 `_buff_timer` 管理BUFF持续时间
- 支持多层叠加，最多5层

## 潜在问题与注意事项

### 1. Storm Eagle 的全局信号 (已解决)
- ✅ 已在 GameManager 中添加 `projectile_crit` 信号
- ✅ 已在 Projectile.gd 中触发该信号
- 信号参数: `(source_unit, target, damage)`

### 2. 闪电效果
- 使用了现有的 `LightningArc.tscn` 场景
- 伤害计算基于单位攻击力的2倍

### 3. 流血效果
- Harpy Eagle L3 使用现有的 `BleedEffect.gd`
- 流血持续5秒

### 4. Vulture 的性能
- 每帧检查敌人并连接信号可能有性能开销
- 考虑优化为只在敌人进入范围时连接信号

## 测试建议

1. **Storm Eagle**: 搭配高暴击率单位（如Bee）测试电荷积累
2. **Gale Eagle**: 验证风刃数量和伤害比例
3. **Harpy Eagle**: 检查三连击节奏和流血效果
4. **Vulture**: 测试敌人死亡时的增益触发和持续时间

## 后续优化方向

1. 为 Storm Eagle 添加更明显的雷暴视觉特效
2. 为 Gale Eagle 的风刃添加独特的视觉效果
3. 优化 Vulture 的敌人检测性能
4. 添加单位特有的音效
