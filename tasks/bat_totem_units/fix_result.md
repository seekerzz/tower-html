# BloodMage.gd 修复报告

## 修复时间
2026-02-16

## 修复内容
- [x] 第30行: 移除 `get_tree()` 调用，直接使用 Constants.TILE_SIZE

### 修复前代码
```gdscript
var tile_size = Constants.TILE_SIZE if "Constants" in get_tree().root else 60.0
```

### 修复后代码
```gdscript
var tile_size = Constants.TILE_SIZE
```

### 修复原因
行为脚本（Behavior）不是Node，无法直接调用 `get_tree()` 方法。Constants 是全局自动加载的单例，可以直接访问。

## 测试结果
- [x] 放置测试: PASS
- [x] 攻击测试: PASS
- [x] 受击测试: PASS
- [x] 清理测试: PASS

## 详细测试输出
```
Unit Test Results:

  vampire_bat:
    - Placement: PASS
    - Attack: PASS
    - Defense: PASS

  plague_spreader:
    - Placement: PASS
    - Attack: PASS
    - Defense: PASS

  blood_mage:
    - Placement: PASS
    - Attack: PASS
    - Defense: PASS

  blood_ancestor:
    - Placement: PASS
    - Attack: PASS
    - Defense: PASS

------------------------------------------------------------
Total: 12 passed, 0 failed out of 12 tests

ALL RUNTIME TESTS PASSED!
```

## 备注
- 文件路径: `/home/zhangzhan/tower-html/src/Scripts/Units/Behaviors/BloodMage.gd`
- 修复行号: 第30行
- 测试场景: `src/Scenes/Tests/TestBatTotemRuntime.tscn`
