# Jules 任务: P0-01 狼图腾魂魄系统

## 任务ID
P0-01

## 任务描述
实现狼图腾核心机制——魂魄系统。这是所有狼图腾单位的基础系统。

## 实现要求

### 1. 创建 SoulManager (src/Autoload/SoulManager.gd)

```gdscript
class_name SoulManager
extends Node

signal soul_count_changed(new_count: int, delta: int)

var current_souls: int = 0
var max_souls: int = 500

func add_souls_from_enemy_death(enemy_data: Dictionary) -> void:
    current_souls = min(current_souls + 1, max_souls)
    soul_count_changed.emit(current_souls, 1)

func add_souls_from_unit_merge(unit_data: Dictionary) -> void:
    current_souls = min(current_souls + 10, max_souls)
    soul_count_changed.emit(current_souls, 10)

func get_soul_damage_bonus() -> int:
    return current_souls
```

### 2. 创建 MechanicWolfTotem (src/Scripts/CoreMechanics/MechanicWolfTotem.gd)

```gdscript
class_name MechanicWolfTotem
extends BaseTotemMechanic

@export var attack_interval: float = 5.0
@export var base_damage: int = 15

func _ready():
    var timer = Timer.new()
    timer.wait_time = attack_interval
    timer.timeout.connect(_on_totem_attack)
    add_child(timer)
    timer.start()

func _on_totem_attack():
    var targets = get_nearest_enemies(3)
    for enemy in targets:
        var damage = base_damage + SoulManager.get_soul_damage_bonus()
        deal_damage(enemy, damage)
```

### 3. 修改 Enemy.gd

在死亡处理中添加：
```gdscript
func _on_death():
    SoulManager.add_souls_from_enemy_death({
        "type": enemy_type,
        "wave": GameManager.current_wave
    })
```

### 4. 修改 UnitDragHandler.gd

在合并处理中添加：
```gdscript
func _on_units_merged(consumed_unit: Unit):
    SoulManager.add_souls_from_unit_merge({
        "level": consumed_unit.level,
        "type": consumed_unit.unit_id
    })
```

### 5. 添加魂魄计数UI

在核心卡UI中添加：
- 显示格式：🔮 [魂魄数]
- 位置：核心血量/法力值下方
- 魂魄数变化时更新

### 6. 更新 data/game_data.json

添加狼图腾配置：
```json
{
    "totems": [
        {
            "id": "wolf_totem",
            "name": "狼图腾",
            "description": "敌人阵亡获得1魂魄，单位吞噬获得10魂魄。图腾每5秒攻击附带魂魄数伤害",
            "attack_interval": 5.0,
            "base_damage": 15,
            "soul_per_enemy": 1,
            "soul_per_merge": 10
        }
    ]
}
```

## 实现步骤

1. 创建 SoulManager.gd 并配置为 Autoload
2. 创建 MechanicWolfTotem.gd
3. 修改 Enemy.gd 添加死亡事件绑定
4. 修改 UnitDragHandler.gd 添加合并事件绑定
5. 在 CoreCard 添加UI元素
6. 更新 game_data.json
7. 运行测试

## 自动化测试要求

你必须在 src/Scripts/Tests/TestSuite.gd 中创建测试用例：

```gdscript
"test_soul_system":
    return {
        "id": "test_soul_system",
        "core_type": "wolf_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 10.0,
        "units": [
            {"id": "wolf", "x": 0, "y": 1}
        ]
    }
```

运行测试命令：
```bash
godot --path . --headless -- --run-test=test_soul_system
```

验证点：
- 击杀敌人增加1魂魄
- 合并单位增加10魂魄
- 图腾攻击伤害 = 15 + 当前魂魄数
- 魂魄数在波次间保持
- UI正确更新

**测试框架扩展权限：**
如果当前测试框架无法覆盖本任务所需的测试场景（如需要验证魂魄数值变化、跨波次状态保持等），你有权：
1. 修改 `src/Scripts/Tests/AutomatedTestRunner.gd` 以增加新的测试能力
2. 更新 `docs/GameDesign.md` 中的自动化测试框架文档，记录新的测试功能和配置方法
3. 确保新增的测试功能不会破坏现有的其他测试用例

## 进度同步要求

完成每个重要步骤后，立即更新 docs/progress.md：

找到任务ID为 "P0-01" 的行并更新：
- 状态：in_progress | completed | failed
- 描述：当前进度的简短描述
- 更新时间：当前ISO格式时间

示例格式：
```markdown
| P0-01 | in_progress | 创建了SoulManager | 2026-02-19T14:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P0-01-soul-system`
2. 提交信息格式：`[P0-01] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是一个独立任务，不要等待其他任务
- 不要假设其他系统已存在
- 只专注于魂魄系统的实现
- 所有功能必须可以独立测试
