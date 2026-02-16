# 蝙蝠图腾系列严格测试报告

## 测试时间
2026-02-16T14:18:03

## 测试结果汇总

### 吸血蝠 (VampireBat)

| 测试项 | 结果 | 详情 |
|--------|------|------|
| vampire_bat_placement | PASS | Placed at (0,0) |
| vampire_bat_lifesteal_L1 Full HP | PASS | Lifesteal calculation correct: 0.0% |
| vampire_bat_lifesteal_L1 50% HP | PASS | Lifesteal calculation correct: 25.0% |
| vampire_bat_lifesteal_L1 25% HP | PASS | Lifesteal calculation correct: 37.5% |
| vampire_bat_lifesteal_L1 10% HP | PASS | Lifesteal calculation correct: 45.0% |
| vampire_bat_lifesteal_L2 Full HP (base 20%) | PASS | Lifesteal calculation correct: 20.0% |
| vampire_bat_lifesteal_L2 10% HP | PASS | Lifesteal calculation correct: 65.0% |
| vampire_bat_lifesteal_L3 Full HP (base 40%) | PASS | Lifesteal calculation correct: 40.0% |
| vampire_bat_lifesteal_L3 10% HP | PASS | Lifesteal calculation correct: 85.0% |
| vampire_bat_combat_lifesteal | PASS | Combat lifesteal: 100.0 damage -> 65.0 heal (65.0%) |

### 瘟疫使者 (PlagueSpreader)

| 测试项 | 结果 | 详情 |
|--------|------|------|
| plague_spreader_placement | PASS | Placed at (0,0) |

### 血法师 (BloodMage)

| 测试项 | 结果 | 详情 |
|--------|------|------|
| blood_mage_placement | PASS | Placed at (0,0) |
| blood_mage_skill_config | PASS | Skill = blood_pool |
| blood_mage_skill_type | PASS | SkillType = point |
| blood_mage_heal_efficiency_L1 | PASS | L1 heal efficiency = 1.0 |
| blood_mage_heal_efficiency_L3 | PASS | L3 heal efficiency = 1.5 (50% bonus) |

### 血祖 (BloodAncestor)

| 测试项 | 结果 | 详情 |
|--------|------|------|
| blood_ancestor_placement | PASS | Placed at (0,0) |
| blood_ancestor_damage_bonus_L1 | PASS | L1 damage bonus per enemy = 10% |
| blood_ancestor_damage_bonus_L2 | PASS | L2 damage bonus per enemy = 15% |
| blood_ancestor_damage_bonus_L3 | PASS | L3 damage bonus per enemy = 20% |
| blood_ancestor_lifesteal_L3 | PASS | L3 lifesteal bonus = 20% |
| blood_ancestor_calculate_damage | PASS | Has calculate_modified_damage method |
| blood_ancestor_damage_calculation | PASS | Damage calculation correct: 100.0 -> 100.0 |

## 总结

- 通过: 32
- 失败: 0
- 总计: 32
- 状态: 全部通过
