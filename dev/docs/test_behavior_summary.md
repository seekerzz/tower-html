# 各单位测试行为总结

本文档总结每个测试用例对单位执行的具体操作行为。

---

## 一、系统机制测试

| 测试ID | 放置单位 | 特殊操作 | 测试目的 |
|-------|---------|---------|---------|
| `test_soul_system` | 1个松鼠 | 无 | 测试狼图腾魂魄系统 |
| `test_cow_squirrel` | 1个松鼠 | 无 | 测试牛图腾核心下的松鼠 |
| `test_bleed_lifesteal` | 4个蚊子（十字布局） | 无 | 测试流血和吸血机制 |
| `test_taunt_system` | 1个牦牛守护 | 无 | 测试嘲讽系统 |
| `test_summon_system` | 无 | **第1秒召唤蜘蛛幼体** | 测试召唤物系统 |
| `test_shop_faction_refresh` | 无 | 验证商店单位阵营 | 测试商店阵营刷新 |
| `test_enemy_death_no_duplicate` | 1个猛虎 | **第2秒执行死亡测试** | 测试敌人死亡不重复触发 |
| `test_bleed_lifesteal_system` | 蚊子 + 血法师 | 无 | 测试流血吸血联动 |

---

## 二、主动技能测试

| 测试ID | 放置单位 | 技能释放操作 |
|-------|---------|-------------|
| `test_butterfly_phoenix` | 1个凤凰 | **第5秒释放技能**到目标位置(-2, -2) |
| `test_bat_totem_blood_mage` | 1个血法师 | **第5秒释放技能**到目标位置(2, 2) |
| `test_bat_totem_blood_mage_skill` | 1个血法师 | **第3秒和第12秒分别释放技能**到不同目标位置 |

---

## 三、Setup Actions测试（初始化操作）

| 测试ID | 放置单位 | Setup操作 | 说明 |
|-------|---------|----------|------|
| `test_viper_strategy` | 松鼠 + 毒蛇 | 1. **随机生成毒陷阱**<br>2. **给松鼠施加毒buff** | 测试毒蛇策略玩法 |

---

## 四、P2新系统测试

| 测试ID | 放置单位 | 测试行为 |
|-------|---------|---------|
| `test_charm_system` | 狐狸 + 牦牛守护 | **等待敌人攻击狐狸**，触发魅惑效果 |
| `test_wolf_devour_system` | 狼 + 猛虎 | **狼吞噬猛虎**，测试继承机制 |
| `test_medusa_petrify` | 1个美杜莎 | **等待美杜莎石化敌人**，测试石块生成 |

---

## 五、单单位基础测试（仅放置）

以下测试仅放置单个单位，观察其基础攻击和行为：

### 牛图腾流派（8个单位）
| 测试ID | 放置单位 |
|-------|---------|
| `test_cow_totem_plant` | 树苗 |
| `test_cow_totem_iron_turtle` | 铁甲龟 |
| `test_cow_totem_hedgehog` | 刺猬 |
| `test_cow_totem_yak_guardian` | 牦牛守护 |
| `test_cow_totem_cow_golem` | 牛魔像 |
| `test_cow_totem_rock_armor_cow` | 岩甲牛 |
| `test_cow_totem_mushroom_healer` | 菌菇治愈者 |
| `test_cow_totem_cow` | 奶牛 |

### 蝙蝠图腾流派（5个单位）
| 测试ID | 放置单位 |
|-------|---------|
| `test_bat_totem_mosquito` | 蚊子 |
| `test_bat_totem_vampire_bat` | 吸血蝠 |
| `test_bat_totem_plague_spreader` | 瘟疫使者 |
| `test_bat_totem_blood_ancestor` | 血祖 |

### 蝴蝶图腾流派（6个单位）
| 测试ID | 放置单位 | 备注 |
|-------|---------|------|
| `test_butterfly_totem_torch` | 红莲火炬 + 松鼠 | 配合友方单位测试 |
| `test_butterfly_totem_butterfly` | 蝴蝶 |
| `test_butterfly_totem_fairy_dragon` | 仙女龙 |
| `test_butterfly_totem_phoenix` | 凤凰 |
| `test_butterfly_totem_eel` | 电鳗 |
| `test_butterfly_totem_dragon` | 龙 |

