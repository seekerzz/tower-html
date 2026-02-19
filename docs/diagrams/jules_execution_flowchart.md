# Jules 执行流程图

> 由系统架构师（陈睿）基于审核报告生成
> 生成时间: 2026-02-19

## 1. 总体执行流程

```mermaid
flowchart TB
    subgraph Phase1["📦 Phase 1: P0 基础系统 (必须串行)"]
        direction TB
        P01["P0-01<br/>狼图腾魂魄系统"] --> P04["P0-04<br/>流血吸血系统"]
        P04 --> P02["P0-02<br/>嘲讽/仇恨系统"]
        P02 --> P03["P0-03<br/>召唤物系统"]
    end

    subgraph Phase2["🚀 Phase 2: P1 单位实现 (按图腾并行)"]
        direction TB
        subgraph GroupA["组A: 狼图腾单位"]
            A1["血食"] & A2["猛虎"] & A3["恶霸犬"] & A4["鬣狗"] & A5["狮子"]
            A6["狼<br/>(需吞噬UI)"] & A7["羊灵<br/>(需召唤系统)"]
        end

        subgraph GroupB["组B: 眼镜蛇单位<br/>(可立即执行)"]
            B1["老鼠"] & B2["蟾蜍"] & B3["美杜莎Lv3"]
        end

        subgraph GroupC["组C: 蝙蝠图腾单位"]
            C1["石像鬼"] & C2["生命链条"] & C3["鲜血圣杯"] & C4["血祭术士"]
            C5["蚊子Lv3"] & C6["血法师Lv3"]
        end

        subgraph GroupD["组D: 蝴蝶单位<br/>(可立即执行)"]
            D1["冰晶蝶"] & D2["萤火虫"] & D3["木精灵"]
            D4["蝴蝶技能"] & D5["凤凰Lv3"] & D6["龙Lv3"]
        end

        subgraph GroupE["组E: 鹰单位<br/>(可立即执行)"]
            E1["红隼"] & E2["猫头鹰"] & E3["喜鹊"] & E4["鸽子"]
            E5["角雕完善"] & E6["疾风鹰完善"] & E7["老鹰完善"]
            E8["秃鹫完善"] & E9["啄木鸟完善"]
        end

        subgraph GroupF["组F: 牛图腾单位"]
            F1["树苗完善"] & F2["铁甲龟完善"] & F3["刺猬完善"]
            F4["岩甲牛完善"] & F5["牛椋鸟完善"] & F6["奶牛完善"]
            F7["苦修者<br/>(需目标选择UI)"] & F8["牦牛守护<br/>(需嘲讽系统)"]
            F9["菌菇治愈者<br/>(需重写)"]
        end
    end

    subgraph Phase3["✅ Phase 3: 最终整合"]
        direction TB
        Merge["合并所有分支"] --> Test["运行测试套件"]
        Test --> Release["发布到 main"]
    end

    Phase1 --> Phase2
    Phase2 --> Phase3

    style P01 fill:#ff9999
    style P04 fill:#ff9999
    style P02 fill:#ff9999
    style P03 fill:#ff9999
    style GroupA fill:#99ccff
    style GroupC fill:#99ccff
    style GroupF fill:#99ccff
    style GroupB fill:#99ff99
    style GroupD fill:#99ff99
    style GroupE fill:#99ff99
```

## 2. 依赖关系图

```mermaid
flowchart LR
    subgraph P0["P0 基础系统"]
        Soul["魂魄系统<br/>P0-01"]
        Taunt["嘲讽系统<br/>P0-02"]
        Summon["召唤系统<br/>P0-03"]
        Bleed["流血吸血<br/>P0-04"]
    end

    subgraph P1["P1 单位实现"]
        Wolf["狼图腾单位<br/>P1-A"]
        Viper["眼镜蛇单位<br/>P1-B"]
        Bat["蝙蝠单位<br/>P1-C"]
        Butterfly["蝴蝶单位<br/>P1-D"]
        Eagle["鹰单位<br/>P1-E"]
        Cow["牛图腾单位<br/>P1-F"]
    end

    Soul --> Wolf
    Soul --> Bat
    Taunt --> Cow
    Summon --> Wolf
    Bleed --> Bat

    style Soul fill:#ff9999
    style Taunt fill:#ff9999
    style Summon fill:#ff9999
    style Bleed fill:#ff9999
```

