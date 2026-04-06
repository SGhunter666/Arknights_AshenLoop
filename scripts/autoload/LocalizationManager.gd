extends Node

signal language_changed(language_code: String)

const LANG_ZH := "zh"
const LANG_EN := "en"

var current_language: String = LANG_ZH

var ui_text := {
	"main.title": {"zh": "明日方舟：灰烬回路", "en": "Arknights: Ashes Circuit"},
	"main.brand_top": {"zh": "明日方舟：", "en": "Arknights:"},
	"main.brand_bottom": {"zh": "灰烬回路", "en": "Ashes Circuit"},
	"main.subtitle": {"zh": "主菜单", "en": "Main Menu"},
	"main.single_player": {"zh": "单人模式", "en": "Single Player"},
	"main.multiplayer": {"zh": "多人模式", "en": "Multiplayer"},
	"main.timeline": {"zh": "时间线", "en": "Timeline"},
	"main.settings": {"zh": "设置", "en": "Settings"},
	"main.codex": {"zh": "百科大全", "en": "Compendium"},
	"main.quit": {"zh": "退出游戏", "en": "Quit Game"},
	"main.save_slot": {"zh": "存档1\n第 %d 层  %d/%d", "en": "Save 1\nFloor %d  %d/%d"},
	"system.return_main": {"zh": "返回主菜单", "en": "Return to Main Menu"},
	"main.hint": {"zh": "点击任意选项后会进入新的页面。", "en": "Select any option to open a new page."},
	"main.hero_title": {"zh": "罗德岛终端", "en": "Rhodes Island Terminal"},
	"main.hero_body": {"zh": "主界面现在包含明确可见的主视觉图像。", "en": "The main menu now includes a clearly visible hero image."},
	"single.title": {"zh": "单人游戏", "en": "Single Player"},
	"single.header": {"zh": "角色选择", "en": "Character Select"},
	"single.body": {"zh": "请选择一个角色查看资料，然后再确认开始游戏。", "en": "Select a character to view details, then confirm before starting."},
	"single.back": {"zh": "返回", "en": "Back"},
	"single.start": {"zh": "开始游戏", "en": "Start Game"},
	"single.resume": {"zh": "继续游戏", "en": "Continue Run"},
	"single.locked": {"zh": "未解锁", "en": "Locked"},
	"single.skill_header": {"zh": "特有机制", "en": "Signature Mechanic"},
	"single.reserved": {"zh": "其他角色（待启用）", "en": "Other Operators (Coming Soon)"},
	"single.status": {"zh": "请选择角色查看介绍。\n历史开局次数: %d", "en": "Select a character to view details.\nRecorded starts: %d"},
	"single.missing_amiya": {"zh": "缺少角色资源: amiya.tres", "en": "Missing character resource: amiya.tres"},
	"single.resume_hint": {"zh": "检测到未完成行动：第 %d 层，金币 %d，生命 %d/%d。点击右下角即可继续。", "en": "Unfinished operation found: Floor %d, Gold %d, HP %d/%d. Press the button below to resume."},
	"single.amiya_header": {"zh": "Amiya | 罗德岛领袖", "en": "Amiya | Leader of Rhodes Island"},
	"single.amiya_stats": {"zh": "生命 72/72    起始能量 3    核心资源：意志", "en": "HP 72/72    Starting Energy 3    Core Resource: Will"},
	"single.amiya_intro": {"zh": "阿米娅是罗德岛的年轻领导者，擅长强力术式，并会亲自前往前线解决问题。在这套构筑中，她的定位是高成长、高代价的术师领袖，既能打出爆发伤害，也能通过支援牌带动全局节奏。", "en": "Amiya is Rhodes Island's young leader, wielding powerful Arts and stepping onto the front lines herself. In this deckbuilder she serves as a high-growth, high-cost caster leader who mixes burst damage with support-driven tempo."},
	"single.amiya_will": {"zh": "特有机制：意志（Will）\n意志是阿米娅的专属资源。部分卡牌会积累意志，意志越高，她的高阶术式就越强，像终结牌和爆发牌都会随着意志提升伤害。\n但意志并不是越高越好：它代表精神负荷与承担的代价，部分牌会消耗意志，某些过载打法还会带来自伤或节奏风险。简单来说，意志就是阿米娅在战斗中把“责任”转化为力量的核心系统。", "en": "Signature Mechanic: Will\nWill is Amiya's exclusive resource. Several cards build Will, and the more Will she has, the stronger her advanced Arts become. Finishers and burst spells scale directly with it.\nBut high Will comes with pressure: some cards spend it, and overload-style lines can cause self-damage or tempo loss. In short, Will is the system that turns Amiya's burden into combat power."},
	"settings.title": {"zh": "设置", "en": "Settings"},
	"settings.body": {"zh": "常见游戏设置选项。", "en": "Common game settings."},
	"settings.resolution": {"zh": "分辨率", "en": "Resolution"},
	"settings.display_mode": {"zh": "显示模式", "en": "Display Mode"},
	"settings.language": {"zh": "语言", "en": "Language"},
	"settings.ui_scale": {"zh": "界面缩放", "en": "UI Scale"},
	"settings.fullscreen": {"zh": "全屏", "en": "Fullscreen"},
	"settings.windowed": {"zh": "窗口模式", "en": "Windowed"},
	"settings.maximized": {"zh": "最大化窗口", "en": "Maximized"},
	"settings.fullscreen_mode": {"zh": "独占全屏", "en": "Fullscreen"},
	"settings.borderless": {"zh": "无边框窗口", "en": "Borderless Window"},
	"settings.vsync": {"zh": "垂直同步", "en": "VSync"},
	"settings.auto_end_turn": {"zh": "自动结束回合（无可用牌时）", "en": "Auto End Turn (when no playable cards)"},
	"settings.master": {"zh": "主音量", "en": "Master Volume"},
	"settings.music": {"zh": "音乐音量", "en": "Music Volume"},
	"settings.sfx": {"zh": "音效音量", "en": "SFX Volume"},
	"settings.voice": {"zh": "语音音量", "en": "Voice Volume"},
	"settings.back": {"zh": "返回", "en": "Back"},
	"system.return_game": {"zh": "返回游戏", "en": "Return to Game"},
	"codex.title": {"zh": "百科大全", "en": "Compendium"},
	"codex.back": {"zh": "<", "en": "<"},
	"codex.cards": {"zh": "卡牌总览", "en": "Card Archive"},
	"codex.cards_body": {"zh": "查看你在行动中见过的卡牌。", "en": "Review cards discovered during runs."},
	"codex.modules": {"zh": "模块收藏", "en": "Module Vault"},
	"codex.modules_body": {"zh": "检视已获得的战术模块。", "en": "Inspect tactical modules you have found."},
	"codex.lab": {"zh": "药剂研究所", "en": "Field Lab"},
	"codex.lab_body": {"zh": "整理战场补给与实验记录。", "en": "Browse combat supplies and field experiments."},
	"codex.monsters": {"zh": "怪物图鉴", "en": "Enemy Archive"},
	"codex.monsters_body": {"zh": "未来将开放敌方资料。", "en": "Enemy intel will unlock in future updates."},
	"codex.stats": {"zh": "角色数据", "en": "Operator Data"},
	"codex.stats_body": {"zh": "查看阿米娅的作战统计。", "en": "View Amiya's run statistics."},
	"codex.history": {"zh": "历史记录", "en": "History"},
	"codex.history_body": {"zh": "回看已经完成的行动。", "en": "Revisit completed operations."},
	"codex.glossary": {"zh": "术语说明", "en": "Glossary"},
	"codex.glossary_body": {"zh": "解释战斗中会反复出现的核心术语。", "en": "Explain the core terms used throughout combat."},
	"codex.detail_cards": {"zh": "这里会逐步汇总你见过的牌组构件，方便回看卡牌路线和构筑方向。", "en": "This section will gather discovered cards so you can review archetypes and build paths."},
	"codex.detail_modules": {"zh": "这里会记录获得过的模块、它们的效果，以及哪些模块更适合阿米娅当前的构筑。", "en": "This section will track found modules, their effects, and which ones best fit Amiya's current build."},
	"codex.detail_lab": {"zh": "这里预留给补给、药剂和战场实验记录，后续可以扩展成更完整的资源百科。", "en": "This area is reserved for supplies, potions, and field experiments as the prototype grows."},
	"codex.detail_monsters": {"zh": "敌方档案还没有完全开放。后续击败更多敌人后，这里会逐步点亮。", "en": "The enemy archive is still incomplete. It will fill in as you defeat more foes."},
	"codex.detail_stats": {"zh": "角色数据会集中展示阿米娅的出战次数、胜率和常用构筑方向。", "en": "Operator data will highlight Amiya's runs, success rate, and common build directions."},
	"codex.detail_history": {"zh": "历史记录会保存最近几次行动的楼层推进、失败节点和最终收益。", "en": "History will preserve recent run progress, failure points, and rewards."},
	"codex.detail_glossary": {"zh": "这里会解释意志、虚弱、术式、支援、诅咒等战斗术语，方便第一次接触卡牌构筑时快速理解。", "en": "This section explains combat terms like Will, Weak, Arts, Support, and Curse so new players can parse the system faster."},
	"settings.preview_title": {"zh": "显示预览", "en": "Display Preview"},
	"settings.preview_body": {"zh": "右侧保留主视觉和说明，避免设置页完全没有图像。", "en": "The right panel keeps a hero image and preview text visible."},
	"overlay.close": {"zh": "关闭", "en": "Close"},
	"overlay.empty_cards": {"zh": "这里还没有可显示的卡牌。", "en": "There are no cards to display here yet."},
	"overlay.empty_entries": {"zh": "这里还没有可显示的内容。", "en": "There is nothing to display here yet."},
	"codex.modules_title": {"zh": "模块收藏", "en": "Module Vault"},
	"codex.lab_title": {"zh": "药剂研究所", "en": "Field Lab"},
	"codex.monsters_title": {"zh": "怪物图鉴", "en": "Enemy Archive"},
	"codex.stats_title": {"zh": "角色数据", "en": "Operator Data"},
	"codex.history_title": {"zh": "历史记录", "en": "History"},
	"codex.glossary_title": {"zh": "术语说明", "en": "Glossary"},
	"codex.stats_runs": {"zh": "出战次数：%d", "en": "Runs Started: %d"},
	"codex.stats_wins": {"zh": "成功撤收：%d", "en": "Runs Won: %d"},
	"codex.stats_losses": {"zh": "行动失败：%d", "en": "Runs Lost: %d"},
	"codex.stats_best_floor": {"zh": "最高推进层数：%d", "en": "Best Floor: %d"},
	"codex.stats_total_gold": {"zh": "累计带回金币：%d", "en": "Total Gold Collected: %d"},
	"codex.stats_active_run": {"zh": "当前未完成行动：第 %d 层，生命 %d/%d，金币 %d", "en": "Active run: Floor %d, HP %d/%d, Gold %d"},
	"codex.stats_no_active_run": {"zh": "当前没有未完成行动。", "en": "There is no active run right now."},
	"codex.history_entry": {"zh": "%s | 第 %d 层 | 金币 %d | 卡组 %d | 模块 %d", "en": "%s | Floor %d | Gold %d | Deck %d | Modules %d"},
	"codex.history_victory": {"zh": "成功", "en": "Victory"},
	"codex.history_defeat": {"zh": "失败", "en": "Defeat"},
	"codex.lab_entry_supply_title": {"zh": "战地补给记录", "en": "Field Supply Notes"},
	"codex.lab_entry_supply_body": {"zh": "这里会整理目前原型里出现过的补给逻辑，包括休整点、金币收益和救援类卡牌的延伸设计。", "en": "This page tracks supply-side systems in the prototype, including rest points, gold rewards, and rescue-oriented cards."},
	"codex.lab_entry_alchemy_title": {"zh": "药剂与模块接口", "en": "Potion and Module Interface"},
	"codex.lab_entry_alchemy_body": {"zh": "当前模块系统已经接入战斗与地图循环。后续药剂、一次性消耗品和战斗外强化会从这里继续扩展。", "en": "The module system is already wired into combat and progression. Potions, one-shot consumables, and out-of-combat upgrades can grow from this page."},
	"codex.lab_entry_progress_title": {"zh": "研究进度", "en": "Research Progress"},
	"codex.lab_entry_progress_body": {"zh": "当前百科已经能打开卡牌、模块、怪物、角色数据和历史记录。下一步可以继续加入药剂图标、拾取来源和使用日志。", "en": "The compendium now opens cards, modules, enemies, operator stats, and history. The next step is adding potion icons, sources, and use logs."},
	"codex.enemy_hp": {"zh": "生命：%d", "en": "HP: %d"},
	"codex.enemy_gold": {"zh": "奖励金币：%d", "en": "Gold Reward: %d"},
	"codex.enemy_moves": {"zh": "行动模式：%s", "en": "Move Set: %s"},
	"codex.module_rarity": {"zh": "稀有度：%s", "en": "Rarity: %s"},
	"codex.module_count": {"zh": "已录入模块：%d", "en": "Modules Catalogued: %d"},
	"codex.enemy_tags": {"zh": "标签：%s", "en": "Tags: %s"},
	"codex.enemy_ai": {"zh": "战斗风格：%s", "en": "Combat Style: %s"},
	"codex.stats_winrate": {"zh": "胜率：%d%%", "en": "Win Rate: %d%%"},
	"codex.stats_deck_modules": {"zh": "当前卡组：%d 张   当前模块：%d 件", "en": "Current Deck: %d cards   Modules: %d"},
	"codex.history_record_body": {"zh": "角色：%s\n结果：%s\n推进层数：%d\n带回金币：%d\n卡组张数：%d\n模块数量：%d", "en": "Operator: %s\nResult: %s\nFloor Reached: %d\nGold Collected: %d\nDeck Size: %d\nModules: %d"},
	"codex.lab_entry_archive_title": {"zh": "条目录入", "en": "Archive Status"},
	"codex.lab_entry_archive_body": {"zh": "当前百科已经整理了 %d 张卡牌、%d 个模块、%d 个敌方单位，以及最近 %d 次行动记录。后续可以继续补充药剂图标、掉落来源和事件链索引。", "en": "The compendium currently tracks %d cards, %d modules, %d enemy units, and the most recent %d run records. Next steps can include potion icons, loot sources, and event chain indexing."},
	"codex.rarity_common": {"zh": "普通", "en": "Common"},
	"codex.rarity_elite": {"zh": "精英", "en": "Elite"},
	"codex.rarity_rare": {"zh": "稀有", "en": "Rare"},
	"codex.ai_basic": {"zh": "标准循环", "en": "Standard Pattern"},
	"codex.ai_w_boss": {"zh": "混沌首领", "en": "Chaos Boss"},
	"codex.tag_reunion": {"zh": "整合运动", "en": "Reunion"},
	"codex.tag_ranged": {"zh": "远程", "en": "Ranged"},
	"codex.tag_arts": {"zh": "术式", "en": "Arts"},
	"codex.tag_guard": {"zh": "重装近卫", "en": "Guard"},
	"codex.tag_boss": {"zh": "首领", "en": "Boss"},
	"codex.tag_elite": {"zh": "精英", "en": "Elite"},
	"codex.tag_siege": {"zh": "封锁装置", "en": "Siege"},
	"codex.term_will_title": {"zh": "意志（Will）", "en": "Will"},
	"codex.term_will_body": {"zh": "阿米娅的专属资源，上限 10。它不会自动让所有牌统一增伤，但会明确强化部分爆发术式：`Mind Alignment` 与 `Discipline Note` 各给 +1 意志，`Burn Will` 给 +3 意志；`Echo Conduit` 会额外获得“每 1 点意志 +1 伤害”，最多 +6；`Resonance Burst` 在意志达到 4 以上时额外 +4 伤害。意志越高，风险也越高，因为它经常和自伤、节奏损失或过载打法绑在一起。", "en": "Amiya's exclusive resource, capped at 10. It does not passively boost every card, but it clearly empowers some burst Arts: `Mind Alignment` and `Discipline Note` each grant +1 Will, `Burn Will` grants +3, `Echo Conduit` gains +1 damage per Will up to +6, and `Resonance Burst` gains +4 damage at 4+ Will. High Will also carries risk because it is often tied to self-damage, tempo loss, or overload lines."},
	"codex.term_arts_title": {"zh": "术式（Arts）", "en": "Arts"},
	"codex.term_arts_body": {"zh": "带有术式标签的牌会吃到阿米娅最核心的联动，也是她主要的伤害来源。当前原型里，阿米娅每回合第一次打出支援牌后，下一张术式牌固定 +2 伤害；如果带着 `Ashen Thread` 模块并且你刚刚自伤过，下一张术式还会再额外 +3。", "en": "Cards with the Arts tag benefit from Amiya's most important synergy and serve as her main damage source. In the current prototype, after Amiya plays her first Support each turn, her next Arts card gets a flat +2 damage. With `Ashen Thread`, the next Arts card after self-damage gains an additional +3."},
	"codex.term_support_title": {"zh": "支援（Support）", "en": "Support"},
	"codex.term_support_body": {"zh": "支援牌偏向抽牌、返还能量、调整节奏或找回关键牌。数值上最关键的是：阿米娅每回合第一次打出支援牌后，下一张术式固定 +2 伤害；如果装着 `Field Command Badge`，这第一次支援还会额外返还 1 点能量。", "en": "Support cards focus on draw, energy refunds, tempo control, or retrieving key tools. Numerically, the big payoff is this: after Amiya plays her first Support each turn, her next Arts card gets a flat +2 damage; with `Field Command Badge`, that first Support also refunds 1 extra Energy."},
	"codex.term_block_title": {"zh": "护盾（Block）", "en": "Block"},
	"codex.term_block_body": {"zh": "护盾会先替你承受伤害，再扣生命。它是最直接的防御资源，适合拿来顶一轮爆发或者拖回合。", "en": "Block absorbs damage before HP is lost. It is the most direct defensive resource and helps you survive bursts or buy extra turns."},
	"codex.term_weak_title": {"zh": "虚弱（Weak）", "en": "Weak"},
	"codex.term_weak_body": {"zh": "带有虚弱的单位造成的伤害会乘以 0.75，也就是直接少 25%。当前原型里，1 层虚弱通常会持续到这个单位完成下一次行动为止，然后自动减掉 1 层。比如敌人原本打 8，挂上虚弱后会变成 6。", "en": "A unit with Weak deals damage at 0.75x, which means a direct 25% reduction. In the current prototype, 1 stack of Weak usually lasts until that unit finishes its next action, then decays by 1. For example, an attack that would deal 8 instead deals 6 under Weak."},
	"codex.term_vulnerable_title": {"zh": "易伤（Vulnerable）", "en": "Vulnerable"},
	"codex.term_vulnerable_body": {"zh": "带有易伤的单位会受到 1.5 倍伤害，也就是多吃 50%。当前原型里，如果某个单位挂着 1 层易伤，这层通常会在它完成下一次行动后自动减掉。比如原本 10 点伤害，打到易伤目标身上会变成 15。", "en": "A unit with Vulnerable takes 1.5x damage, or 50% more. In the current prototype, 1 stack usually decays after that unit completes its next action. For example, 10 damage becomes 15 against a Vulnerable target."},
	"codex.term_curse_title": {"zh": "诅咒（Curse）", "en": "Curse"},
	"codex.term_curse_body": {"zh": "诅咒牌一般帮不上忙，只会塞进牌堆拖慢节奏，严重时还会直接带来惩罚。当前原型里：`Hesitation` 若回合结束还在手里会失去 1 点意志；`Panic Static` 抽到时会让你本回合第一张牌费用 +1；`Blast Countdown` 若回合结束还留在手里，会直接受到 8 点伤害。", "en": "Curse cards usually do not help and only clog the deck, slowing your tempo or directly causing penalties. In the current prototype: `Hesitation` makes you lose 1 Will if it remains in hand at end of turn, `Panic Static` makes your first card cost +1 when drawn, and `Blast Countdown` deals 8 damage if it is still in hand at end of turn."},
	"codex.term_rescue_title": {"zh": "救援（Rescue）", "en": "Rescue"},
	"codex.term_rescue_body": {"zh": "救援类牌和事件代表阿米娅把资源分出去救人。它们通常不会立刻打出最高伤害，但会换来金币、剧情标记或更好的长期收益。比如 `Rescue Corridor` 当前就是 1 费，给 6 点护盾并立即获得 10 金币。", "en": "Rescue cards and events represent Amiya diverting resources to save people. They usually do not create the biggest immediate damage, but they can pay off through gold, story flags, or stronger long-term rewards. For example, `Rescue Corridor` currently costs 1, grants 6 Block, and immediately gives 10 Gold."},
	"codex.term_overload_title": {"zh": "过载（Overload）", "en": "Overload"},
	"codex.term_overload_body": {"zh": "过载不是单独一个状态图标，而是一种高风险打法。你会用自伤、少抽牌或节奏损失，去换更高的术式爆发。当前原型里最直接的例子是：`Burn Will` 会失去 4 点生命换 3 点意志，`Overclock Arts` 会先打出 16 点术式伤害，再失去 3 点生命。", "en": "Overload is not a single status icon but a high-risk play pattern. You trade self-damage, reduced draw, or tempo loss for stronger Arts bursts. In the current prototype, the clearest examples are `Burn Will`, which trades 4 HP for 3 Will, and `Overclock Arts`, which deals 16 Arts damage and then costs 3 HP."},
	"codex.term_exhaust_title": {"zh": "消耗（Exhaust）", "en": "Exhaust"},
	"codex.term_exhaust_body": {"zh": "带有消耗的牌在本场战斗里打出后会进入消耗堆，不会再回到弃牌堆循环。它们往往是一次性的大效果。", "en": "A card with Exhaust goes to the exhaust pile after being played and will not cycle back during that battle. These cards are usually powerful one-shot effects."},
	"codex.term_ethereal_title": {"zh": "飘忽（Ethereal）", "en": "Ethereal"},
	"codex.term_ethereal_body": {"zh": "带有飘忽的牌如果回合结束时还留在手里，也会直接消失。常见于诅咒或一些限时机会牌。", "en": "A card with Ethereal disappears if it is still in your hand at the end of the turn. This often appears on curses or time-sensitive opportunity cards."},
	"codex.term_energy_title": {"zh": "能量（Energy）", "en": "Energy"},
	"codex.term_energy_body": {"zh": "每回合打牌都要花能量。阿米娅的基础能量是 3；如果带着 `Reserve Battery`，第一回合会变成 4。`Command Sync` 会返还 1 点能量，`Field Command Badge` 还会让每回合第一次支援额外返还 1 点。", "en": "Playing cards costs Energy. Amiya's base Energy is 3; with `Reserve Battery`, turn one becomes 4. `Command Sync` refunds 1 Energy, and `Field Command Badge` makes the first Support each turn refund another 1."},
	"codex.term_strain_title": {"zh": "精神负荷（Strain）", "en": "Mental Strain"},
	"codex.term_strain_body": {"zh": "精神负荷不是单独的状态条，而是你为高爆发付出的实际代价。当前原型里它主要表现为 3 种东西：1. 直接掉生命，例如 `Burn Will` -4 生命、`Overclock Arts` -3 生命、W 规则下每打出第 3 张牌自伤 2。2. 失去意志，例如 `Hesitation` 留手回合结束 -1 意志。3. 节奏惩罚，例如 `Panic Static` 让第一张牌费用 +1。", "en": "Mental Strain is not a separate meter but the real cost you pay for high burst turns. In the current prototype it appears in three main forms: 1. direct HP loss, such as `Burn Will` for -4 HP, `Overclock Arts` for -3 HP, and W's rule dealing 2 self-damage every third card; 2. Will loss, such as `Hesitation` causing -1 Will if left in hand; and 3. tempo penalties, such as `Panic Static` making your first card cost +1."},
	"quit.title": {"zh": "退出游戏", "en": "Quit Game"},
	"quit.body": {"zh": "确定要退出游戏吗？", "en": "Are you sure you want to quit the game?"},
	"quit.hint": {"zh": "如果现在不想退出，也可以返回主菜单继续操作。", "en": "If you do not want to quit right now, you can return to the main menu instead."},
	"quit.confirm": {"zh": "退出游戏", "en": "Quit Game"},
	"quit.cancel": {"zh": "返回主菜单", "en": "Back to Main Menu"},
	"defeat.title": {"zh": "行动失败", "en": "Operation Failed"},
	"defeat.body": {"zh": "阿米娅与小队被迫撤离，本次行动到此结束。", "en": "Amiya and the squad are forced to withdraw. The operation ends here."},
	"defeat.summary": {"zh": "终止于第 %d 层\n累计金币：%d\n剩余卡组张数：%d", "en": "Stopped on floor %d\nGold collected: %d\nDeck size: %d"},
	"defeat.retry": {"zh": "返回主菜单", "en": "Return to Main Menu"},
	"defeat.preview_title": {"zh": "作战回收", "en": "After Action Recovery"},
	"defeat.preview_body": {"zh": "下一次行动可以重新整理构筑，再次出发。", "en": "You can regroup and begin a new run from the main menu."},
	"victory.title": {"zh": "行动成功", "en": "Operation Cleared"},
	"victory.body": {"zh": "阿米娅带领小队完成了这次远征。无论你是否继续进入隐藏层，这一局都已经算正式通关。", "en": "Amiya led the squad through the expedition. Whether or not you continue into the hidden floor, this run already counts as a clear."},
	"victory.summary": {"zh": "抵达第 %d 层\n累计金币：%d\n最终卡组：%d 张\n模块数量：%d", "en": "Reached floor %d\nGold collected: %d\nFinal deck size: %d\nModules: %d"},
	"victory.back": {"zh": "返回主菜单", "en": "Back to Main Menu"},
	"victory.hint": {"zh": "主菜单里仍然可以继续查看百科、继续游戏或重新开局。", "en": "From the main menu, you can still open the codex, continue, or start a new run."},
	"map.header": {"zh": "第 %d 层 | %s", "en": "Floor %d | %s"},
	"map.status": {"zh": "生命 %d/%d   金币 %d   卡组 %d   模块 %d", "en": "HP %d/%d   Gold %d   Deck %d   Modules %d"},
	"map.hero_chip": {"zh": "Amiya", "en": "Amiya"},
	"map.hud_hp": {"zh": "生命 %d/%d", "en": "HP %d/%d"},
	"map.hud_gold": {"zh": "金币 %d", "en": "Gold %d"},
	"map.hud_deck": {"zh": "卡组 %d", "en": "Deck %d"},
	"map.hud_modules": {"zh": "模块 %d", "en": "Modules %d"},
	"map.hud_floor": {"zh": "第 %d 层", "en": "Floor %d"},
	"map.complete": {"zh": "当前路线已完成，返回主菜单。", "en": "The route is complete. Return to the main menu."},
	"map.current_node": {"zh": "当前节点：%s", "en": "Current node: %s"},
	"map.enter": {"zh": "进入节点", "en": "Enter Node"},
	"map.route": {"zh": "后续路线：%s", "en": "Upcoming route: %s"},
	"map.pick_route": {"zh": "请选择一条可到达的路线节点。完成节点后会回到地图继续选路。", "en": "Choose a reachable route node. After each node, you will return to the map to choose again."},
	"map.legend_title": {"zh": "图例", "en": "Legend"},
	"map.legend_sheet": {"zh": "E 敌人\nEL 精英\n? 事件\nR 休息\n$ 商店\nB Boss", "en": "E Enemy\nEL Elite\n? Event\nR Rest\n$ Shop\nB Boss"},
	"map.legend": {"zh": "图例：普通战适合稳步推进；事件更偏剧情与抉择；商店能调卡组；精英风险高但回报更好。层间休整会在首领战后强制出现。", "en": "Legend: Battle nodes are safer progress, Events focus on story and choices, Shop tunes the deck, and Elite is riskier with better rewards. Inter-floor rest is forced after bosses."},
	"map.state_available": {"zh": "可前往", "en": "Available"},
	"map.state_locked": {"zh": "未连通", "en": "Locked"},
	"map.state_done": {"zh": "已完成", "en": "Cleared"},
	"battle.player_stats": {"zh": "阿米娅  生命 %d/%d   护盾 %d   能量 %d   意志 %d", "en": "Amiya  HP %d/%d   Block %d   Energy %d   Will %d"},
	"battle.hud_hp": {"zh": "生命 %d/%d", "en": "HP %d/%d"},
	"battle.hud_gold": {"zh": "金币 %d", "en": "Gold %d"},
	"battle.hud_draw": {"zh": "抽牌堆 %d", "en": "Draw %d"},
	"battle.hud_discard": {"zh": "弃牌堆 %d", "en": "Discard %d"},
	"battle.hud_floor": {"zh": "第 %d 层", "en": "Floor %d"},
	"battle.hud_turn": {"zh": "回合 %d", "en": "Turn %d"},
	"battle.inspect_draw": {"zh": "查看当前抽牌堆", "en": "Inspect draw pile"},
	"battle.inspect_discard": {"zh": "查看当前弃牌堆", "en": "Inspect discard pile"},
	"battle.draw_pile_title": {"zh": "抽牌堆总览", "en": "Draw Pile"},
	"battle.discard_pile_title": {"zh": "弃牌堆总览", "en": "Discard Pile"},
	"battle.energy_orb": {"zh": "能量\n%d/%d", "en": "Energy\n%d/%d"},
	"battle.combat_info": {"zh": "回合 %d   当前目标：%s   领袖加成：%s", "en": "Turn %d   Target: %s   Leader Buff: %s"},
	"battle.enemy_panel": {"zh": "%s\n生命 %d/%d  护盾 %d\n意图：%s", "en": "%s\nHP %d/%d  Block %d\nIntent: %s"},
	"battle.targeting": {"zh": "当前目标：%s", "en": "Targeting %s"},
	"battle.target_none": {"zh": "无", "en": "None"},
	"battle.buff_ready": {"zh": "已就绪", "en": "Ready"},
	"battle.buff_idle": {"zh": "未触发", "en": "Inactive"},
	"battle.end_turn": {"zh": "结束回合", "en": "End Turn"},
	"battle.status_will": {"zh": "意志 %d\n当前意志会让“回响导流”额外 +%d 伤害；若意志达到 4 点以上，“谐振爆发”额外 +%d 伤害。", "en": "Will %d\nCurrent Will adds +%d damage to Echo Conduit. At 4+ Will, Resonance Burst gains +%d damage."},
	"battle.status_leader_ready": {"zh": "领袖加成已就绪\n你本回合第一次打出支援牌后，下一张术式牌固定 +2 伤害。", "en": "Leader buff ready\nAfter your first Support this turn, the next Arts card gains +2 damage."},
	"battle.status_weak": {"zh": "虚弱 %d\n该单位造成的伤害减少 25%。通常会在完成下一次行动后减少 1 层。", "en": "Weak %d\nThis unit deals 25% less damage. It usually loses 1 stack after its next action."},
	"battle.status_vulnerable": {"zh": "易伤 %d\n该单位受到的伤害增加 50%。通常会在完成下一次行动后减少 1 层。", "en": "Vulnerable %d\nThis unit takes 50% more damage. It usually loses 1 stack after its next action."},
	"battle.status_strength": {"zh": "力量 %d\n该单位造成伤害时额外 +%d。", "en": "Strength %d\nThis unit deals +%d extra damage."},
	"battle.invalid_state": {"zh": "当前没有有效的战斗状态，正在返回上一级页面。", "en": "No valid battle state was found. Returning to the previous screen."},
	"event.empty_title": {"zh": "安静的走廊", "en": "Quiet Corridor"},
	"event.empty_body": {"zh": "这里没有发生特别的事情。", "en": "Nothing meaningful happens here."},
	"event.continue": {"zh": "继续", "en": "Continue"},
	"reward.title": {"zh": "奖励", "en": "Reward"},
	"reward.body_default": {"zh": "为下一场作战选择一项战术收益。", "en": "Choose a tactical gain for the next operation."},
	"reward.body_elite": {"zh": "精英战斩获更丰富的战利品。本次奖励至少包含一张高阶战术卡。", "en": "Elite encounters yield richer loot. This reward includes at least one higher-tier tactical card."},
	"reward.body_elite_double": {"zh": "精英战大获全胜。本次奖励至少包含一张高阶战术卡，并且有机会带走两张牌。", "en": "A major elite victory. This reward includes at least one higher-tier tactical card and may let you keep two cards."},
	"reward.pick_remaining": {"zh": "还可选择 %d / %d 张牌。", "en": "%d / %d card picks remaining."},
	"reward.continue": {"zh": "继续", "en": "Continue"},
	"reward.skip": {"zh": "跳过奖励", "en": "Skip Reward"},
	"rest.info": {"zh": "罗德岛临时休整点会让小队完全恢复生命值。每层结算后都会强制进行一次整备，再进入下一层。", "en": "A Rhodes Island rest point fully restores the squad. One full regroup is forced between floors before the next deployment."},
	"shop.info": {"zh": "原型商店：花费 40 金币移除一张牌，或花费 50 金币购买一个模块。", "en": "Prototype shop: spend 40 gold to remove a card, or 50 gold to buy a module."},
	"shop.removed": {"zh": "已从卡组中移除一张基础牌。", "en": "A basic card has been removed from the deck."},
	"shop.bought": {"zh": "已获得模块：信号增幅器。", "en": "Module acquired: Signal Booster."},
	"battle.log.start": {"zh": "作战开始。阿米娅接管指挥。", "en": "Operation starts. Amiya takes command."},
	"battle.log.countdown": {"zh": "爆破倒计时触发，受到 8 点伤害。", "en": "Blast Countdown detonates for 8 damage."},
	"battle.log.curse": {"zh": "%s 向你的卡组塞入了一张诅咒。", "en": "%s pollutes the deck with a curse."},
	"battle.log.disrupt": {"zh": "%s 扰乱了阵型，你的下一张牌费用提高。", "en": "%s disrupts formation and taxes the next play."},
	"battle.log.enemy_idle": {"zh": "敌人没有采取行动。", "en": "Enemy did nothing."},
	"battle.log.panic": {"zh": "恐慌杂音生效，本回合第一张牌费用增加。", "en": "Panic Static increases the first card cost this turn."},
	"battle.log.leader_ready": {"zh": "阿米娅调整了队伍节奏，下一张术式会更强。", "en": "Amiya syncs the squad's tempo. The next Arts card is empowered."},
	"battle.log.will": {"zh": "意志 +%d", "en": "Will +%d"},
	"battle.log.damage": {"zh": "造成 %d 点伤害", "en": "Damage %d"},
	"battle.log.damage_detail": {"zh": "%s 对 %s 造成了 %d 点伤害。", "en": "%s dealt damage to %s for %d."},
	"battle.intent_attack_tooltip": {"zh": "%s\n预估打击：%d\n当前护盾吸收：%d\n实际掉血：%d", "en": "%s\nProjected hit: %d\nBlocked now: %d\nHP loss now: %d"},
	"battle.intent_curse_tooltip": {"zh": "%s\n将施加诅咒或牌组干扰。", "en": "%s\nWill apply a curse or deck disruption."},
	"battle.intent_rule_tooltip": {"zh": "%s\n将改变下一回合的战场规则。", "en": "%s\nWill alter the next turn's battlefield rule."},
	"battle.intent_other_tooltip": {"zh": "%s\n这是一个特殊行动。", "en": "%s\nThis is a special action."},
	"battle.log.auto_end": {"zh": "没有可继续打出的牌了，回合自动结束。", "en": "No more playable cards. Ending turn automatically."},
	"battle.log.scan": {"zh": "脉冲扫描看到：%s", "en": "Pulse Scan sees: %s"},
	"battle.log.w_hand": {"zh": "W 扭曲了战场。下一次抽牌手牌上限变为 4。", "en": "W twists the field. Hand size drops to 4 for the next draw."},
	"battle.log.w_tax": {"zh": "W 制造迟疑。下一回合第一张牌费用 +1。", "en": "W forces hesitation. The next first card costs +1."},
	"battle.log.w_shift": {"zh": "在 W 的压力下，战场规则发生了变化。", "en": "The battlefield shifts under W's pressure."},
	"battle.log.w_third": {"zh": "W 惩罚了你的第三张牌，你受到 2 点自伤。", "en": "W punishes the third card with 2 self damage."}
}

