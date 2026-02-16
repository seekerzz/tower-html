# 鹰图腾系列运行时测试报告

## 测试时间
2026-02-16T09:57:51

## 测试单位

### storm_eagle
- 放置测试: FAIL
- 攻击测试: FAIL
- 受击测试: FAIL
- 错误信息:
  - place_unit returned false - may be occupied or invalid position

### gale_eagle
- 放置测试: FAIL
- 攻击测试: FAIL
- 受击测试: FAIL
- 错误信息:
  - place_unit returned false - may be occupied or invalid position

### harpy_eagle
- 放置测试: FAIL
- 攻击测试: FAIL
- 受击测试: FAIL
- 错误信息:
  - place_unit returned false - may be occupied or invalid position

### vulture
- 放置测试: FAIL
- 攻击测试: FAIL
- 受击测试: FAIL
- 错误信息:
  - place_unit returned false - may be occupied or invalid position

## 发现的问题
1. place_unit returned false - may be occupied or invalid position
   - 影响单位: storm_eagle
1. place_unit returned false - may be occupied or invalid position
   - 影响单位: gale_eagle
1. place_unit returned false - may be occupied or invalid position
   - 影响单位: harpy_eagle
1. place_unit returned false - may be occupied or invalid position
   - 影响单位: vulture

## 总结
- 通过: 0/12
- 失败: 12/12
