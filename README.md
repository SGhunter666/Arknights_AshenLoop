# 明日方舟：灰烬回路

一个基于 Godot 4 的《明日方舟》同人卡牌 Roguelike 原型，方向参考《杀戮尖塔》式单人爬塔。当前版本已经从“单脚本原型”升级成更接近正式项目的脚手架：`Resources + Autoload + BattleManager + MapGenerator`。

## 当前内容

- 1 名可玩角色：Amiya
- 4 层地图模板，其中第 4 层为隐藏层框架
- 多类普通敌人、精英敌人和 3 个楼层 Boss
- 基础战斗循环：抽牌、能量、Will、Block、Support、Curse、W 规则干扰
- 5 个首发事件资源
- 战后卡牌奖励、模块、商店与休整节点
- 数据驱动资源目录，可继续往 `data/` 扩充

## 主要文件

- `project.godot`
- `scenes/MainMenu.tscn`
- `scenes/MapScene.tscn`
- `scenes/BattleScene.tscn`
- `scenes/EventScene.tscn`
- `scenes/RewardScene.tscn`
- `scenes/ShopScene.tscn`
- `scenes/RestScene.tscn`
- `scripts/autoload/RunManager.gd`
- `scripts/autoload/SceneRouter.gd`
- `scripts/battle/BattleManager.gd`
- `scripts/core/util.gd`
- `data/cards/*.tres`
- `data/enemies/*.tres`
- `data/events/*.tres`
- `data/modules/*.tres`

## 关于图像

当前仓库里没有现成角色/敌人素材，本版本先用纯 UI 原型把玩法跑通，没有内置官网图或 AI 图。

如果你后续要补图，推荐这样接：

1. 在 `res://assets/portraits/` 放角色和敌人立绘。
2. 在战斗场景中给玩家/敌方面板加入 `TextureRect`。
3. 在 `GameData` 里给角色、敌人和事件加 `portrait_path` / `background_path` 字段。

## 下一步最值得补

1. 把当前 20 张左右资源卡扩到你规格里的 40 张首发卡。
2. 把地图从楼层模板推进升级成真正分叉图。
3. 给 `BattleScene` 加角色/敌人立绘与卡面图。
4. 完善 W 的三阶段规则变化与隐藏结局收束。
5. 新增 Nearl / Exusiai / Kal'tsit 三套职业牌池。