var node_type_names := {
	"battle": {"zh": "普通战", "en": "Battle"},
	"elite": {"zh": "精英战", "en": "Elite"},
	"boss": {"zh": "首领战", "en": "Boss"},
	"event": {"zh": "事件", "en": "Event"},
	"story": {"zh": "剧情", "en": "Story"},
	"rest": {"zh": "休整", "en": "Rest"},
	"shop": {"zh": "商店", "en": "Shop"}
}

var floor_names := {
	1: {"zh": "失序街区", "en": "Disorder District"},
	2: {"zh": "封锁城区", "en": "Lockdown Sector"},
	3: {"zh": "余烬回廊", "en": "Ember Corridor"},
	4: {"zh": "灰烬真相", "en": "Ash Truth"}
}

var node_descriptions := {
	"battle": {"zh": "普通战斗节点。适合稳步推进构筑。", "en": "A standard combat node. Good for steady deck growth."},
	"elite": {"zh": "精英战节点。压力更高，但奖励更好。", "en": "A high-pressure elite encounter with better rewards."},
	"boss": {"zh": "首领战节点。本层的关键决战。", "en": "A decisive confrontation that closes the floor."},
	"event": {"zh": "事件节点。你的选择会影响生命、金币、卡牌、模块与剧情标记。", "en": "A narrative choice node that changes HP, gold, cards, modules, and flags."},
	"story": {"zh": "剧情节点。与阿米娅的承担和局势走向有关。", "en": "A heavier story beat tied to Amiya's burden."},
	"rest": {"zh": "休整节点。恢复状态并准备下一场作战。", "en": "Recover and regroup before the next battle."},
	"shop": {"zh": "商店节点。使用金币换取更稳定的构筑。", "en": "Spend gold to improve deck quality or stability."}
}

