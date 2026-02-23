@echo off
chcp 65001 >nul
echo ========================================
echo  塔防游戏单位自动化测试脚本
echo ========================================
echo.

set "GODOT=godot"
set "PASSED=0"
set "FAILED=0"

echo [1/6] 测试牛图腾流派单位...
%GODOT% --path . --headless -- --run-test=test_cow_totem_plant 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_cow_totem_iron_turtle 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_cow_totem_hedgehog 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_cow_totem_yak_guardian 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_cow_totem_cow_golem 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_cow_totem_rock_armor_cow 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_cow_totem_mushroom_healer 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_cow_totem_cow 2>nul && set /a PASSED+=1 || set /a FAILED+=1
echo.

echo [2/6] 测试蝙蝠图腾流派单位...
%GODOT% --path . --headless -- --run-test=test_bat_totem_mosquito 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_bat_totem_vampire_bat 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_bat_totem_plague_spreader 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_bat_totem_blood_mage 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_bat_totem_blood_ancestor 2>nul && set /a PASSED+=1 || set /a FAILED+=1
echo.

echo [3/6] 测试蝴蝶图腾流派单位...
%GODOT% --path . --headless -- --run-test=test_butterfly_totem_torch 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_butterfly_totem_butterfly 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_butterfly_totem_fairy_dragon 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_butterfly_totem_phoenix 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_butterfly_totem_eel 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_butterfly_totem_dragon 2>nul && set /a PASSED+=1 || set /a FAILED+=1
echo.

echo [4/6] 测试狼图腾流派单位...
%GODOT% --path . --headless -- --run-test=test_wolf_totem_tiger 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_wolf_totem_dog 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_wolf_totem_lion 2>nul && set /a PASSED+=1 || set /a FAILED+=1
echo.

echo [5/6] 测试眼镜蛇图腾流派单位...
%GODOT% --path . --headless -- --run-test=test_viper_totem_spider 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_viper_totem_snowman 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_viper_totem_scorpion 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_viper_totem_viper 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_viper_totem_arrow_frog 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_viper_totem_medusa 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_viper_totem_lure_snake 2>nul && set /a PASSED+=1 || set /a FAILED+=1
echo.

echo [6/6] 测试鹰图腾流派单位...
%GODOT% --path . --headless -- --run-test=test_eagle_totem_harpy_eagle 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_gale_eagle 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_kestrel 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_owl 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_eagle 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_vulture 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_magpie 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_pigeon 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_woodpecker 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_parrot 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_peacock 2>nul && set /a PASSED+=1 || set /a FAILED+=1
%GODOT% --path . --headless -- --run-test=test_eagle_totem_storm_eagle 2>nul && set /a PASSED+=1 || set /a FAILED+=1
echo.

echo ========================================
echo  测试结果汇总
echo ========================================
echo 通过: %PASSED%
echo 失败: %FAILED%
echo 总计: %PASSED% + %FAILED%
echo.

if %FAILED%==0 (
    echo ✓ 所有测试通过！
    exit /b 0
) else (
    echo ✗ 有测试失败，请检查日志
    exit /b 1
)
