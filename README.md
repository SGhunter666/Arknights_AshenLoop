# 明日方舟：灰烬回路

《明日方舟：灰烬回路》是一个使用 **Godot 4.6** 制作的单人卡牌 Roguelike 项目。整体体验参考《杀戮尖塔》的路线选择、卡组构筑与战斗节奏，但角色机制、敌人设计、事件路线和资源系统围绕明日方舟同人主题重新实现。

当前版本已经进入 **可完整游玩的初版**：可以选择角色、推进地图、经历普通战/精英战/事件/商店/休整/Boss，获得卡牌和模块，最终挑战终局 Boss。项目仍在持续平衡和扩充，但已经不是只验证功能的原型。

## 当前版本

- 引擎版本：Godot 4.6.x
- 主场景：`res://scenes/Main.tscn`
- 支持导出：Windows Desktop，当前预设为单文件 exe 内嵌 pck
- 当前主分支：`main`

## 可玩角色

当前包含 4 名可玩角色，每名角色都有独立初始卡组、专属卡池、角色机制和战斗定位。

### 阿米娅

阿米娅是高成长、高爆发的术师领袖，围绕 **意志、共振、支援与爆发窗口** 构筑。她可以通过支援牌滚动资源，也可以把意志转化为强力输出。

核心方向：

- 意志积累与爆发
- 共振铺垫与引爆
- 支援牌带动抽牌、减费和节奏
- 高成长但需要管理资源窗口

### 能天使

能天使是偏快节奏的连射角色，强调 **弹药、爆发射击、追加攻击和高频打击反馈**。她的回合通常更轻快，适合连续输出和快速处理敌人。

核心方向：

- 弹药与爆发状态
- 多段攻击和连射
- 快速抽牌与节奏循环
- 对单体和低血量敌人处理能力强

### 凯尔希

凯尔希围绕 **Mon3tr、融毁、修复与指令切换** 展开。她不是普通召唤模板，而是需要控制 Mon3tr 状态，在稳定治疗和融毁爆发之间切换。

核心方向：

- Mon3tr 独立承伤与输出
- 融毁状态下的高压爆发
- 修复、护盾和生命线管理
- 高上限但需要精确判断时机

### 临光

临光是防御运营型角色，围绕 **护盾继承、光耀、救援、支援运营和反击** 构筑。她更适合把战斗拖入自己舒服的节奏，再通过反击和光耀完成反打。

核心方向：

- 护盾不会在回合结束被清空
- 反击会在敌人攻击后按规则触发
- 光耀提供成长与防御节奏
- 稳定、防守、消耗战能力强

## 战斗与构筑

游戏采用回合制卡牌战斗。玩家每回合获得能量，抽取手牌，使用攻击、防御、技能、支援等不同类型卡牌处理敌方意图。

当前主要系统包括：

- **能量**：每回合的出牌资源。
- **护盾**：抵挡伤害，部分角色拥有特殊继承规则。
- **意志**：阿米娅等角色的重要构筑资源。
- **共振**：可被叠加、转化、引爆的状态资源。
- **爆发/融毁**：部分角色的高风险高收益状态。
- **光耀/反击**：临光的防守反击核心。
- **弹药**：能天使连射和爆发的节奏资源。
- **Mon3tr**：凯尔希的特殊战斗单位与状态核心。

战斗反馈已经加入了更明显的攻击、受击、反击、敌方行动和负面牌获得提示，目标是让打击感更接近成熟卡牌 Roguelike。

## 奖励规则

战斗结束后会进入奖励选择。当前版本的普通战卡牌奖励也有概率出现高品质卡牌：

- 普通卡牌：默认主体奖励
- 精英卡牌：每个奖励位约 5% 概率
- 稀有卡牌：每个奖励位约 2% 概率

卡牌正面和图鉴中会显示品质标识，方便玩家区分普通、精英、稀有和基础卡牌。基础/初始卡牌不会作为常规战斗奖励进入卡池。

## 地图流程

当前地图包含类爬塔路线推进：

- 普通战
- 精英战
- 事件
- 剧情
- 商店
- 休整
- Boss

地图界面支持路线节点、图例、侧边信息、当前卡组/模块/护符/调律查看，并针对不同显示比例和 Windows 缩放做了适配选项。