var card_text := {
	"arts_bolt": {"zh_name": "术式击", "zh_desc": "造成 6 点术式伤害。"},
	"barrier_formula": {"zh_name": "屏障公式", "zh_desc": "获得 5 点护盾。"},
	"mind_alignment": {"zh_name": "精神校准", "zh_desc": "抽 2 张牌。获得 1 点意志。"},
	"tactical_reorder": {"zh_name": "战术重整", "zh_desc": "抽 2 张牌。若本回合打出过术式牌，获得 1 点意志。"},
	"focus_pulse": {"zh_name": "聚焦脉冲", "zh_desc": "造成 7 点术式伤害。若本回合打出过支援牌，再 +3。"},
	"emergency_shield": {"zh_name": "应急护盾", "zh_desc": "获得 9 点护盾。"},
	"resonance_burst": {"zh_name": "谐振爆发", "zh_desc": "造成 12 点术式伤害。若意志达到 4 以上，再 +4。"},
	"command_sync": {"zh_name": "指挥同步", "zh_desc": "返还 1 点能量，并触发支援联动。"},
	"signal_relay": {"zh_name": "信号中继", "zh_desc": "从抽牌堆或弃牌堆取回一张支援牌。"},
	"guided_fire": {"zh_name": "引导火力", "zh_desc": "造成两次 5 点术式伤害。"},
	"rescue_corridor": {"zh_name": "救援通道", "zh_desc": "获得 6 点护盾，并额外获得 10 金币。"},
	"discipline_note": {"zh_name": "纪律笔记", "zh_desc": "获得 1 点意志并抽 1 张牌。"},
	"pulse_scan": {"zh_name": "脉冲扫描", "zh_desc": "查看抽牌堆顶 3 张牌。"},
	"burn_will": {"zh_name": "燃烧意志", "zh_desc": "失去 4 点生命，获得 3 点意志。"},
	"overclock_arts": {"zh_name": "过载术式", "zh_desc": "造成 16 点术式伤害，并承受强烈反噬。"},
	"tactical_calm": {"zh_name": "战术冷静", "zh_desc": "抽 2 张牌。所有敌人获得虚弱。"},
	"echo_conduit": {"zh_name": "回响导流", "zh_desc": "造成 10 点术式伤害。每 1 点意志额外 +1，最多 +6。"},
	"hesitation": {"zh_name": "迟疑", "zh_desc": "无法打出。回合结束时若仍在手中，失去 1 点意志。"},
	"panic_static": {"zh_name": "恐慌杂音", "zh_desc": "无法打出。抽到时本回合第一张牌费用 +1。"},
	"blast_countdown": {"zh_name": "爆破倒计时", "zh_desc": "若本回合未处理，回合结束时受到 8 点伤害。"}
}