## 3. 分支合并策略

```mermaid
flowchart TB
    subgraph Branches["分支结构"]
        Main["main<br/>(基线分支)"]

        subgraph P0Branches["P0 系统分支"]
            P01B["feature/P0-01-soul-system"]
            P02B["feature/P0-02-aggro-system"]
            P03B["feature/P0-03-summon-system"]
            P04B["feature/P0-04-lifesteal-system"]
        end

        subgraph P1Branches["P1 单位分支"]
            P1AB["feature/P1-wolf-units"]
            P1BB["feature/P1-viper-units"]
            P1CB["feature/P1-bat-units"]
            P1DB["feature/P1-butterfly-units"]
            P1EB["feature/P1-eagle-units"]
            P1FB["feature/P1-cow-units"]
        end
    end

    subgraph MergePoints["合并窗口"]
        M1["合并点1<br/>P0系统完成"]
        M2["合并点2<br/>狼图腾完成"]
        M3["合并点3<br/>眼镜蛇完成"]
        M4["合并点4<br/>蝙蝠完成"]
        M5["合并点5<br/>蝴蝶完成"]
        M6["合并点6<br/>鹰完成"]
        M7["合并点7<br/>牛图腾完成"]
    end

    P01B --> M1
    P04B --> M1
    P02B --> M1
    P03B --> M1
    M1 --> Main

    M1 --> P1AB
    M1 --> P1BB
    M1 --> P1CB
    M1 --> P1DB
    M1 --> P1EB
    M1 --> P1FB

    P1AB --> M2 --> Main
    P1BB --> M3 --> Main
    P1CB --> M4 --> Main
    P1DB --> M5 --> Main
    P1EB --> M6 --> Main
    P1FB --> M7 --> Main

    style Main fill:#99ff99
    style M1 fill:#ffcc99
    style M2 fill:#ffcc99
    style M3 fill:#ffcc99
    style M4 fill:#ffcc99
    style M5 fill:#ffcc99
    style M6 fill:#ffcc99
    style M7 fill:#ffcc99
```

## 4. 高风险冲突区域

```mermaid
flowchart TB
    subgraph RiskAreas["⚠️ 高风险冲突区域"]
        direction TB

        JSON["data/game_data.json<br/><br/>所有Prompt都需要修改<br/>冲突概率: 高"]

        Enemy["src/Scripts/Enemy.gd<br/><br/>4个P0系统都需要修改<br/>冲突概率: 高"]

        Unit["src/Scripts/Unit.gd<br/><br/>基类修改影响所有单位<br/>冲突概率: 中"]

        Manager["src/Autoload/ 管理器<br/><br/>新增多个单例管理器<br/>冲突概率: 低"]
    end

    subgraph Mitigation["🛡️ 缓解方案"]
        J1["每个图腾独立配置段"]
        E1["使用信号而非直接修改"]
        U1["优先使用组合而非继承"]
        M1["独立文件，无冲突"]
    end

    JSON --> J1
    Enemy --> E1
    Unit --> U1
    Manager --> M1

    style JSON fill:#ff9999
    style Enemy fill:#ff9999
    style Unit fill:#ffcc99
    style Manager fill:#99ff99
```

## 5. 执行时间表 (建议)

