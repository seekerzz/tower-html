# Jules 任务: P0-04 流血和吸血系统

## 任务ID
P0-04

## 任务描述
实现蝙蝠图腾核心机制——流血Debuff和吸血回复系统。

## 实现要求

### 1. 在 Enemy.gd 中添加流血系统

```gdscript
# 添加到 Enemy 类
var bleed_stacks: int = 0
var max_bleed_stacks: int = 30
var bleed_damage_per_stack: float = 3.0

signal bleed_stack_changed(new_stacks: int)

func add_bleed_stacks(stacks: int):
    var old_stacks = bleed_stacks
    bleed_stacks = min(bleed_stacks + stacks, max_bleed_stacks)
    if bleed_stacks != old_stacks:
        bleed_stack_changed.emit(bleed_stacks)

func _process_bleed_damage(delta: float):
    if bleed_stacks > 0:
        var damage = bleed_stacks * bleed_damage_per_stack * delta
        take_damage(damage, null, "bleed")
```

### 2. 创建 LifestealManager (src/Scripts/Managers/LifestealManager.gd)

```gdscript
class_name LifestealManager
extends Node

@export var lifesteal_ratio: float = 0.4

func _ready():
    # 连接伤害事件信号
    EventBus.damage_dealt.connect(_on_damage_dealt)

func _on_damage_dealt(source: Node, target: Enemy, damage: float):
    if target.bleed_stacks <= 0:
        return
    if not _is_bat_totem_unit(source):
        return

    var lifesteal_amount = target.bleed_stacks * 1.5 * lifesteal_ratio
    lifesteal_amount = min(lifesteal_amount, GameManager.max_core_health * 0.05)

    GameManager.heal_core(lifesteal_amount)
    _show_lifesteal_effect(target.global_position, lifesteal_amount)

func _is_bat_totem_unit(source: Node) -> bool:
    if source is Unit:
        return source.unit_id in ["mosquito", "blood_mage", "vampire_bat"]
    return false

func _show_lifesteal_effect(pos: Vector2, amount: float):
    # 绿色浮动文字
    FloatingTextManager.show_text(pos, "+" + str(int(amount)), Color.GREEN, "heal")
```

### 3. 更新 MechanicBatTotem.gd

```gdscript
class_name MechanicBatTotem
extends BaseTotemMechanic

@export var attack_interval: float = 5.0
@export var target_count: int = 3
@export var bleed_stacks_per_hit: int = 1

func _ready():
    super._ready()
    var timer = Timer.new()
    timer.wait_time = attack_interval
    timer.timeout.connect(_on_totem_attack)
    add_child(timer)
    timer.start()

func _on_totem_attack():
    var targets = get_nearest_enemies(target_count)
    for enemy in targets:
        enemy.add_bleed_stacks(bleed_stacks_per_hit)
        _play_bat_attack_effect(enemy)
```

### 4. 添加流血层数UI

在敌人视觉表现上添加：
- 敌人头顶显示流血层数指示器
- 红色/暗红色配色方案
- 在 bleed_stack_changed 信号时更新

### 5. 更新 game_data.json

```json
{
    "totems": [
        {
            "id": "bat_totem",
            "name": "蝙蝠图腾",
            "description": "每5秒攻击3个最近敌人施加流血。攻击流血敌人按层数回复核心生命",
            "attack_interval": 5.0,
            "bleed_stacks": 1,
            "lifesteal_ratio": 0.4
        }
    ]
}
```

## 实现步骤

1. 在 Enemy.gd 中添加流血系统
2. 创建 LifestealManager.gd
3. 更新/创建 MechanicBatTotem.gd
4. 添加流血层数UI指示器
5. 更新 game_data.json
6. 运行测试

## 自动化测试要求

在 src/Scripts/Tests/TestSuite.gd 中创建测试用例：

```gdscript
"test_bleed_lifesteal":
    return {
        "id": "test_bleed_lifesteal",
        "core_type": "bat_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [
            {"id": "mosquito", "x": 0, "y": 1}
        ]
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_bleed_lifesteal
```

验证点：
- 图腾攻击时施加流血层数
- 流血随时间造成伤害
- 攻击流血敌人回复核心生命
- 吸血有每秒5%最大生命上限
- 流血UI显示正确的层数

**测试框架扩展权限：**
如果当前测试框架无法覆盖本任务所需的测试场景（如需要验证流血层数堆叠、吸血数值计算、持续伤害跳字、吸血上限限制等），你有权：
1. 修改 `src/Scripts/Tests/AutomatedTestRunner.gd` 以增加新的测试能力
2. 更新 `docs/GameDesign.md` 中的自动化测试框架文档，记录新的测试功能和配置方法
3. 确保新增的测试功能不会破坏现有的其他测试用例

## 进度同步要求

更新 docs/progress.md 中任务 P0-04 的行：

```markdown
| P0-04 | in_progress | 在Enemy类添加流血 | 2026-02-19T15:30:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P0-04-lifesteal-system`
2. 提交信息格式：`[P0-04] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是一个独立任务
- 不依赖其他P0任务
- 专注于流血机制和吸血计算
- 限制吸血上限防止无限回复