var module_text := {
	"ashen_thread": {"zh_name": "灰烬丝线", "zh_desc": "每次主动自伤后，你的下一张术式牌额外造成 3 点伤害。"},
	"field_command_badge": {"zh_name": "战地指挥徽章", "zh_desc": "每回合第一次支援联动会返还 1 点能量。"},
	"field_medic_pack": {"zh_name": "战地医疗包", "zh_desc": "每场战斗开始时恢复 4 点生命。"},
	"nearl_crest": {"zh_name": "临光护徽", "zh_desc": "每场战斗的第一回合获得 8 点护盾。"},
	"reserve_battery": {"zh_name": "备用电池", "zh_desc": "每场战斗第一回合额外获得 1 点能量。"},
	"rhodes_tactical_console": {"zh_name": "罗德岛战术终端", "zh_desc": "代表罗德岛级别的指挥权限，并计入隐藏路线条件。"},
	"signal_booster": {"zh_name": "信号增幅器", "zh_desc": "每场战斗打出的第一张支援牌额外抽 1 张牌。"}
}

var enemy_text := {
	"reunion_scout": {"zh_name": "整合运动侦察兵"},
	"reunion_caster": {"zh_name": "整合运动术师"},
	"riot_shieldbearer": {"zh_name": "暴乱持盾者"},
	"crossbow_sniper": {"zh_name": "弩手狙击兵"},
	"field_captain": {"zh_name": "整合运动战地队长"},
	"originium_channeler": {"zh_name": "源石导流者"},
	"scout_chief": {"zh_name": "战术侦察领袖"},
	"lockdown_core": {"zh_name": "纯粹源石"},
	"w_boss": {"zh_name": "W"}
	,
	"ash_echo": {"zh_name": "灰烬回响"}
}