### 狼图腾流派（4个单位）
| 测试ID | 放置单位 |
|-------|---------|
| `test_wolf_totem_tiger` | 猛虎 |
| `test_wolf_totem_dog` | 恶霸犬 |
| `test_wolf_totem_lion` | 狮子 |

### 眼镜蛇图腾流派（7个单位）
| 测试ID | 放置单位 |
|-------|---------|
| `test_viper_totem_spider` | 蜘蛛 |
| `test_viper_totem_snowman` | 雪人 |
| `test_viper_totem_scorpion` | 蝎子 |
| `test_viper_totem_viper` | 毒蛇 |
| `test_viper_totem_arrow_frog` | 箭毒蛙 |
| `test_viper_totem_medusa` | 美杜莎 |
| `test_viper_totem_lure_snake` | 诱饵蛇 |

### 鹰图腾流派（12个单位）
| 测试ID | 放置单位 |
|-------|---------|
| `test_eagle_kestrel` | 红隼 |
| `test_eagle_owl` | 猫头鹰 + 红隼（2单位） |
| `test_eagle_magpie` | 喜鹊 |
| `test_eagle_pigeon` | 鸽子 |
| `test_eagle_totem_harpy_eagle` | 角雕 |
| `test_eagle_totem_gale_eagle` | 疾风鹰 |
| `test_eagle_totem_kestrel` | 红隼 |
| `test_eagle_totem_owl` | 猫头鹰 |
| `test_eagle_totem_eagle` | 老鹰 |
| `test_eagle_totem_vulture` | 秃鹫 |
| `test_eagle_totem_magpie` | 喜鹊 |
| `test_eagle_totem_pigeon` | 鸽子 |
| `test_eagle_totem_woodpecker` | 啄木鸟 |
| `test_eagle_totem_parrot` | 鹦鹉 |
| `test_eagle_totem_peacock` | 孔雀 |
| `test_eagle_totem_storm_eagle` | 风暴鹰 |

---

## 六、测试行为分类汇总

### 1. 仅放置观察（基础测试）
约**50+个测试**仅执行：放置单位 → 等待15秒 → 观察行为

### 2. 主动技能释放测试
- 凤凰：定时技能
- 血法师：定时技能（单发或双发）

### 3. 初始化操作测试
- 毒蛇策略：放置陷阱 + 施加buff

### 4. 召唤测试
- 召唤系统：定时召唤蜘蛛幼体

### 5. 系统交互测试
- 魅惑：等待敌人攻击触发
- 吞噬：双单位放置，触发吞噬
- 石化：等待技能触发
- 死亡：主动执行死亡测试

### 6. 商店验证测试
- 商店阵营：无单位，仅验证商店商品

---

## 七、关键测试操作详解

### 技能释放操作
```gdscript
# 定时在指定时间对指定目标释放技能
"scheduled_actions": [
    {
        "time": 5.0,              // 第5秒执行
        "type": "skill",
        "source": "phoenix",      // 凤凰释放
        "target": {"x": -2, "y": -2}  // 目标位置
    }
]
```

### 召唤操作
```gdscript
# 第1秒在指定位置召唤蜘蛛幼体
"scheduled_actions": [
    {
        "time": 1.0,
        "type": "summon_test",
        "summon_type": "spiderling",
        "position": {"x": 0, "y": 1}
    }
]
```

### Setup操作
```gdscript
# 测试开始时执行
"setup_actions": [
    {"type": "spawn_trap", "trap_id": "poison_trap", "strategy": "random_valid"},
    {"type": "apply_buff", "buff_id": "poison", "target_unit_id": "squirrel"}
]
```

### 特殊测试操作
```gdscript
# 敌人死亡重复调用测试
"scheduled_actions": [
    {"time": 2.0, "type": "test_enemy_death"}
]

// 商店阵营验证
"validate_shop_faction": "wolf_totem"
```
