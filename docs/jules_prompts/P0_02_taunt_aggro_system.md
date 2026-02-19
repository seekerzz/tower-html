# Jules 任务: P0-02 嘲讽和仇恨系统

## 任务ID
P0-02

## 任务描述
实现嘲讽和仇恨系统，用于控制敌人的目标选择行为。

## 实现要求

### 1. 创建 AggroManager (src/Scripts/Managers/AggroManager.gd)

```gdscript
class_name AggroManager
extends Node

var enemy_targets: Dictionary = {}
var taunting_units: Array[Unit] = []

signal target_changed(enemy: Enemy, new_target: Unit)
signal taunt_started(unit: Unit, radius: float)
signal taunt_ended(unit: Unit)

func register_enemy(enemy: Enemy):
    pass

func apply_taunt(unit: Unit, radius: float, duration: float):
    taunting_units.append(unit)
    _update_targets_in_radius(unit.global_position, radius)
    taunt_started.emit(unit, radius)

    if duration > 0:
        await get_tree().create_timer(duration).timeout
        remove_taunt(unit)

func remove_taunt(unit: Unit):
    taunting_units.erase(unit)
    taunt_ended.emit(unit)

func get_target_for_enemy(enemy: Enemy) -> Unit:
    # 优先嘲讽单位
    for unit in taunting_units:
        if enemy.global_position.distance_to(unit.global_position) <= 150:
            return unit
    return null
```

### 2. 创建 TauntBehavior (src/Scripts/Units/Behaviors/TauntBehavior.gd)

```gdscript
class_name TauntBehavior
extends UnitBehavior

@export var taunt_radius: float = 120.0
@export var taunt_interval: float = 6.0
@export var taunt_duration: float = 2.5

func _ready():
    var timer = Timer.new()
    timer.wait_time = taunt_interval
    timer.timeout.connect(_trigger_taunt)
    add_child(timer)
    timer.start()

func _trigger_taunt():
    AggroManager.apply_taunt(unit, taunt_radius, taunt_duration)
    _play_taunt_effect()

func _play_taunt_effect():
    # 嘲讽视觉效果
    pass
```

### 3. 修改 Enemy.gd

更新目标选择逻辑：
```gdscript
func find_attack_target() -> Unit:
    # 首先检查嘲讽单位
    var target = AggroManager.get_target_for_enemy(self)
    if target:
        return target
    # 默认攻击核心
    return null
```

### 4. 添加视觉反馈

- 嘲讽范围指示器：红色/橙色圆形
- 敌人仇恨标记：敌人头顶显示"!"图标
- 单位嘲讽状态特效

## 实现步骤

1. 创建 AggroManager.gd
2. 创建 TauntBehavior.gd
3. 修改 Enemy.gd 目标选择逻辑
4. 添加嘲讽范围可视化
5. 添加仇恨标记
6. 更新 game_data.json（如需要）
7. 运行测试

## 自动化测试要求

在 src/Scripts/Tests/TestSuite.gd 中创建测试用例：

```gdscript
"test_taunt_system":
    return {
        "id": "test_taunt_system",
        "core_type": "cow_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 15.0,
        "units": [
            {"id": "yak_guardian", "x": 0, "y": 0}
        ]
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_taunt_system
```

验证点：
- 嘲讽每6秒触发一次
- 范围内敌人攻击嘲讽单位
- 嘲讽2.5秒后结束
- 视觉反馈正确显示

## 进度同步要求

完成每个步骤后，更新 docs/progress.md 中任务 P0-02 的行：

```markdown
| P0-02 | in_progress | 创建AggroManager | 2026-02-19T14:30:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P0-02-aggro-system`
2. 提交信息格式：`[P0-02] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是一个独立任务
- 不依赖其他P0任务
- 只专注于嘲讽/仇恨机制
- 可以用牦牛守护单位测试（如果已存在）