var intent_labels := {
	"Rush 6": {"zh": "突袭 6", "en": "Rush 6"},
	"Slash 8": {"zh": "斩击 8", "en": "Slash 8"},
	"Arts Bolt 5": {"zh": "术式飞弹 5", "en": "Arts Bolt 5"},
	"Static Distortion": {"zh": "静电干扰", "en": "Static Distortion"},
	"Snipe 9": {"zh": "狙击 9", "en": "Snipe 9"},
	"Volley 6": {"zh": "齐射 6", "en": "Volley 6"},
	"Command Strike 11": {"zh": "指挥打击 11", "en": "Command Strike 11"},
	"Suppress Formation": {"zh": "压制阵型", "en": "Suppress Formation"},
	"Breakthrough 13": {"zh": "突破 13", "en": "Breakthrough 13"},
	"Lockdown Slam 12": {"zh": "封锁重击 12", "en": "Lockdown Slam 12"},
	"Barrier Fire 10": {"zh": "屏障火力 10", "en": "Barrier Fire 10"},
	"Containment Pulse": {"zh": "封控脉冲", "en": "Containment Pulse"},
	"Crush 8": {"zh": "重击 8", "en": "Crush 8"},
	"Bash 7": {"zh": "盾击 7", "en": "Bash 7"},
	"Originium Pulse 10": {"zh": "源石脉冲 10", "en": "Originium Pulse 10"},
	"Shatter Beam 14": {"zh": "碎裂射线 14", "en": "Shatter Beam 14"},
	"Chief's Strike 11": {"zh": "首领打击 11", "en": "Chief's Strike 11"},
	"Signal Jam": {"zh": "信号干扰", "en": "Signal Jam"},
	"Coordinated Push 14": {"zh": "协同推进 14", "en": "Coordinated Push 14"},
	"Plant Bomb": {"zh": "埋设炸弹", "en": "Plant Bomb"},
	"Explosive Volley": {"zh": "爆炸齐射", "en": "Explosive Volley"},
	"Mock and Disrupt": {"zh": "嘲弄与扰乱", "en": "Mock and Disrupt"},
	"Ash Rule: Hand Limit -1": {"zh": "灰烬规则：手牌上限 -1", "en": "Ash Rule: Hand Limit -1"},
	"Ash Rule: First Card +1": {"zh": "灰烬规则：首张牌费用 +1", "en": "Ash Rule: First Card +1"},
	"Focused Demolition": {"zh": "定点爆破", "en": "Focused Demolition"},
	"Unknown": {"zh": "未知", "en": "Unknown"}
}