## 当前内容规模

截至当前版本，仓库中包含：

- 4 名可玩角色
- 约 798 张卡牌资源
- 40 个敌人资源
- 26 个事件资源
- 52 个模块资源
- 24 个护符资源
- 多套 Boss、精英敌人与普通敌人配置
- 角色选择、主菜单、设置、百科、地图、战斗、奖励、商店、休整、胜利/失败界面

## 运行项目

### 环境要求

- Godot 4.6.x
- 推荐使用与项目同版本或兼容的稳定版编辑器

### 启动方式

1. 用 Godot 打开仓库根目录。
2. 确认主场景为：

```text
res://scenes/Main.tscn
```

3. 点击运行项目即可进入主菜单。

## 导出 Windows 可执行文件

项目已经配置 `Windows Desktop` 导出预设，并使用内嵌 pck 的单文件 exe 方案。

在 Godot 中文界面中：

1. 打开项目。
2. 进入 `项目 -> 导出`。
3. 选择 `Windows Desktop`。
4. 确认已经安装导出模板。
5. 点击 `导出项目`。
6. 建议导出为：

```text
AshenLoopDemo.exe
```

导出后把 exe 传到 Windows 电脑即可运行。若 Windows 使用 150% 缩放或 16:10 屏幕，建议在游戏设置中选择更适合的显示配置，例如 Windows 推荐或 MacBook 推荐。

## 测试

仓库内包含多套 headless smoke test，用于快速检查关键流程是否回归。

常用测试：

- `scripts/tools/card_effect_smoke_test.gd`
- `scripts/tools/ui_scene_smoke_test.gd`
- `scripts/tools/run_flow_smoke_test.gd`
- `scripts/tools/full_options_smoke_test.gd`
- `scripts/tools/export_starter_deck_smoke_test.gd`
- `scripts/tools/character_card_pool_isolation_smoke_test.gd`
- `scripts/tools/reward_rarity_smoke_test.gd`
- `scripts/tools/nearl_playable_smoke_test.gd`
- `scripts/tools/kaltsit_mon3tr_smoke_test.gd`
- `scripts/tools/w_boss_smoke_test.gd`

如果本地有项目使用的 Godot 可执行文件 `./godot`，可以这样运行：

```bash
./godot --headless --path . -s scripts/tools/card_effect_smoke_test.gd
./godot --headless --path . -s scripts/tools/ui_scene_smoke_test.gd
./godot --headless --path . -s scripts/tools/reward_rarity_smoke_test.gd
```

Windows 导出 smoke 可使用：

```bash
./godot --headless --path . --export-release "Windows Desktop" tmp/AshenLoopExportSmoke.exe
```

## 仓库结构

```text
assets/              图片、音效、UI 图标、背景、卡图与角色资源
data/                卡牌、角色、敌人、事件、模块、护符等 Godot 资源
docs/                架构、音频方向、英文参考等文档
scenes/              Godot 场景
scripts/autoload/    全局单例：RunManager、SceneRouter、Save、Settings、Audio
scripts/battle/      战斗流程、效果结算、单位状态、敌人 AI
scripts/core/        通用工具、调律库、UI 动画等底层能力
scripts/events/      事件运行与结算逻辑
scripts/map/         地图生成与节点模型
scripts/rewards/     战斗奖励与卡牌选择逻辑
scripts/rest/        休整点逻辑
scripts/shop/        商店逻辑
scripts/ui/          主菜单、角色选择、地图、战斗、奖励、百科、设置等界面
scripts/tools/       headless 测试与资源辅助脚本
```

## 开发重点

当前版本接下来的重点是：

- 继续平衡四名角色的卡池强度和构筑差异
- 强化 Boss 与精英敌人的机制压力
- 打磨战斗动画、攻击反馈、受击反馈和负面牌提示
- 继续修复导出版本与编辑器版本之间的差异
- 保持 Windows、MacBook、16:9、16:10 与高 DPI 缩放下的 UI 可用性

## 说明

本项目为明日方舟风格同人 / 学习型项目，不代表官方立场。仓库中的玩法设计、系统拆分、卡牌数值与事件实现主要为原创游戏化实现。若继续补充外部图像、音频或其他素材，请注意版权归属和使用范围。