| 阶段 | 任务 | 预估时间 | 依赖 | 合并点 |
|-----|------|---------|------|--------|
| **Phase 1** | | | | |
| | P0-01 狼图腾魂魄系统 | 2-3天 | 无 | M1 |
| | P0-04 流血吸血系统 | 2天 | P0-01 | M1 |
| | P0-02 嘲讽/仇恨系统 | 2-3天 | P0-04 | M1 |
| | P0-03 召唤物系统 | 2天 | P0-02 | M1 |
| **Phase 2** | | | | |
| | P1-A 狼图腾单位群 | 4-5天 | P0-01, P0-03 | M2 |
| | P1-B 眼镜蛇单位群 | 2-3天 | 无 | M3 |
| | P1-C 蝙蝠图腾单位群 | 4-5天 | P0-04 | M4 |
| | P1-D 蝴蝶单位群 | 3-4天 | 无 | M5 |
| | P1-E 鹰单位群 | 4-5天 | 无 | M6 |
| | P1-F 牛图腾单位群 | 4-5天 | P0-02 | M7 |
| **Phase 3** | | | | |
| | 最终整合测试 | 2-3天 | M2-M7 | Release |

**总计预估**: 约 4-5 周

## 6. Jules 命令参考

```bash
# ========== Phase 1: P0 基础系统 ==========

# P0-01: 狼图腾魂魄系统
jules --prompt="docs/jules_prompts/P0_01_wolf_totem_soul_system.md" \
      --branch="feature/P0-01-soul-system" \
      --reviewers="@game-designer,@system-architect"

# P0-04: 流血吸血系统
jules --prompt="docs/jules_prompts/P0_04_bleed_lifesteal_system.md" \
      --branch="feature/P0-04-lifesteal" \
      --base="feature/P0-01-soul-system"

# P0-02: 嘲讽/仇恨系统
jules --prompt="docs/jules_prompts/P0_02_taunt_aggro_system.md" \
      --branch="feature/P0-02-aggro-system" \
      --base="feature/P0-04-lifesteal"

# P0-03: 召唤物系统
jules --prompt="docs/jules_prompts/P0_03_summon_system.md" \
      --branch="feature/P0-03-summon-system" \
      --base="feature/P0-02-aggro-system"

# ========== Phase 2: P1 单位实现 ==========

# P1-A: 狼图腾单位群
jules --prompt="docs/jules_prompts/P1_01_wolf_units_implementation.md" \
      --branch="feature/P1-wolf-units" \
      --base="main"

# P1-B: 眼镜蛇单位群
jules --prompt="docs/jules_prompts/P1_02_viper_cobra_units.md" \
      --branch="feature/P1-viper-units" \
      --base="main"

# P1-C: 蝙蝠图腾单位群
jules --prompt="docs/jules_prompts/P1_03_bat_totem_units.md" \
      --branch="feature/P1-bat-units" \
      --base="main"

# P1-D: 蝴蝶图腾单位群
jules --prompt="docs/jules_prompts/P1_04_butterfly_units.md" \
      --branch="feature/P1-butterfly-units" \
      --base="main"

# P1-E: 鹰单位群
jules --prompt="docs/jules_prompts/P1_05_eagle_units.md" \
      --branch="feature/P1-eagle-units" \
      --base="main"

# P1-F: 牛图腾单位群
jules --prompt="docs/jules_prompts/P1_06_cow_totem_units.md" \
      --branch="feature/P1-cow-units" \
      --base="main"
```

## 7. 关键检查点

在每个合并点之前，需要验证以下内容：

### M1 (P0系统完成)
- [ ] SoulManager 单例工作正常
- [ ] AggroManager 嘲讽逻辑正确
- [ ] SummonManager 生命周期管理正确
- [ ] LifestealManager 吸血计算正确
- [ ] 所有P0系统单元测试通过

### M2-M7 (各图腾单位完成)
- [ ] 新单位配置文件正确添加
- [ ] 单位技能效果符合设计文档
- [ ] 与其他单位的协同效果正常
- [ ] 无性能问题(帧率下降 < 5%)

### Release (最终发布)
- [ ] 所有单元测试通过
- [ ] 集成测试通过
- [ ] 性能测试通过
- [ ] 代码审查完成

---

*此流程图由系统架构师基于审核报告生成，如有变更需要更新*