var event_text := {
	"temporary_ward": {
		"zh_title": "临时病房",
		"zh_body": "这地方原本像是个小店，现在临时收拾成了病房。破帘子挂在歪掉的货架上，灯也不够亮，照得人脸色都发白。药剂一支支摆在木箱上，可再摆整齐也不会凭空多出来。\n\n躺着的人里有刚从骚乱里拖回来的平民，也有还惦记着想站回前线的罗德岛干员。阿米娅听着医疗汇报，目光却老往街外飘。她心里很清楚，下一场麻烦随时会来，可你们手上的东西，救不了所有人。\n\n现在就看你怎么选了。花点钱把病房先稳住，今晚大概能多留下几个人。平均分，听起来公平，但谁都拿不到足够的量。要是把药全留给前线，那下一场会轻松些，可这地方留下来的安静，也不会那么快过去。"
	},
	"dobermann_inspection": {
		"zh_title": "杜宾的检查",
		"zh_body": "队伍刚喘口气，杜宾就把人叫停了，说要看看你现在这套构筑。她翻牌的表情，跟检查一把保养没做好的武器差不多，越看眉头越紧。\n\n在她眼里，犹豫就是拖后腿，不够果断就是纪律出问题。她不在乎一张牌看起来是不是“温和”，她只在乎真到局面崩的时候，这套东西顶不顶得住。阿米娅没顶嘴，但那话听着显然不轻。\n\n杜宾把路说得很直白。要么砍掉软的，牌组收紧一点。要么干脆更凶一点，别老想着两头都顾。再不然，就别说了，带着这点不舒服继续往前走。"
	},
	"nearl_principle": {
		"zh_title": "临光的原则",
		"zh_body": "临光在一处塌掉的检查口前停了下来。被困的人就在歪掉的护栏和翻倒的车后面。要是只看效率，现在最省事的做法当然是继续推进，先把任务做完再说。\n\n可临光不认这个。她说得很平静，但意思一点都不含糊: 如果罗德岛因为救人太麻烦、太费代价，就干脆不救，那迟早会把更重要的东西也一起丢掉。她声音不大，可每个字都压得很实。\n\n阿米娅一听就知道，这事没有谁是真错的，这才最难办。站临光这边，就得拿血量和节奏去换。优先任务，行动会更利索，但也会更冷。折中听着聪明，其实只是把账先往后压。"
	},
	"kaltsit_briefing": {
		"zh_title": "凯尔希的简报",
		"zh_body": "下一轮部署前，凯尔希把更新过的简报送来了。她说话还是老样子，平得像在念病历，可意思很清楚: 这片城区现在越来越难猜了，闭着眼往前冲，后面多半要吃更大的亏。\n\n她也没替阿米娅拍板，只是把几条路摆出来。想稳一点，就先把路线情报摸清。想把节奏放平，就走更冷静的打法。要是愿意吃点眼前的亏，也能换一条更稀有、更专门的支援线。\n\n凯尔希不用把话说得很重。她只要把事实摆那儿，剩下的压力自然就落到你们头上了。"
	},
	"ws_broadcast": {
		"zh_title": "W 的广播",
		"zh_body": "无线电突然炸了一下，刺啦刺啦响完，W 那种让人想皱眉的笑声就冒出来了。她在附近，或者她就是想让你觉得她在附近。反正她挺喜欢把战场搞成她自己的表演场。\n\n这段广播不只是单纯挑衅。里头还夹着路线碎片、爆炸触发、半真半假的诱饵，摆明了是在勾你踩进她准备好的节奏里。阿米娅没说话，队里其他人也都在等，看你是准备追过去、拆情报，还是干脆不接她这茬。\n\nW 说的话不能全信，但也不是一句都没用。追信号，就是往她想要的危险里走。慢慢拆模式，也许能让她之后没那么难猜。直接转身走人，眼前是省事了，可说不定也把什么更值钱的东西一起放跑了。"
	}
}

