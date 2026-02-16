# 鹰图腾系列测试 - 踩过的坑

## 测试时间
2026-02-16T09:57:51

## 测试过程中遇到的问题

### storm_eagle
- place_unit returned false - may be occupied or invalid position

### gale_eagle
- place_unit returned false - may be occupied or invalid position

### harpy_eagle
- place_unit returned false - may be occupied or invalid position

### vulture
- place_unit returned false - may be occupied or invalid position


## 给后续开发者的建议

1. 确保GridManager和CombatManager在测试场景中正确定义
2. 单位放置前需要等待一帧确保管理器初始化完成
3. 攻击测试需要给单位足够时间检测和攻击敌人
4. 某些单位可能有特殊的攻击条件（如需要敌人进入范围）
