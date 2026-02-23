# Jules 任务: P0-03 召唤物系统

## 任务ID
P0-03

## 任务描述
实现召唤物系统，用于临时单位（如小蜘蛛、克隆体）。

## 实现要求

### 1. 创建 SummonedUnit 基类 (src/Scripts/Units/SummonedUnit.gd)

```gdscript
class_name SummonedUnit
extends Unit

@export var lifetime: float = 25.0
@export var is_clone: bool = false
@export var summon_source: Unit = null

var lifetime_timer: Timer

signal summon_expired(summon: SummonedUnit)
signal summon_killed(summon: SummonedUnit)

func _ready():
    super._ready()
    is_summoned = true

    # 视觉区分
    modulate = Color(1, 1, 1, 0.7)

    if lifetime > 0:
        lifetime_timer = Timer.new()
        lifetime_timer.wait_time = lifetime
        lifetime_timer.timeout.connect(_on_lifetime_expired)
        lifetime_timer.one_shot = true
        add_child(lifetime_timer)
        lifetime_timer.start()

func _on_lifetime_expired():
    summon_expired.emit(self)
    queue_free()
```

### 2. 创建 SummonManager (src/Scripts/Managers/SummonManager.gd)

```gdscript
class_name SummonManager
extends Node

var active_summons: Array[SummonedUnit] = []
var max_summons_per_source: int = 8

signal summon_created(summon: SummonedUnit, source: Unit)
signal summon_destroyed(summon: SummonedUnit)

func create_summon(data: Dictionary) -> SummonedUnit:
    var summon_scene = preload("res://src/Scenes/Units/SummonedUnit.tscn")
    var summon = summon_scene.instantiate()

    summon.unit_id = data.get("unit_id", "summon_generic")
    summon.level = data.get("level", 1)
    summon.lifetime = data.get("lifetime", 25.0)
    summon.is_clone = data.get("is_clone", false)
    summon.summon_source = data.get("source")
    summon.global_position = data.get("position", Vector2.ZERO)

    # 如果是克隆体，继承属性
    if summon.is_clone and summon.summon_source:
        _inherit_stats(summon, summon.summon_source, data.get("inherit_ratio", 0.4))

    get_tree().current_scene.add_child(summon)
    active_summons.append(summon)

    summon.summon_expired.connect(_on_summon_removed.bind(summon))
    summon_killed.connect(_on_summon_removed.bind(summon))

    summon_created.emit(summon, summon.summon_source)
    return summon

func _inherit_stats(summon: SummonedUnit, source: Unit, ratio: float):
    summon.base_damage = source.base_damage * ratio
    summon.max_hp = source.max_hp * ratio
    summon.current_hp = summon.max_hp
    summon.attack_speed = source.attack_speed
```

### 3. 创建 SummonedUnit 场景

创建 src/Scenes/Units/SummonedUnit.tscn：
- 根节点：SummonedUnit（附加脚本）
- 视觉：半透明（alpha 0.7）
- 可选：克隆体的描边着色器

### 4. 更新 game_data.json

添加召唤物配置：
```json
{
    "units": [
        {
            "id": "spiderling",
            "name": "小蜘蛛",
            "type": "summoned",
            "base_damage": 8,
            "attack_speed": 1.5,
            "attack_range": 80,
            "max_hp": 30,
            "lifetime": 25
        },
        {
            "id": "enemy_clone",
            "name": "克隆体",
            "type": "summoned_clone",
            "inherit_stats": ["damage", "attack_speed", "range"],
            "lifetime": -1
        }
    ]
}
```

## 实现步骤

1. 创建 SummonedUnit.gd 基类
2. 创建 SummonManager.gd
3. 创建 SummonedUnit.tscn 场景
4. 添加视觉效果（半透明、描边）
5. 更新 game_data.json
6. 运行测试

## 自动化测试要求

在 src/Scripts/Tests/TestSuite.gd 中创建测试用例：

```gdscript
"test_summon_system":
    return {
        "id": "test_summon_system",
        "core_type": "viper_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 30.0,
        "units": [],
        "scheduled_actions": [
            {
                "time": 1.0,
                "type": "summon_test",
                "summon_type": "spiderling",
                "position": {"x": 0, "y": 1}
            }
        ]
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_summon_system
```

验证点：
- 召唤物有正确的生命周期
- 召唤物自动过期消失
- 克隆体继承正确的属性
- 视觉区分明显
- 每个来源的最大召唤数限制生效

**测试框架扩展权限：**
如果当前测试框架无法覆盖本任务所需的测试场景（如需要验证召唤物生命周期、克隆体属性继承、多个召唤物同时存在等），你有权：
1. 修改 `src/Scripts/Tests/AutomatedTestRunner.gd` 以增加新的测试能力
2. 更新 `docs/GameDesign.md` 中的自动化测试框架文档，记录新的测试功能和配置方法
3. 确保新增的测试功能不会破坏现有的其他测试用例

## 进度同步要求

完成每个步骤后，更新 docs/progress.md 中任务 P0-03 的行：

```markdown
| P0-03 | in_progress | 创建SummonedUnit类 | 2026-02-19T15:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P0-03-summon-system`
2. 提交信息格式：`[P0-03] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是一个独立任务，不依赖其他P0任务
- 召唤物不增加核心血量（与普通单位不同）
- 专注于系统架构，具体单位后续实现