var event_result_text := {
	"The lamps stay lit long enough for the ward to breathe again. Fewer voices are lost tonight, and the squad remembers that Rhodes Island chose to protect before it chose to advance.": "病房总算先稳住了，今晚多留住了几个人。队里的人也都看得很清楚，这一次罗德岛先顾的是人，不是推进。",
	"You spread the shortage across everyone and buy time rather than certainty. The ward does not collapse, but the whole operation carries that compromise into the next fights.": "你把东西尽量分开了，谁都沾上一点，可谁也拿不到够用的量。病房没当场垮掉，但这口气，其实是从后面的战斗里借出来的。",
	"The frontline receives what it needs, and your readiness sharpens immediately. The cost is harder to name: a pause in Amiya's voice, and a hesitation that settles into the deck like dust.": "前线这边一下轻松了不少，准备也跟着顺了。可代价不是没有，只是没那么好说出口，最后变成阿米娅说话时那一下停顿，还有牌组里怎么都甩不掉的一点迟疑。",
	"The training is brutal and efficient. A softer habit is cut away, and what remains feels narrower, sharper, and more dependable under pressure.": "这轮训练一点都不客气，但确实有用。牌组里那些偏软的地方被直接砍掉了，剩下来的东西更紧，也更顶得住压力。",
	"You refuse to become smaller just to become cleaner. Dobermann does not approve, but even she cannot deny the deck now bites harder when it commits.": "你没打算为了好看就把自己收得太死。杜宾嘴上不认，可这套牌现在真出手的时候，确实更狠了。",
	"You let the inspection end without a real answer. Nothing breaks immediately, but the hesitation to commit leaves the next deployment feeling a little heavier.": "这事就这么被你糊过去了，当下倒也没出什么问题。只是那点没说开的东西，会让下一次出发时心里更沉一点。",
	"The civilians are extracted under pressure and the squad pays for every meter. It is not an efficient victory, but it is one Amiya can look at directly.": "人是救出来了，但每往前一点都是真拿代价换的。这不算什么漂亮仗，不过阿米娅至少能正眼看着这个结果。",
	"The objective remains intact and your resources stay stable. Even so, the space left behind by those you did not stop for follows the squad long after the road is clear.": "任务保住了，资源也没乱。可那些你没停下来救的人留下的空白，不会因为路清出来了就跟着消失。",
	"The crisis moves, not resolves, and the price of that compromise waits further ahead.": "你把这事先按住了，看着像是折中过去了。可账并没有真消掉，只是往后拖了。",
	"The report is broken down, cross-checked, and turned into something the squad can actually use. The road ahead does not become safe, but it becomes readable.": "这份简报总算被理顺了，至少不再是一堆冷冰冰的字。前面还是危险，但起码没那么摸不着头脑了。",
	"The squad adjusts its breathing, pacing, and timing around a calmer operational line. The coming fights will still hurt, but they will hurt on terms you understand better.": "队伍节奏慢慢稳下来了，呼吸和步调都顺了不少。后面的仗还是难打，但至少不会乱成一团。",
	"You accept a sharper trade: less tempo now for a more precise support pattern later. Kal'tsit gives no praise, only the brief nod that passes for approval.": "你先吃一点眼前的亏，换后面更顺手的支援节奏。凯尔希没多说什么，就点了下头，算是认了。",
	"You answer W by moving toward the danger instead of away from it. The squad returns with sharper tools and rattled nerves, as if strength had been pried from the blast radius itself.": "你没躲，反而顺着 W 留下的味道追了过去。人回来时都还有点发紧，但手里确实多了点硬东西。",
	"You treat the transmission like a puzzle instead of a threat and peel back part of its design. W is still dangerous, but she becomes just a little less unknowable.": "你没急着跟她硬碰，而是先把这段广播拆开来看。W 还是危险，可至少没之前那么让人摸不透了。",
	"You deny W the performance she wants and keep the squad intact for now. Still, the sense that an opportunity was left in the smoke lingers longer than anyone says aloud.": "你没顺着 W 的意思陪她演，队伍也算完整地撤了下来。只是那种“好像错过了点什么”的感觉，还是一直吊在心里。"
}

