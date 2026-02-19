# Jules 任务: P2-01 商店图腾阵营刷新机制

## 任务ID
P2-01

## 任务描述
重构商店刷新机制，使商店只会刷出玩家选择的图腾阵营对应的单位，外加通用单位。

## 当前代码位置

- 商店逻辑: `src/Scripts/UI/Shop.gd` (第152-166行的 `refresh_shop` 函数)
- 单位数据: `data/game_data.json` 中的 `UNIT_TYPES`
- 图腾类型: `data/game_data.json` 中的 `CORE_TYPES`

## 实现要求

### 1. 为单位添加阵营字段

更新 `data/game_data.json` 中的 `UNIT_TYPES`，为每个单位添加 `faction` 字段：

```json
{
    "UNIT_TYPES": {
        "tiger": {
            "name": "猛虎",
            "faction": "wolf_totem",
            "icon": "🐯",
            ...
        },
        "rat": {
            "name": "老鼠",
            "faction": "viper_totem",
            "icon": "🐭",
            ...
        },
        "mosquito": {
            "name": "蚊子",
            "faction": "bat_totem",
            "icon": "🦟",
            ...
        },
        "moth": {
            "name": "光蛾",
            "faction": "butterfly_totem",
            "icon": "🦋",
            ...
        },
        "kestrel": {
            "name": "红隼",
            "faction": "eagle_totem",
            "icon": "🦅",
            ...
        },
        "cow": {
            "name": "战牛",
            "faction": "cow_totem",
            "icon": "🐮",
            ...
        },
        "meat": {
            "name": "肉块",
            "faction": "universal",
            "icon": "🥩",
            ...
        }
    }
}
```

阵营映射关系：
- `wolf_totem`: 狼图腾单位 (tiger, dog, wolf, hyena, fox, sheep_spirit, lion, blood_food)
- `viper_totem`: 毒蛇图腾单位 (scorpion, medusa, basilisk, cobra, python, rat, toad)
- `bat_totem`: 蝙蝠图腾单位 (mosquito, blood_mage, vampire_bat, gargoyle, life_chain, blood_chalice, blood_ritualist)
- `butterfly_totem`: 蝴蝶图腾单位 (phoenix, ice_moth, firefly, sprite)
- `eagle_totem`: 鹰图腾单位 (kestrel, owl, magpie, pigeon)
- `cow_totem`: 牛图腾单位 (cow, yak_guardian, iron_turtle, hedgehog, rock_armor_cow, mushroom_healer, oxpecker, plant, ascetic)
- `universal`: 通用单位 (meat, spiderling, enemy_clone 等)

### 2. 修改商店刷新逻辑

修改 `src/Scripts/UI/Shop.gd` 中的 `refresh_shop` 函数：

```gdscript
func refresh_shop(force: bool = false):
    if !force and GameManager.gold < 10: return
    if !force:
        GameManager.spend_gold(10)

    # 获取当前玩家选择的图腾
    var player_faction = GameManager.core_type

    # 获取可用单位池
    var available_units = _get_units_for_faction(player_faction)

    var new_items = []

    for i in range(SHOP_SIZE):
        if !force and shop_items.size() > i and shop_locked[i]:
            new_items.append(shop_items[i])
        else:
            new_items.append(available_units.pick_random())

    shop_items = new_items

    for child in shop_container.get_children():
        child.queue_free()

    for i in range(SHOP_SIZE):
        create_shop_card(i, shop_items[i])

# 新增：获取指定阵营的单位列表
func _get_units_for_faction(faction: String) -> Array:
    var result = []

    for unit_key in Constants.UNIT_TYPES.keys():
        var unit_data = Constants.UNIT_TYPES[unit_key]
        var unit_faction = unit_data.get("faction", "universal")

        # 只包含指定阵营或通用阵营的单位
        if unit_faction == faction or unit_faction == "universal":
            result.append(unit_key)

    # 如果没有找到任何单位（容错处理），返回所有单位
    if result.is_empty():
        push_warning("No units found for faction: %s, falling back to all units" % faction)
        return Constants.UNIT_TYPES.keys()

    return result
```

### 3. 确保 DataManager 加载 faction 字段

检查 `src/Scripts/Managers/DataManager.gd` 的 `_parse_unit_types` 函数，确保 `faction` 字段被正确加载（应该自动加载，因为所有字段都会被复制到 entry）。

### 4. 添加默认图腾处理

在 `src/Scripts/UI/Shop.gd` 中添加容错处理：

```gdscript
func _ready():
    GameManager.resource_changed.connect(update_ui)
    GameManager.wave_started.connect(on_wave_started)
    GameManager.wave_ended.connect(on_wave_ended)
    if GameManager.has_signal("wave_reset"):
        GameManager.wave_reset.connect(on_wave_reset)

    # 等待 GameManager 初始化完成
    if GameManager.core_type.is_empty():
        # 如果没有选择图腾，等待核心类型被设置
        await GameManager.core_type_changed

    refresh_shop(true)
    update_ui()
    ...
```

### 5. 波次结束刷新时保持阵营一致性

确保波次结束后刷新的商店仍然遵循阵营限制：

```gdscript
func on_wave_ended():
    refresh_btn.disabled = false
    expand_btn.disabled = false
    start_wave_btn.disabled = false
    # 波次结束自动刷新商店，使用当前阵营
    refresh_shop(true)
    expand_shop()
```

## 实现步骤

1. 更新 `data/game_data.json`，为所有 `UNIT_TYPES` 添加 `faction` 字段
2. 修改 `src/Scripts/UI/Shop.gd` 的 `refresh_shop` 函数
3. 添加 `_get_units_for_faction` 辅助函数
4. 测试商店刷新逻辑

## 自动化测试要求

在 `src/Scripts/Tests/TestSuite.gd` 中添加测试用例：

```gdscript
"test_shop_faction_refresh":
    return {
        "id": "test_shop_faction_refresh",
        "core_type": "wolf_totem",
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 5.0,
        "test_shop": true,
        "validate_shop_faction": "wolf_totem"
    }
```

运行测试：
```bash
godot --path . --headless -- --run-test=test_shop_faction_refresh
```

验证点：
- 狼图腾核心时，商店只出现狼图腾单位和通用单位
- 商店刷新4个商品都符合阵营要求
- 波次结束后自动刷新仍遵循阵营限制

**测试框架扩展权限：**
如果当前测试框架无法覆盖本任务所需的测试场景，你有权：
1. 修改 `src/Scripts/Tests/AutomatedTestRunner.gd` 以支持商店阵营验证
2. 更新 `docs/GameDesign.md` 中的自动化测试框架文档，记录新的测试功能

## 进度同步要求

更新 `docs/progress.md` 中任务 P2-01 的行：

```markdown
| P2-01 | completed | 商店改为按图腾阵营刷新单位 | 2026-02-19T12:00:00 |
```

## 代码提交要求

1. 在独立分支上工作：`feature/P2-01-shop-faction-refresh`
2. 提交信息格式：`[P2-01] 简要描述`
3. 完成后创建 Pull Request 到 main 分支

## 注意事项

- 这是单任务实现，只关注商店刷新机制
- 不要修改其他游戏机制
- 确保通用单位（如meat）在所有阵营都能出现
- 考虑向后兼容：如果没有faction字段的单位，默认视为通用单位

---

## 任务标识

Task being executed: P2-01
