# 明日方舟：灰烬回路

一个基于 **Godot 4.6** 的《明日方舟》风格单人卡牌 Roguelike 项目。  
整体方向参考《杀戮尖塔》式爬塔构筑，但核心机制围绕 **Amiya** 的术式、意志、共振、支援协同与过载代价展开。

> 当前仓库是一个 **可游玩、持续迭代中的原型版本**，重点已经从“只把功能拼起来”转向“系统纯度、UI 表现、战斗手感与可维护结构”。

## 项目特点

- **主角固定为 Amiya**
  - 不是普通法伤模板，而是围绕 `Will / Resonance / Overload / Support` 展开构筑
- **类杀戮尖塔式路线推进**
  - 地图分叉、普通战、精英战、事件、商店、休整、Boss
- **数据驱动结构**
  - 卡牌、敌人、事件、模块、Charm 基本都已资源化，后续扩内容不需要一直改死代码
- **明日方舟风格表现**
  - 角色/敌方立绘、背景图、主菜单、百科、战斗 HUD、音效分层都在持续靠拢更完整的视觉表现
- **可测试**
  - 已有多套 Godot headless smoke tests，用来验证 UI、流程、奖励、W Boss、自动跑关等关键环节

## 当前实现规模

截至目前，仓库中已经包含：

- **116** 张卡牌资源
- **40** 个敌人资源
- **21** 个事件资源
- **20** 个模块资源
- **8** 个 Charm 资源
- **4** 层地图流程框架
  - 第 4 层为隐藏路线 / 隐藏 Boss 方向

## 核心系统

### 1. Energy

- 每回合基础资源
- 决定单回合能打出多少张牌

### 2. Will

- Amiya 的核心资源之一
- 用于阈值判定、爆发伤害与部分卡牌消耗

### 3. Resonance

- 挂在敌人或玩家身上的“资源型状态”
- 本身不是自动增伤，而是给共振流牌组铺垫、转化、引爆的条件

### 4. Overload

- 高风险高收益系统
- 回合结束会带来代价，但也能被部分卡牌、模块、Charm 反向利用

### 5. Support / Command

- 支援牌不是单纯加数值，而是构筑节奏发动机
- 负责拉抽牌、减费、回手、补能量、增强 Arts 爆发

## 当前可玩的主要内容

- Amiya 单角色开局
- 主菜单 / 角色页 / 设置 / 百科全书
- 地图选择与随机节点推进
- 普通战 / 精英战 / Boss 战
- 事件选择与长期路线影响
- 战后奖励、商店、休整点
- 胜利 / 失败 / 中途放弃战斗结算
- W 作为主线终局 Boss，隐藏路线继续向隐藏 Boss 延伸

## 战斗体验方向

这个项目当前的战斗设计，重点不是“普通法伤牌打来打去”，而是以下几条构筑路线：

- **Will Burst**
  - 蓄力、阈值、终结爆发
- **Resonance Combo**
  - 叠层、联动、引爆、顺序收益
- **Command Support**
  - 通过支援牌滚资源、做大回合
- **Overload Sacrifice**
  - 用掉血与风险换取上限

## 运行方式

### 环境要求

- **Godot 4.6.x**
- 推荐使用与项目同版本或兼容的稳定版编辑器打开

### 启动项目

1. 用 Godot 打开仓库根目录
2. 主场景为：

```text
res://scenes/Main.tscn
```

3. 直接运行项目即可进入主菜单

## 测试

仓库内包含多套 smoke test 场景，适合快速检查功能是否回归：

- `res://scenes/UISceneSmokeTest.tscn`
- `res://scenes/FullOptionsSmokeTest.tscn`
- `res://scenes/RunFlowSmokeTest.tscn`
- `res://scenes/CardEffectSmokeTest.tscn`
- `res://scenes/WBossSmokeTest.tscn`
- `res://scenes/AutoplayRunSmokeTest.tscn`
- `res://scenes/AbandonBattleSmokeTest.tscn`

如果本地存在可执行文件 `./godot`，可直接这样跑：

```bash
./godot --headless --path . --scene res://scenes/UISceneSmokeTest.tscn
```

## 仓库结构

```text
assets/              图片、音效、UI 图标、背景资源
data/                卡牌、敌人、事件、模块、Charm 等数据资源
docs/                说明文档、音频设计说明等
scenes/              Godot 场景
scripts/autoload/    全局单例：RunManager / SceneRouter / Save / Settings / Audio
scripts/battle/      战斗流程、效果结算、敌人 AI
scripts/core/        通用工具、UI 动画、调律库等底层能力
scripts/events/      事件结算逻辑
scripts/map/         地图生成与节点流程
scripts/rest/        休整点服务
scripts/ui/          主菜单、战斗、奖励、百科、设置等界面脚本
scripts/tools/       headless 测试、资源生成辅助脚本
```

## 当前开发重点

目前更关注这些方向：

- 继续压实各构筑流派的差异感
- 强化 Boss 机制检定，而不是单纯堆数值
- 把 UI / 动效 / 音效进一步向更完整的卡牌 Roguelike 体验靠拢
- 用自动测试稳住流程，减少“改一个界面炸另一处”的回归问题

## 后续计划

- 继续打磨 Amiya 卡池与流派分化
- 强化事件的长期影响与路线差异
- 进一步优化百科、奖励、商店与休整界面
- 补充更多敌人立绘与卡图
- 继续平衡隐藏路线与高难流程

## 说明

- 本项目为 **明日方舟风格同人 / 学习型项目**，不代表官方立场。
- 仓库中的玩法设计、系统拆分与卡牌数值主要为原创游戏化实现。
- 若后续补入更多外部图像或音频资源，请注意版权归属与使用范围。