func _ready() -> void:
	var profile: Dictionary = SaveManager.load_profile()
	current_language = String(profile.get("language", LANG_ZH))

func set_language(language_code: String) -> void:
	current_language = language_code
	var profile: Dictionary = SaveManager.load_profile()
	profile["language"] = current_language
	SaveManager.save_profile(profile)
	language_changed.emit(current_language)

func text(key: String, format_args: Array = []) -> String:
	var entry: Dictionary = ui_text.get(key, {})
	var raw: String = String(entry.get(current_language, key))
	return raw % format_args if not format_args.is_empty() else raw

func card_name(card: CardData) -> String:
	if current_language == LANG_ZH and card_text.has(card.id):
		return String(card_text[card.id].get("zh_name", card.display_name))
	return card.display_name

func card_description(card: CardData) -> String:
	if current_language == LANG_ZH and card_text.has(card.id):
		return String(card_text[card.id].get("zh_desc", card.description))
	return card.description

func module_name(module_data: ModuleData) -> String:
	if current_language == LANG_ZH and module_text.has(module_data.id):
		return String(module_text[module_data.id].get("zh_name", module_data.display_name))
	return module_data.display_name

func module_description(module_data: ModuleData) -> String:
	if current_language == LANG_ZH and module_text.has(module_data.id):
		return String(module_text[module_data.id].get("zh_desc", module_data.description))
	return module_data.description

func rarity_name(rarity: String) -> String:
	match rarity:
		"Common":
			return text("codex.rarity_common")
		"Elite":
			return text("codex.rarity_elite")
		"Rare":
			return text("codex.rarity_rare")
	return rarity

func enemy_tag_name(tag: String) -> String:
	match tag:
		"Reunion":
			return text("codex.tag_reunion")
		"Ranged":
			return text("codex.tag_ranged")
		"Arts":
			return text("codex.tag_arts")
		"Guard":
			return text("codex.tag_guard")
		"Boss":
			return text("codex.tag_boss")
		"Elite":
			return text("codex.tag_elite")
		"Siege":
			return text("codex.tag_siege")
	return tag

func ai_profile_name(ai_profile: String) -> String:
	match ai_profile:
		"basic":
			return text("codex.ai_basic")
		"w_boss":
			return text("codex.ai_w_boss")
	return ai_profile

func enemy_name(enemy_id: String, fallback: String) -> String:
	if current_language == LANG_ZH and enemy_text.has(enemy_id):
		return String(enemy_text[enemy_id].get("zh_name", fallback))
	return fallback

func intent_label(label: String) -> String:
	var entry: Dictionary = intent_labels.get(label, {})
	return String(entry.get(current_language, label))

func event_title(event_id: String, fallback: String) -> String:
	if current_language == LANG_ZH and event_text.has(event_id):
		return String(event_text[event_id].get("zh_title", fallback))
	return fallback

func event_body(event_id: String, fallback: String) -> String:
	if current_language == LANG_ZH and event_text.has(event_id):
		return String(event_text[event_id].get("zh_body", fallback))
	return fallback

func event_result(result_text: String) -> String:
	if current_language == LANG_ZH:
		return String(event_result_text.get(result_text, result_text))
	return result_text

func node_type_name(node_type: String) -> String:
	var entry: Dictionary = node_type_names.get(node_type, {})
	return String(entry.get(current_language, node_type))

func floor_name(floor_index: int) -> String:
	var entry: Dictionary = floor_names.get(floor_index, {})
	return String(entry.get(current_language, text("map.header")))

func node_description(node_type: String) -> String:
	var entry: Dictionary = node_descriptions.get(node_type, {})
	return String(entry.get(current_language, node_type))
