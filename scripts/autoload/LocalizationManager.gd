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
	"single.amiya_will": {"zh": "特有机制：意志（Will）\n意志是阿米娅的专属资源。部分卡牌会积累意志，意志越高，她的高阶术式就越强，像终结牌和爆发牌都会随着意志提升伤害。\n但意志并不是越高越好：它代表精神负荷与承担的代价，部分牌会消耗意志，某些过载打法还会带来自伤或节奏风险。简单来说，意志就是阿米娅在战斗中把「责任」转化为力量的核心系统。", "en": "Signature Mechanic: Will\nWill is Amiya's exclusive resource. Several cards build Will, and the more Will she has, the stronger her advanced Arts become. Finishers and burst spells scale directly with it.\nBut high Will comes with pressure: some cards spend it, and overload-style lines can cause self-damage or tempo loss. In short, Will is the system that turns Amiya's burden into combat power."},
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
	"codex.header_eyebrow": {"zh": "罗德岛战术档案", "en": "Rhodes Island Tactical Archive"},
	"codex.header_title": {"zh": "档案总览", "en": "Archive Overview"},
	"codex.header_body": {"zh": "这里集中整理你已经解锁的 %d 张卡牌、%d 个模块与 %d 种敌人资料，也会持续记录每一次行动的推进与选择。", "en": "This archive gathers %d unlocked cards, %d modules, and %d enemy records, while preserving the progress and choices from each operation."},
	"codex.header_cards_chip": {"zh": "卡牌 %d", "en": "Cards %d"},
	"codex.header_modules_chip": {"zh": "模块 %d", "en": "Modules %d"},
	"codex.header_monsters_chip": {"zh": "敌人 %d", "en": "Enemies %d"},
	"codex.header_history_chip": {"zh": "记录 %d", "en": "Records %d"},
	"codex.section_primary": {"zh": "核心档案", "en": "Core Archive"},
	"codex.section_secondary": {"zh": "作战记录与说明", "en": "Records and Reference"},
	"codex.cards": {"zh": "卡牌总览", "en": "Card Archive"},
	"codex.cards_body": {"zh": "查看你在行动中见过的卡牌。", "en": "Review cards discovered during runs."},
	"codex.modules": {"zh": "模块收藏", "en": "Module Vault"},
	"codex.modules_body": {"zh": "检视已获得的战术模块。", "en": "Inspect tactical modules you have found."},
	"codex.lab": {"zh": "药剂研究所", "en": "Field Lab"},
	"codex.lab_body": {"zh": "整理战场补给与实验记录。", "en": "Browse combat supplies and field experiments."},
	"codex.monsters": {"zh": "怪物图鉴", "en": "Enemy Archive"},
	"codex.monsters_body": {"zh": "查看已经记录下来的敌方立绘、数值与行动模式。", "en": "Review recorded enemy portraits, stats, and intent patterns."},
	"codex.stats": {"zh": "角色数据", "en": "Operator Data"},
	"codex.stats_body": {"zh": "查看阿米娅的作战统计。", "en": "View Amiya's run statistics."},
	"codex.history": {"zh": "历史记录", "en": "History"},
	"codex.history_body": {"zh": "回看已经完成的行动。", "en": "Revisit completed operations."},
	"codex.glossary": {"zh": "术语说明", "en": "Glossary"},
	"codex.glossary_body": {"zh": "解释战斗中会反复出现的核心术语。", "en": "Explain the core terms used throughout combat."},
	"codex.detail_cards": {"zh": "这里会逐步汇总你见过的牌组构件，方便回看卡牌路线和构筑方向。", "en": "This section will gather discovered cards so you can review archetypes and build paths."},
	"codex.detail_modules": {"zh": "这里会记录获得过的模块、它们的效果，以及哪些模块更适合阿米娅当前的构筑。", "en": "This section will track found modules, their effects, and which ones best fit Amiya's current build."},
	"codex.detail_lab": {"zh": "这里预留给补给、药剂和战场实验记录，后续可以扩展成更完整的资源百科。", "en": "This area is reserved for supplies, potions, and field experiments as the prototype grows."},
	"codex.detail_monsters": {"zh": "这里会展示敌人的生命、奖励、行动模式与标签，方便你在跑图前快速回忆哪些敌人要优先处理。", "en": "This section shows enemy HP, rewards, move patterns, and tags so you can quickly remember which foes need priority handling."},
	"codex.detail_stats": {"zh": "角色数据会集中展示阿米娅的出战次数、胜率和常用构筑方向。", "en": "Operator data will highlight Amiya's runs, success rate, and common build directions."},
	"codex.detail_history": {"zh": "历史记录会保存最近几次行动的楼层推进、失败节点和最终收益。", "en": "History will preserve recent run progress, failure points, and rewards."},
	"codex.detail_glossary": {"zh": "这里会解释意志、虚弱、术式、支援、诅咒等战斗术语，方便第一次接触卡牌构筑时快速理解。", "en": "This section explains combat terms like Will, Weak, Arts, Support, and Curse so new players can parse the system faster."},
	"settings.preview_title": {"zh": "显示预览", "en": "Display Preview"},
	"settings.preview_body": {"zh": "右侧保留主视觉和说明，避免设置页完全没有图像。", "en": "The right panel keeps a hero image and preview text visible."},
	"overlay.close": {"zh": "关闭", "en": "Close"},
	"overlay.count": {"zh": "条目 %d", "en": "Entries %d"},
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
	"codex.ai_tank": {"zh": "重甲防线", "en": "Armored Tank"},
	"codex.ai_debuffer": {"zh": "战场干扰", "en": "Debuffer"},
	"codex.ai_caster": {"zh": "蓄力施术", "en": "Charge Caster"},
	"codex.tag_reunion": {"zh": "整合运动", "en": "Reunion"},
	"codex.tag_ranged": {"zh": "远程", "en": "Ranged"},
	"codex.tag_arts": {"zh": "术式", "en": "Arts"},
	"codex.tag_guard": {"zh": "重装近卫", "en": "Guard"},
	"codex.tag_boss": {"zh": "首领", "en": "Boss"},
	"codex.tag_elite": {"zh": "精英", "en": "Elite"},
	"codex.tag_siege": {"zh": "封锁装置", "en": "Siege"},
	"codex.term_will_title": {"zh": "意志（Will）", "en": "Will"},
	"codex.term_will_body": {"zh": "阿米娅的专属资源，上限 10。它不会自动让所有牌统一增伤，但会明确强化部分爆发术式：`Mind Alignment` 与 `Discipline Note` 各给 +1 意志，`Burn Will` 给 +3 意志；`Echo Conduit` 会额外获得「每 1 点意志 +1 伤害」，最多 +6；`Resonance Burst` 在意志达到 4 以上时额外 +4 伤害。意志越高，风险也越高，因为它经常和自伤、节奏损失或过载打法绑在一起。", "en": "Amiya's exclusive resource, capped at 10. It does not passively boost every card, but it clearly empowers some burst Arts: `Mind Alignment` and `Discipline Note` each grant +1 Will, `Burn Will` grants +3, `Echo Conduit` gains +1 damage per Will up to +6, and `Resonance Burst` gains +4 damage at 4+ Will. High Will also carries risk because it is often tied to self-damage, tempo loss, or overload lines."},
	"codex.term_arts_title": {"zh": "术式（Arts）", "en": "Arts"},
	"codex.term_arts_body": {"zh": "带有术式标签的牌会吃到阿米娅最核心的联动，也是她主要的伤害来源。当前原型里，阿米娅每回合第一次打出支援牌后，下一张术式牌固定 +2 伤害；如果带着 `Ashen Thread` 模块并且你刚刚自伤过，下一张术式还会再额外 +3。", "en": "Cards with the Arts tag benefit from Amiya's most important synergy and serve as her main damage source. In the current prototype, after Amiya plays her first Support each turn, her next Arts card gets a flat +2 damage. With `Ashen Thread`, the next Arts card after self-damage gains an additional +3."},
	"codex.term_support_title": {"zh": "支援（Support）", "en": "Support"},
	"codex.term_support_body": {"zh": "支援牌偏向抽牌、返还能量、调整节奏或找回关键牌。数值上最关键的是：阿米娅每回合第一次打出支援牌后，下一张术式固定 +2 伤害；如果装着 `Field Command Badge`，这第一次支援还会额外返还 1 点能量。", "en": "Support cards focus on draw, energy refunds, tempo control, or retrieving key tools. Numerically, the big payoff is this: after Amiya plays her first Support each turn, her next Arts card gets a flat +2 damage; with `Field Command Badge`, that first Support also refunds 1 extra Energy."},
	"codex.term_resonance_title": {"zh": "共振（Resonance）", "en": "Resonance"},
	"codex.term_resonance_body": {"zh": "共振是阿米娅牌组里另一条很核心的资源线，单个目标最多可叠到 9 层。它本身不会直接造成伤害，但很多牌会把共振转成爆发：`共振标记` 直接施加 3 层；`频锁` 施加 2 层；`频域崩塌` 会消耗目标全部共振，每层造成 3 点术式伤害；`嵌合协议` 还会把目标的每层共振转成 4 点术式伤害。简单说，共振就是你先挂在敌人身上、再择机一次性引爆的层数资源。", "en": "Resonance is another core resource line in Amiya's deck, capped at 9 stacks per target. It does not deal damage by itself, but many cards convert it into burst: `Resonance Mark` applies 3 stacks, `Frequency Lock` applies 2, `Collapse Frequency` consumes all stacks for 3 Arts damage each, and `Chimera Protocol` converts each stack into 4 Arts damage. In short, Resonance is a delayed layer resource that you stack first and detonate later."},
	"codex.term_echo_title": {"zh": "回响（Echo）", "en": "Echo"},
	"codex.term_echo_body": {"zh": "回响代表「下一张术式会额外触发一次部分效果」。当前原型里最常见的是 50%% Echo，也就是再触发一次基础效果的 50%%。`回响格` 会给予 50%% Echo；`七重回响` 会给接下来 2 张术式牌 50%% Echo；如果你有 `镜波`，带着 Echo 时还会再额外重复一次基础伤害。", "en": "Echo means your next Arts card repeats part of its effect. The most common form in the prototype is 50%% Echo, which repeats 50%% of the card's base effect. `Echo Lattice` grants 50%% Echo, `Sevenfold Echo` gives the next 2 Arts cards 50%% Echo, and `Mirrored Wave` repeats its base damage again if Echo is active."},
	"codex.term_block_title": {"zh": "护盾（Block）", "en": "Block"},
	"codex.term_block_body": {"zh": "护盾会先替你承受伤害，再扣生命。它是最直接的防御资源，适合拿来顶一轮爆发或者拖回合。", "en": "Block absorbs damage before HP is lost. It is the most direct defensive resource and helps you survive bursts or buy extra turns."},
	"codex.term_weak_title": {"zh": "虚弱（Weak）", "en": "Weak"},
	"codex.term_weak_body": {"zh": "带有虚弱的单位造成的伤害会乘以 0.75，也就是直接少 25%。当前原型里，1 层虚弱通常会持续到这个单位完成下一次行动为止，然后自动减掉 1 层。比如敌人原本打 8，挂上虚弱后会变成 6。", "en": "A unit with Weak deals damage at 0.75x, which means a direct 25% reduction. In the current prototype, 1 stack of Weak usually lasts until that unit finishes its next action, then decays by 1. For example, an attack that would deal 8 instead deals 6 under Weak."},
	"codex.term_vulnerable_title": {"zh": "易伤（Vulnerable）", "en": "Vulnerable"},
	"codex.term_vulnerable_body": {"zh": "带有易伤的单位会受到 1.5 倍伤害，也就是多吃 50%。当前原型里，如果某个单位挂着 1 层易伤，这层通常会在它完成下一次行动后自动减掉。比如原本 10 点伤害，打到易伤目标身上会变成 15。", "en": "A unit with Vulnerable takes 1.5x damage, or 50% more. In the current prototype, 1 stack usually decays after that unit completes its next action. For example, 10 damage becomes 15 against a Vulnerable target."},
	"codex.term_strength_title": {"zh": "力量（Strength）", "en": "Strength"},
	"codex.term_strength_body": {"zh": "力量会直接加到一个单位造成的伤害上。当前原型里，1 点力量就让每次攻击额外 +1 伤害；如果敌人头顶显示 8 点打击并且它有 2 点力量，结算时就会按 10 点去算，再继续套虚弱、易伤和护盾。", "en": "Strength adds directly to the damage a unit deals. In the current prototype, 1 Strength means +1 damage on each hit. If an enemy shows an 8-damage attack and has 2 Strength, it resolves from 10 before Weak, Vulnerable, and Block are applied."},
	"codex.term_curse_title": {"zh": "诅咒（Curse）", "en": "Curse"},
	"codex.term_curse_body": {"zh": "诅咒牌一般帮不上忙，只会塞进牌堆拖慢节奏，严重时还会直接带来惩罚。当前原型里：`Hesitation` 若回合结束还在手里会失去 1 点意志；`Panic Static` 抽到时会让你本回合第一张牌费用 +1；`Blast Countdown` 若回合结束还留在手里，会直接受到 8 点伤害。", "en": "Curse cards usually do not help and only clog the deck, slowing your tempo or directly causing penalties. In the current prototype: `Hesitation` makes you lose 1 Will if it remains in hand at end of turn, `Panic Static` makes your first card cost +1 when drawn, and `Blast Countdown` deals 8 damage if it is still in hand at end of turn."},
	"codex.term_rescue_title": {"zh": "救援（Rescue）", "en": "Rescue"},
	"codex.term_rescue_body": {"zh": "救援类牌和事件代表阿米娅把资源分出去救人。它们通常不会立刻打出最高伤害，但会换来金币、剧情标记或更好的长期收益。比如 `Rescue Corridor` 当前就是 1 费，给 6 点护盾并立即获得 10 金币。", "en": "Rescue cards and events represent Amiya diverting resources to save people. They usually do not create the biggest immediate damage, but they can pay off through gold, story flags, or stronger long-term rewards. For example, `Rescue Corridor` currently costs 1, grants 6 Block, and immediately gives 10 Gold."},
	"codex.term_overload_title": {"zh": "过载（Overload）", "en": "Overload"},
	"codex.term_overload_body": {"zh": "过载不是单独一个状态图标，而是一种高风险打法。你会用自伤、少抽牌或节奏损失，去换更高的术式爆发。当前原型里最直接的例子是：`Burn Will` 会失去 4 点生命换 3 点意志，`Overclock Arts` 会先打出 16 点术式伤害，再失去 3 点生命。", "en": "Overload is not a single status icon but a high-risk play pattern. You trade self-damage, reduced draw, or tempo loss for stronger Arts bursts. In the current prototype, the clearest examples are `Burn Will`, which trades 4 HP for 3 Will, and `Overclock Arts`, which deals 16 Arts damage and then costs 3 HP."},
	"codex.term_slow_title": {"zh": "迟滞（Slow）", "en": "Slow"},
	"codex.term_slow_body": {"zh": "迟滞会压低单位造成的伤害。当前原型里它和虚弱一样，会让伤害乘 0.75，也就是少 25%%。它主要来自 `霜叶·迟滞领域`，通常会在该单位完成下一次行动后减掉 1 层。", "en": "Slow lowers the damage a unit deals. In the current prototype it works like Weak and multiplies damage by 0.75, or 25%% less. It mainly comes from `Frostleaf Delay Field` and usually decays by 1 after that unit completes its next action."},
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
	"victory.title_hidden": {"zh": "灰烬真相", "en": "Ashen Truth"},
	"victory.body": {"zh": "%s带领小队完成了这次远征。无论你是否继续进入隐藏层，这一局都已经算正式通关。", "en": "%s led the squad through the expedition. Whether or not you continue into the hidden floor, this run already counts as a clear."},
	"victory.body_hidden": {"zh": "%s穿过了灰烬回响的最后一层伪装，把这场行动真正推进到了尽头。隐藏层已经收束，这一局也被记作完整真结局通关。", "en": "%s pushed through Ash Echo's final veil and carried the operation to its true end. The hidden route is now resolved and this run counts as a true ending clear."},
	"victory.summary": {"zh": "抵达第 %d 层\n累计金币：%d\n最终卡组：%d 张\n模块数量：%d", "en": "Reached floor %d\nGold collected: %d\nFinal deck size: %d\nModules: %d"},
	"victory.back": {"zh": "返回主菜单", "en": "Back to Main Menu"},
	"victory.hint": {"zh": "主菜单里仍然可以继续查看百科、继续游戏或重新开局。", "en": "From the main menu, you can still open the codex, continue, or start a new run."},
	"victory.hint_hidden": {"zh": "这次不只是打通了主线，还揭开了隐藏层收束。之后你可以继续优化构筑，挑战更稳的真结局路线。", "en": "This run did more than clear the main route: it also resolved the hidden ending. You can keep refining builds for a cleaner true-ending path."},
	"map.header": {"zh": "第 %d 层 | %s", "en": "Floor %d | %s"},
	"map.status": {"zh": "生命 %d/%d   金币 %d   卡组 %d   模块 %d", "en": "HP %d/%d   Gold %d   Deck %d   Modules %d"},
	"map.hero_chip": {"zh": "Amiya", "en": "Amiya"},
	"map.hud_hp": {"zh": "生命 %d/%d", "en": "HP %d/%d"},
	"map.hud_gold": {"zh": "金币 %d", "en": "Gold %d"},
	"map.hud_deck": {"zh": "卡组 %d", "en": "Deck %d"},
	"map.hud_modules": {"zh": "模块 %d", "en": "Modules %d"},
	"map.sidebar_title": {"zh": "行动摘要", "en": "Operation Summary"},
	"map.sidebar_body": {"zh": "当前位于第 %d 层的%s。这里集中放置本局最常看的卡组、模块、护符与调律信息，方便在选路前快速确认构筑方向。", "en": "You are currently on floor %d: %s. This side panel keeps your deck, modules, charms, and tunes visible before you commit to the next route."},
	"map.sidebar_charms": {"zh": "护符 %d", "en": "Charms %d"},
	"map.sidebar_actions": {"zh": "快速查看", "en": "Quick Access"},
	"map.sidebar_preview_title": {"zh": "节点说明", "en": "Node Preview"},
	"map.sidebar_preview_default": {"zh": "悬停一个节点，先看看这一步更偏战斗、商店还是剧情，再决定往哪条线推进。", "en": "Hover a node to preview whether the next stop leans toward combat, shopping, or story before choosing your route."},
	"map.sidebar_preview_route": {"zh": "后续可能连到：%s", "en": "Can branch into: %s"},
	"map.sidebar_preview_tests": {"zh": "这一步更偏向 %s 检定。", "en": "This stop leans toward a %s check."},
	"map.sidebar_preview_enemy_count": {"zh": "预计敌人：%d 名", "en": "Estimated enemies: %d"},
	"map.sidebar_preview_enemy_list": {"zh": "预计敌人：%s", "en": "Estimated enemies: %s"},
	"map.sidebar_preview_enemy_generic": {"zh": "预计遭遇：%s 相关内容", "en": "Expected encounter: %s content"},
	"map.sidebar_preview_reward": {"zh": "主要收益：%s", "en": "Primary payoff: %s"},
	"map.sidebar_reward_battle": {"zh": "卡牌奖励，顺带有少量金币", "en": "Card reward with a little gold"},
	"map.sidebar_reward_elite": {"zh": "高品质奖励，更容易出稀有卡与模块", "en": "Higher-tier rewards with better odds for rare cards and modules"},
	"map.sidebar_reward_boss": {"zh": "首领结算与关键推进奖励", "en": "Boss payout and key progression rewards"},
	"map.sidebar_reward_shop": {"zh": "买牌、模块、护符，并修整套牌方向", "en": "Buy cards, modules, charms, and repair your build direction"},
	"map.sidebar_reward_event": {"zh": "剧情分支、代价交换与长期路线变化", "en": "Story branches, trade-offs, and long-term route shifts"},
	"map.sidebar_reward_rest": {"zh": "回血、升级、调律与临时战术改造", "en": "Heal, upgrade, tune, and temporary tactical rewires"},
	"map.inspect_deck": {"zh": "查看当前卡组", "en": "Inspect current deck"},
	"map.inspect_modules": {"zh": "查看当前模块", "en": "Inspect current modules"},
	"map.deck_title": {"zh": "当前卡组", "en": "Current Deck"},
	"map.modules_title": {"zh": "当前模块", "en": "Current Modules"},
	"map.no_modules": {"zh": "这一局还没有拿到任何模块。", "en": "No modules have been acquired in this run yet."},
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
	"battle.log_title": {"zh": "战斗日志", "en": "Combat Log"},
	"battle.log_subtitle": {"zh": "命中 · 护盾 · 共振", "en": "Hits · Block · Resonance"},
	"battle.energy_orb": {"zh": "能量\n%d/%d", "en": "Energy\n%d/%d"},
	"battle.combat_info": {"zh": "回合 %d   当前目标：%s   战斗节奏：%s", "en": "Turn %d   Target: %s   Combat Tempo: %s"},
	"battle.enemy_panel": {"zh": "%s\n生命 %d/%d  护盾 %d\n意图：%s", "en": "%s\nHP %d/%d  Block %d\nIntent: %s"},
	"battle.targeting": {"zh": "当前目标：%s", "en": "Targeting %s"},
	"battle.target_hint_title": {"zh": "选定术式：%s", "en": "Selected card: %s"},
	"battle.target_hint_body": {"zh": "点击敌人确认。右键或 Esc 取消。当前锁定：%s", "en": "Click an enemy to confirm. Right-click or Esc to cancel. Current lock: %s"},
	"battle.target_none": {"zh": "无", "en": "None"},
	"battle.buff_ready": {"zh": "已就绪", "en": "Ready"},
	"battle.buff_idle": {"zh": "未触发", "en": "Inactive"},
	"battle.end_turn": {"zh": "结束回合", "en": "End Turn"},
	"battle.abandon": {"zh": "放弃战斗", "en": "Abandon"},
	"battle.abandon_tooltip": {"zh": "结束当前行动存档，并按失败结算。", "en": "End the current run and count it as a defeat."},
	"battle.abandon_title": {"zh": "放弃本次行动？", "en": "Abandon this run?"},
	"battle.abandon_body": {"zh": "确认后会立刻结束当前存档，记录为行动失败，并返回结算页面。这个操作不能撤销。", "en": "This will immediately end the current saved run, record it as a defeat, and open the result screen. This cannot be undone."},
	"battle.abandon_confirm": {"zh": "确认放弃", "en": "Abandon Run"},
	"battle.abandon_cancel": {"zh": "继续战斗", "en": "Keep Fighting"},
	"battle.support_banner_title": {"zh": "支援介入", "en": "Support Online"},
	"battle.support_banner_body": {"zh": "%s 接入了前线指挥链。", "en": "%s enters the frontline command chain."},
	"battle.support_cutin_title": {"zh": "战术支援", "en": "Tactical Support"},
	"battle.support_cutin_body": {"zh": "%s", "en": "%s"},
	"battle.float_support": {"zh": "支援", "en": "Support"},
	"battle.float_damage": {"zh": "-%d", "en": "-%d"},
	"battle.float_heal": {"zh": "+%d", "en": "+%d"},
	"battle.float_block_gain": {"zh": "护盾 +%d", "en": "Block +%d"},
	"battle.float_block_loss": {"zh": "护盾 -%d", "en": "Block -%d"},
	"battle.float_block_break": {"zh": "破盾", "en": "Break"},
	"battle.float_will_gain": {"zh": "意志 +%d", "en": "Will +%d"},
	"battle.float_will_spend": {"zh": "意志 -%d", "en": "Will -%d"},
	"battle.float_energy_gain": {"zh": "能量 +%d", "en": "Energy +%d"},
	"battle.float_overload_gain": {"zh": "负荷 +%d", "en": "Overload +%d"},
	"battle.float_overload_reduce": {"zh": "负荷 -%d", "en": "Overload -%d"},
	"battle.float_echo_gain": {"zh": "回响", "en": "Echo"},
	"battle.float_channel_ready": {"zh": "引导", "en": "Channel"},
	"battle.float_status_weak": {"zh": "虚弱 +%d", "en": "Weak +%d"},
	"battle.float_status_vulnerable": {"zh": "易伤 +%d", "en": "Vulnerable +%d"},
	"battle.float_status_strength": {"zh": "力量 +%d", "en": "Strength +%d"},
	"battle.float_resonance_gain": {"zh": "共振 +%d", "en": "Resonance +%d"},
	"battle.float_resonance_burst": {"zh": "引爆 x%d", "en": "Burst x%d"},
	"tune.hud_chip": {"zh": "调律 %d", "en": "Tune %d"},
	"tune.overlay_title": {"zh": "当前调律", "en": "Active Tunes"},
	"tune.overlay_intro_title": {"zh": "本局改造总览", "en": "Run Tuning Overview"},
	"tune.overlay_intro_body": {"zh": "当前已启用 %d 项调律。它们会整局持续生效。", "en": "%d tunes are active for this run. They persist through the entire operation."},
	"tune.overlay_empty_title": {"zh": "暂无调律", "en": "No Tunes Yet"},
	"tune.overlay_empty_body": {"zh": "这一局还没有进行调律。休整点和商店都能继续塑形你的构筑。", "en": "This run does not have any tunes yet. Rest sites and shops can still reshape the build."},
	"battle.status_will": {"zh": "意志 %d\n当前意志会让「回响导流」额外 +%d 伤害；若意志达到 4 点以上，「谐振爆发」额外 +%d 伤害。", "en": "Will %d\nCurrent Will adds +%d damage to Echo Conduit. At 4+ Will, Resonance Burst gains +%d damage."},
	"battle.status_leader_ready": {"zh": "领袖加成已就绪\n你本回合第一次打出支援牌后，下一张术式牌固定 +2 伤害。", "en": "Leader buff ready\nAfter your first Support this turn, the next Arts card gains +2 damage."},
	"battle.status_weak": {"zh": "虚弱 %d\n该单位造成的伤害减少 25%%。通常会在完成下一次行动后减少 1 层。", "en": "Weak %d\nThis unit deals 25%% less damage. It usually loses 1 stack after its next action."},
	"battle.status_vulnerable": {"zh": "易伤 %d\n该单位受到的伤害增加 50%%。通常会在完成下一次行动后减少 1 层。", "en": "Vulnerable %d\nThis unit takes 50%% more damage. It usually loses 1 stack after its next action."},
	"battle.status_strength": {"zh": "力量 %d\n该单位造成伤害时额外 +%d。", "en": "Strength %d\nThis unit deals +%d extra damage."},
	"battle.status_resonance": {"zh": "共振 %d\n共振本身不会直接增伤，它是挂在单位身上的层数资源。像「频域崩塌」会每层造成 3 点术式伤害，「嵌合协议」会每层转成 4 点术式伤害。若没有特殊效果保护，敌人回合结束后通常会减少 1 层。", "en": "Resonance %d\nResonance does not increase damage on its own. It is a layered resource attached to a unit. Cards like Collapse Frequency cash it out for 3 Arts damage per stack, while Chimera Protocol converts it to 4 Arts per stack. Unless protected, enemies usually lose 1 stack at the end of their turn."},
	"battle.invalid_state": {"zh": "当前没有有效的战斗状态，正在返回上一级页面。", "en": "No valid battle state was found. Returning to the previous screen."},
	"event.empty_title": {"zh": "安静的走廊", "en": "Quiet Corridor"},
	"event.empty_body": {"zh": "这里没有发生特别的事情。", "en": "Nothing meaningful happens here."},
	"event.empty_footer": {"zh": "这一格没有额外分支，确认后直接继续推进。", "en": "There is no extra branch here. Confirm to keep moving."},
	"event.eyebrow": {"zh": "事件档案", "en": "Field Event"},
	"event.continue": {"zh": "继续", "en": "Continue"},
	"event.confirm": {"zh": "确认选择", "en": "Confirm Choice"},
	"event.choose_option": {"zh": "先选一个方案，再确认执行。", "en": "Choose an option first, then confirm."},
	"event.selected_hint": {"zh": "当前方案：%s", "en": "Selected plan: %s"},
	"reward.eyebrow": {"zh": "战后结算", "en": "After Action Report"},
	"reward.title": {"zh": "奖励", "en": "Reward"},
	"reward.body_default": {"zh": "为下一场作战选择一项战术收益。", "en": "Choose a tactical gain for the next operation."},
	"reward.body_elite": {"zh": "精英战斩获更丰富的战利品。本次奖励至少包含一张高阶战术卡。", "en": "Elite encounters yield richer loot. This reward includes at least one higher-tier tactical card."},
	"reward.body_elite_double": {"zh": "精英战大获全胜。本次奖励至少包含一张高阶战术卡，并且有机会带走两张牌。", "en": "A major elite victory. This reward includes at least one higher-tier tactical card and may let you keep two cards."},
	"reward.pick_remaining": {"zh": "还可选择 %d / %d 张牌。", "en": "%d / %d card picks remaining."},
	"reward.module_bonus_title": {"zh": "获得模块", "en": "Module Acquired"},
	"reward.module_bonus": {"zh": "额外获得模块：%s", "en": "Bonus Module: %s"},
	"reward.footer_pending": {"zh": "先确认本次奖励，再继续推进。", "en": "Confirm this reward before moving on."},
	"reward.footer_ready": {"zh": "奖励已经整理完毕，可以继续前进。", "en": "Rewards are settled. You can move on."},
	"reward.footer_empty": {"zh": "这一格没有额外奖励，确认后继续。", "en": "There is no extra reward here. Continue when ready."},
	"reward.continue": {"zh": "继续", "en": "Continue"},
	"reward.skip": {"zh": "跳过奖励", "en": "Skip Reward"},
	"rest.eyebrow": {"zh": "整备据点", "en": "Regroup Site"},
	"rest.info": {"zh": "罗德岛临时休整点会让小队完全恢复生命值。每层结算后都会强制进行一次整备，再进入下一层。", "en": "A Rhodes Island rest point fully restores the squad. One full regroup is forced between floors before the next deployment."},
	"rest.interfloor_done": {"zh": "层间休整完成：生命值已完全恢复。", "en": "Interfloor rest complete: HP fully restored."},
	"rest.choose_service": {"zh": "选择一项休整服务，然后继续行动。", "en": "Choose a rest service, then continue."},
	"rest.footer_default": {"zh": "休整点通常只能使用一项服务，确认后继续。", "en": "Rest sites usually allow one service before moving on."},
	"rest.footer_upgrade": {"zh": "选择一张牌完成升级，或返回上一层服务列表。", "en": "Choose a card to upgrade, or return to the service list."},
	"rest.footer_used": {"zh": "本次休整已经完成，现在可以继续推进。", "en": "This rest stop is complete. You can continue forward."},
	"rest.footer_interfloor": {"zh": "层间回复已经完成，确认后进入下一层行动。", "en": "Interfloor recovery is complete. Continue to the next floor."},
	"rest.service_recover": {"zh": "恢复：回复 30% 最大生命", "en": "Recover: heal 30% of max HP"},
	"rest.service_upgrade": {"zh": "升级：选择一张可升级牌", "en": "Upgrade: choose an eligible card"},
	"rest.service_tune": {"zh": "调律：%s | %s", "en": "Tune: %s | %s"},
	"rest.service_rewire_arts": {"zh": "重构：每回合第一张 Arts +2 伤害", "en": "Rewire: first Arts each turn deals +2 damage"},
	"rest.service_rewire_support": {"zh": "重构：每战第一次 Support 抽 2", "en": "Rewire: first Support each battle draws 2"},
	"rest.service_rewire_overload": {"zh": "重构：Overload 结算伤害 -1", "en": "Rewire: Overload tick damage -1"},
	"rest.service_equip_charm": {"zh": "补入护符：获得一个未拥有的 Charm", "en": "Equip Charm: gain an unowned Charm"},
	"rest.done_recover": {"zh": "已回复 30% 最大生命。", "en": "Recovered 30% of max HP."},
	"rest.done_upgrade": {"zh": "已升级：%s。", "en": "Upgraded: %s."},
	"rest.done_upgrade_none": {"zh": "没有找到可升级的牌。", "en": "No upgradable cards found."},
	"rest.pick_card_to_upgrade": {"zh": "选择一张牌进行升级：", "en": "Choose a card to upgrade:"},
	"rest.upgrade_choice": {"zh": "升级：%s", "en": "Upgrade: %s"},
	"rest.upgrade_choice_tooltip": {"zh": "%s\n升级后效果：%s", "en": "%s\nUpgraded effect: %s"},
	"rest.back_services": {"zh": "返回休整选项", "en": "Back to Rest Options"},
	"rest.done_tune": {"zh": "调律完成：%s。\n%s", "en": "Tuning complete: %s.\n%s"},
	"rest.done_tune_duplicate": {"zh": "这个调律已经掌握过了。", "en": "This tune has already been learned."},
	"rest.done_rewire_arts": {"zh": "已选择临时战术：每回合第一张 Arts +2 伤害。", "en": "Tactical rewire applied: first Arts each turn deals +2 damage."},
	"rest.done_rewire_support": {"zh": "已选择临时战术：每战第一次 Support 抽 2。", "en": "Tactical rewire applied: first Support each battle draws 2."},
	"rest.done_rewire_overload": {"zh": "已选择临时战术：Overload 结算伤害 -1。", "en": "Tactical rewire applied: Overload tick damage -1."},
	"rest.done_equip_charm": {"zh": "已装备 Charm：%s。", "en": "Charm equipped: %s."},
	"rest.done_equip_charm_full": {"zh": "所有 Charm 都已经拥有。", "en": "All Charms already owned."},
	"rest.current_tunes": {"zh": "\n\n当前调律：\n%s", "en": "\n\nCurrent tunes:\n%s"},
	"shop.eyebrow": {"zh": "前线整备货架", "en": "Forward Supply Shelf"},
	"shop.title": {"zh": "前线商店", "en": "Field Shop"},
	"shop.gold_chip": {"zh": "金币 %d", "en": "Gold %d"},
	"shop.loading": {"zh": "商店正在整理货架……", "en": "The field shop is arranging its stock..."},
	"shop.info": {"zh": "这里会根据你当前的构筑方向整理卡牌、模块、护符与服务。上方会固定显示你当前持有的金币。", "en": "The field shop arranges cards, modules, charms, and services around your current build. Your available gold is always shown at the top."},
	"shop.section_cards": {"zh": "卡牌", "en": "Cards"},
	"shop.section_modules": {"zh": "模块", "en": "Modules"},
	"shop.section_charms": {"zh": "护符", "en": "Charms"},
	"shop.section_services": {"zh": "服务", "en": "Services"},
	"shop.charms_chip": {"zh": "护符 %d", "en": "Charms %d"},
	"shop.filter_cards": {"zh": "卡牌", "en": "Cards"},
	"shop.filter_modules": {"zh": "模块", "en": "Modules"},
	"shop.filter_charms": {"zh": "护符", "en": "Charms"},
	"shop.filter_services": {"zh": "服务", "en": "Services"},
	"shop.footer_section": {"zh": "当前查看：%s · 共 %d 项。滚动中区即可继续浏览。", "en": "Viewing: %s · %d entries. Scroll the middle shelf to browse more."},
	"shop.buy_action": {"zh": "购买（%d 金币）", "en": "Buy (%d Gold)"},
	"shop.service_remove_first": {"zh": "移除牌组中的第一张牌（%d 金币）", "en": "Remove the first card in the deck (%d Gold)"},
	"shop.service_upgrade_first": {"zh": "升级第一张可升级牌（%d 金币）", "en": "Upgrade the first upgradable card (%d Gold)"},
	"shop.service_tune_line": {"zh": "调律：%s | %s（%d 金币）", "en": "Tune: %s | %s (%d Gold)"},
	"shop.service_rewire_arts": {"zh": "重构：每回合第一张术式 +2（%d 金币）", "en": "Rewire: first Arts each turn gets +2 (%d Gold)"},
	"shop.service_rewire_support": {"zh": "重构：每战第一次支援抽 2（%d 金币）", "en": "Rewire: first Support each battle draws 2 (%d Gold)"},
	"shop.service_rewire_overload": {"zh": "重构：过载结算伤害 -1（%d 金币）", "en": "Rewire: Overload tick damage -1 (%d Gold)"},
	"shop.service_equip_charm": {"zh": "补入护符：获得一个未拥有护符（%d 金币）", "en": "Equip Charm: gain an unowned Charm (%d Gold)"},
	"shop.service_refresh": {"zh": "刷新货架（%d 金币）", "en": "Refresh shop (%d Gold)"},
	"shop.service_remove_first_title": {"zh": "移除一张牌", "en": "Remove a Card"},
	"shop.service_remove_first_desc": {"zh": "从牌组里移除当前排序中的第一张牌。适合清掉过渡牌或诅咒牌。", "en": "Remove the first card in your current deck order. Useful for clearing filler or curses."},
	"shop.service_upgrade_first_title": {"zh": "升级一张牌", "en": "Upgrade a Card"},
	"shop.service_upgrade_first_desc": {"zh": "升级当前找到的第一张可升级牌，直接提升它的数值或效果。", "en": "Upgrade the first upgradable card found in your deck to improve its stats or effect."},
	"shop.service_tune_title": {"zh": "调律：%s", "en": "Tune: %s"},
	"shop.service_rewire_arts_title": {"zh": "重构：术式增幅", "en": "Rewire: Arts Boost"},
	"shop.service_rewire_arts_desc": {"zh": "每回合第一张术式牌额外获得 +2 伤害，适合稳定补输出。", "en": "The first Arts card each turn gains +2 damage for steadier output."},
	"shop.service_rewire_support_title": {"zh": "重构：支援抽牌", "en": "Rewire: Support Draw"},
	"shop.service_rewire_support_desc": {"zh": "每场战斗第一次打出支援牌时，额外抽 2 张牌。", "en": "The first Support card each battle draws 2 extra cards."},
	"shop.service_rewire_overload_title": {"zh": "重构：过载缓冲", "en": "Rewire: Overload Buffer"},
	"shop.service_rewire_overload_desc": {"zh": "过载结算时受到的伤害减少 1 点，适合高压透支流。", "en": "Reduce Overload tick damage by 1, useful for riskier overload builds."},
	"shop.service_equip_charm_title": {"zh": "补入护符", "en": "Acquire Charm"},
	"shop.service_equip_charm_desc": {"zh": "获得并装备一个你还没有的护符，进一步给牌组定方向。", "en": "Gain and equip an unowned Charm to push your build in a clearer direction."},
	"shop.service_refresh_title": {"zh": "刷新货架", "en": "Refresh Stock"},
	"shop.service_refresh_desc": {"zh": "重置当前商店货架，生成一批新的卡牌、模块、护符与服务项。", "en": "Refresh the current shop stock with a new set of cards, modules, charms, and services."},
	"shop.not_enough_gold": {"zh": "金币不足。", "en": "Not enough gold."},
	"shop.refreshed": {"zh": "商店已刷新。", "en": "Shop refreshed."},
	"shop.no_card_to_remove": {"zh": "当前没有可移除的牌。", "en": "There is no card to remove."},
	"shop.removed_named": {"zh": "已移除：%s", "en": "Removed: %s"},
	"shop.upgraded_named": {"zh": "已升级：%s", "en": "Upgraded: %s"},
	"shop.no_upgrade_target": {"zh": "没有找到可升级的牌。", "en": "No card can be upgraded right now."},
	"shop.tune_owned": {"zh": "这个调律已经拥有了。", "en": "This tune is already owned."},
	"shop.tune_bought": {"zh": "已购入调律：%s\n%s", "en": "Tune acquired: %s\n%s"},
	"shop.charm_equipped": {"zh": "已装备护符：%s", "en": "Charm equipped: %s"},
	"shop.all_charms_owned": {"zh": "所有护符都已经拥有。", "en": "All charms are already owned."},
	"shop.rewire_arts_done": {"zh": "已接入重构：每回合第一张术式 +2。", "en": "Rewire installed: first Arts each turn gets +2."},
	"shop.rewire_support_done": {"zh": "已接入重构：每战第一次支援抽 2。", "en": "Rewire installed: first Support each battle draws 2."},
	"shop.rewire_overload_done": {"zh": "已接入重构：过载结算伤害 -1。", "en": "Rewire installed: Overload tick damage -1."},
	"battle.log.start": {"zh": "作战开始。%s接管指挥。", "en": "Operation starts. %s takes command."},
	"battle.log.countdown": {"zh": "爆破倒计时触发，受到 8 点伤害。", "en": "Blast Countdown detonates for 8 damage."},
		"battle.log.curse": {"zh": "%s 向你的卡组塞入了一张诅咒。", "en": "%s pollutes the deck with a curse."},
		"battle.log.disrupt": {"zh": "%s 扰乱了阵型，你的下一张牌费用提高。", "en": "%s disrupts formation and taxes the next play."},
		"battle.log.play_failed": {"zh": "[%s] 未能打出。当前需要 %d 费，你只有 %d 点能量。", "en": "[%s] could not be played. It needs %d energy but you only have %d."},
		"battle.log.enemy_idle": {"zh": "敌人没有采取行动。", "en": "Enemy did nothing."},
	"battle.log.panic": {"zh": "恐慌杂音生效，本回合第一张牌费用增加。", "en": "Panic Static increases the first card cost this turn."},
	"battle.log.leader_ready": {"zh": "阿米娅调整了队伍节奏，下一张术式会更强。", "en": "Amiya syncs the squad's tempo. The next Arts card is empowered."},
	"battle.log.will": {"zh": "意志 +%d", "en": "Will +%d"},
	"battle.log.channel_resolve": {"zh": "引导完成：获得 %d 点意志，并抽 %d 张牌。", "en": "Channel resolves: gain %d Will and draw %d."},
	"battle.log.channel_damage_will": {"zh": "引导完成：对目标造成 %d 点术式伤害，并获得 %d 点意志。", "en": "Channel resolves: deal %d Arts damage to the target and gain %d Will."},
	"battle.log.burn": {"zh": "灼痕发作，你受到 2 点伤害。", "en": "Burn flares up. You take 2 damage."},
	"battle.log.overloaded_nerves": {"zh": "过载神经发作：获得 1 层精神负荷，下回合额外抽 1。", "en": "Overloaded Nerves flare up: gain 1 Overload and draw 1 extra next turn."},
	"battle.log.sealed_chimera": {"zh": "封闭嵌合启动：你因精神负荷额外获得了 1 点意志。", "en": "Sealed Chimera triggers: gaining Overload also grants 1 Will."},
	"battle.log.shared_burden": {"zh": "共负其重触发：抽 1 并获得 1 点意志。", "en": "Shared Burden triggers: draw 1 and gain 1 Will."},
	"battle.log.forbidden_crown": {"zh": "禁忌冠冕灼响：回合结束时获得 1 层精神负荷。", "en": "Forbidden Crown hums: gain 1 Overload at end of turn."},
	"battle.log.voice_of_the_team": {"zh": "团队之声生成了临时术式：%s。", "en": "Voice of the Team generates a temporary Arts card: %s."},
	"battle.log.crowned_resolve": {"zh": "冠冕意志触发，额外获得 1 点护盾。", "en": "Crowned Resolve triggers and grants 1 Block."},
	"battle.log.resonance_apply": {"zh": "%s 获得了 %d 层共振。", "en": "%s gains %d Resonance."},
	"battle.log.resonance_consume": {"zh": "%s 身上的 %d 层共振被引爆了。", "en": "Resonance on %s is consumed: %d."},
	"battle.log.resonance_consume_total": {"zh": "总共引爆了 %d 层共振。", "en": "%d total Resonance is consumed."},
	"battle.log.damage": {"zh": "造成 %d 点伤害", "en": "Damage %d"},
	"battle.log.damage_detail": {"zh": "%s 对 %s 造成了 %d 点伤害。", "en": "%s dealt damage to %s for %d."},
	"battle.log.block_absorb": {"zh": "%s 挡下了 %d 点伤害。", "en": "%s absorbs %d damage with Block."},
	"battle.log.block_break": {"zh": "%s 的护盾被彻底击碎。", "en": "%s's Block is shattered."},
	"battle.intent_attack_tooltip": {"zh": "%s\n预估打击：%d\n当前护盾吸收：%d\n实际掉血：%d", "en": "%s\nProjected hit: %d\nBlocked now: %d\nHP loss now: %d"},
	"battle.intent_curse_tooltip": {"zh": "%s\n将施加诅咒或牌组干扰。", "en": "%s\nWill apply a curse or deck disruption."},
	"battle.intent_rule_tooltip": {"zh": "%s\n将改变下一回合的战场规则。", "en": "%s\nWill alter the next turn's battlefield rule."},
	"battle.intent_other_tooltip": {"zh": "%s\n这是一个特殊行动。", "en": "%s\nThis is a special action."},
	"battle.log.auto_end": {"zh": "没有可继续打出的牌了，回合自动结束。", "en": "No more playable cards. Ending turn automatically."},
	"battle.log.scan": {"zh": "脉冲扫描看到：%s", "en": "Pulse Scan sees: %s"},
	"battle.log.w_hand": {"zh": "W 扭曲了战场。下一次抽牌手牌上限变为 4。", "en": "W twists the field. Hand size drops to 4 for the next draw."},
	"battle.log.w_tax": {"zh": "W 制造迟疑。下一回合第一张牌费用 +1。", "en": "W forces hesitation. The next first card costs +1."},
	"battle.log.w_shift": {"zh": "在 W 的压力下，战场规则发生了变化。", "en": "The battlefield shifts under W's pressure."},
	"battle.log.w_third": {"zh": "W 惩罚了你的第三张牌，你受到 %d 点自伤。", "en": "W punishes the third card with %d self damage."},
	"battle.log.rhodes_formation": {"zh": "罗德岛阵列协同生效，获得 3 点护盾。", "en": "Rhodes Formation triggers. Gain 3 Block."},
	"battle.log.tactical_network": {"zh": "战术网络回流能量，获得 1 点能量。", "en": "Tactical Network refunds 1 Energy."},
	"battle.log.signal_booster": {"zh": "信号增幅器启动，额外抽 1 张牌。", "en": "Signal Booster activates. Draw 1 extra card."},
	"battle.log.field_command_badge": {"zh": "战地指挥徽章回流能量，获得 1 点能量。", "en": "Field Command Badge refunds 1 Energy."},
	"battle.log.luminous_guard": {"zh": "临光的守势稳住了战线：这张防御牌额外获得 4 点护盾。", "en": "Nearl steadies the line: this defensive card gains 4 extra Block."},
	"battle.log.cover_fire_lead": {"zh": "能天使抢先开火：本回合第一张攻击返还 1 点能量。", "en": "Exusiai opens fire first: the first Attack this turn refunds 1 Energy."},
	"battle.log.cold_analysis": {"zh": "凯尔希冷静分析局势：首张支援或引导额外抽 1。", "en": "Kal'tsit coldly analyzes the field: the first Support or Channel draws 1."},
	"battle.log.enemy_block": {"zh": "%s 加固了防线，获得 %d 点护盾。", "en": "%s reinforces its defense and gains %d Block."},
	"battle.log.enemy_debuff": {"zh": "%s 对你施加了负面状态。", "en": "%s inflicts a debuff on you."},
	"battle.log.enemy_charge": {"zh": "%s 正在蓄力，准备下一次爆发。", "en": "%s is charging up for a powerful strike."},
	"battle.log.enemy_release": {"zh": "%s 释放了蓄力攻击，造成 %d 点伤害！", "en": "%s unleashes the charged strike for %d damage!"}
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
	"blast_countdown": {"zh_name": "爆破倒计时", "zh_desc": "若本回合未处理，回合结束时受到 8 点伤害。"},
	"guard_pulse": {"zh_name": "守护脉冲", "zh_desc": "获得 5 点护盾。"},
	"mental_tuning": {"zh_name": "精神校准", "zh_desc": "抽 2 张牌，获得 1 点意志。"},
	"field_command": {"zh_name": "战场指令", "zh_desc": "本回合第一次打出支援牌后，抽 1 张牌。"},
	"resonance_mark": {"zh_name": "共振标记", "zh_desc": "对目标施加 3 层共振。"},
	"focused_ray": {"zh_name": "聚焦射线", "zh_desc": "造成 9 点术式伤害；若意志至少为 3，再造成 4 点。"},
	"tactical_briefing": {"zh_name": "战术简报", "zh_desc": "抽 2 张牌；本回合下一张支援牌费用 -1。"},
	"bloodline_casting": {"zh_name": "透支施术", "zh_desc": "失去 3 点生命，获得 2 点能量。"},
	"channel_pulse": {"zh_name": "引导脉冲", "zh_desc": "下回合开始时获得 3 点意志并抽 1 张牌。"},
	"stabilize_line": {"zh_name": "稳定战线", "zh_desc": "获得 7 点护盾；若本回合打出过支援牌，净化 1 个负面状态。"},
	"arc_sliver": {"zh_name": "弧光切片", "zh_desc": "造成 7 点术式伤害；若意志至少为 2，再造成 3 点。"},
	"mind_pressure": {"zh_name": "心压", "zh_desc": "获得 2 点意志；本回合不能获得护盾。"},
	"harmonic_cut": {"zh_name": "谐律切断", "zh_desc": "造成 6 点术式伤害；若目标已有共振，抽 1 张牌。"},
	"pressure_wave": {"zh_name": "压缩波", "zh_desc": "对所有敌人造成 4 点术式伤害。"},
	"echo_lattice": {"zh_name": "回响格", "zh_desc": "获得 Echo：下一张术式牌重复 50% 基础效果。"},
	"resonant_insight": {"zh_name": "共振洞察", "zh_desc": "若任一敌人有共振，则抽 2；否则对随机敌人施加 2 层共振。"},
	"crowned_resolve": {"zh_name": "冠冕意志", "zh_desc": "能力。每当你获得意志，获得 1 点护盾。"},
	"grand_equation": {"zh_name": "大术式方程", "zh_desc": "造成 8 点术式伤害；再按当前意志每点追加 2 点；然后消耗 2 点意志。"},
	"final_vector": {"zh_name": "终向量", "zh_desc": "造成 28 点术式伤害；若意志至少为 6，再施加 2 层易伤。"},
	"overclock_casting": {"zh_name": "过载施术", "zh_desc": "本回合下一张术式牌额外造成 6 点伤害，并获得 1 层精神负荷。"},
	"measured_blast": {"zh_name": "定量爆发", "zh_desc": "造成 14 点术式伤害。"},
	"clear_intent": {"zh_name": "澄明意图", "zh_desc": "抽 1 张牌。若手中至少有 2 张术式牌，再获得 2 点意志并额外抽 1。"},
	"phase_tap": {"zh_name": "相位轻触", "zh_desc": "施加 1 层共振。抽 1 张牌。"},
	"split_tone": {"zh_name": "分裂音", "zh_desc": "造成 4 点术式伤害两次；若目标已有共振，再造成 2 点。"},
	"coordinated_strike": {"zh_name": "协同打击", "zh_desc": "造成 7 点伤害；若本回合打出过支援牌，再造成 5 点。"},
	"rhodes_formation": {"zh_name": "罗德岛阵列", "zh_desc": "能力。每当你打出支援牌，获得 3 点护盾。"},
	"desperate_focus": {"zh_name": "绝境专注", "zh_desc": "失去 4 点生命。抽 3 张牌。"},
	"crisis_surge": {"zh_name": "危机涌流", "zh_desc": "若生命高于 50%，获得 1 点意志；否则获得 2 点意志、抽 2 张牌并获得 1 点能量。"},
	"arc_collapse": {"zh_name": "弧塌缩", "zh_desc": "造成 14 点术式伤害；若意志至少为 5，再施加 2 层易伤。"},
	"controlled_detonation": {"zh_name": "受控爆裂", "zh_desc": "最多消耗 3 点意志；每点造成 5 点术式伤害。"},
	"thought_acceleration": {"zh_name": "思维加速", "zh_desc": "获得 2 点意志。本回合下一张术式牌费用 -1。"},
	"widened_spectrum": {"zh_name": "扩谱", "zh_desc": "对所有敌人造成 7 点术式伤害；若意志至少为 4，再额外造成 3 点。"},
	"tactical_network": {"zh_name": "战术网络", "zh_desc": "能力。每回合第一次打出支援牌时，获得 1 点能量。"}
	,
	"chain_reaction": {"zh_name": "连锁反应", "zh_desc": "对所有有共振的敌人造成 8 点术式伤害。"},
	"emergency_order": {"zh_name": "紧急命令", "zh_desc": "从弃牌堆取回 1 张支援牌到手牌；本回合下一张支援牌费用 -1。"},
	"dobermann_drill_order": {"zh_name": "杜宾训令", "zh_desc": "本回合下一张攻击或术式牌 +5 伤害；若本回合已打出 2 张牌，再抽 1。"},
	"exusiai_cover_fire": {"zh_name": "能天使掩护射击", "zh_desc": "对随机敌人造成 3 点伤害 3 次；若目标已有共振，再追加 1 次。"},
	"precise_break": {"zh_name": "精准裂解", "zh_desc": "造成 8 点术式伤害；无视目标 50% 护盾。"},
	"resonance_field": {"zh_name": "共振场", "zh_desc": "能力。敌人获得共振时，随机另一名敌人获得 1 层共振。"},
	"prism_shatter": {"zh_name": "棱镜破裂", "zh_desc": "对所有有共振的敌人造成 6 点术式伤害，并各消耗 1 层共振。"},
	"medical_evac_route": {"zh_name": "医疗撤离路线", "zh_desc": "回复 8 点生命；若本回合打出过 2 张支援牌，再净化全部负面状态。"},
	"elite_coordination": {"zh_name": "精英协同", "zh_desc": "能力。每当你打出支援牌，下一张术式牌额外 +2 伤害。"},
	"tactical_encirclement": {"zh_name": "战术合围", "zh_desc": "造成 12 点术式伤害；本回合每打出 1 张支援牌，再追加 4 点术式伤害。"},
	"harmonic_spike": {"zh_name": "共振刺点", "zh_desc": "造成 5 点术式伤害；若目标已有共振，抽 1 张牌。"},
	"reckless_invocation": {"zh_name": "鲁莽唤起", "zh_desc": "获得 3 层精神负荷；对所有敌人造成 18 点术式伤害。"},
	"ace_last_stand": {"zh_name": "Ace·最后防线", "zh_desc": "获得 15 点护盾；若生命值不高于 30%，额外获得 2 点能量。"},
	"black_ring_method": {"zh_name": "黑环术式", "zh_desc": "造成 10 点术式伤害；若你有精神负荷，再额外造成等同精神负荷层数的术式伤害。"},
	"survival_reflex": {"zh_name": "求生反射", "zh_desc": "若当前生命值不高于 40%，回复 6 点生命并移除 2 层精神负荷。"},
	"will_transfusion": {"zh_name": "意志转灌", "zh_desc": "消耗 2 点意志，抽 2 张牌并获得 1 点能量。"},
	"mirrored_wave": {"zh_name": "镜波", "zh_desc": "造成 10 点术式伤害；若你拥有 Echo，再额外重复一次基础伤害。"},
	"last_argument": {"zh_name": "最后论证", "zh_desc": "造成 18 点术式伤害；若当前生命值不高于 30%，再追加 12 点术式伤害。"},
	"terminal_appeal": {"zh_name": "终端诉求", "zh_desc": "造成 12 点术式伤害；本战每失去过 10 点生命，额外 +4。"},
	"ashes_to_ashes": {"zh_name": "灰归灰", "zh_desc": "对所有敌人造成 10 点术式伤害；再按当前精神负荷对每个敌人造成等额追加伤害。"},
	"frequency_lock": {"zh_name": "频锁", "zh_desc": "对目标施加 2 层共振，并锁定其本回合的共振。"},
	"strategic_rotation": {"zh_name": "战术轮换", "zh_desc": "弃 1 张牌，抽 2；若弃掉的是支援牌，获得 1 点能量。"},
	"forbidden_formula": {"zh_name": "禁式", "zh_desc": "造成 16 点术式伤害，并向弃牌堆加入 1 张灼痕。"},
	"unstable_channel": {"zh_name": "不稳定引导", "zh_desc": "引导：下回合开始时对目标造成 12 点术式伤害并获得 2 点意志；获得 1 层精神负荷。"},
	"collapse_frequency": {"zh_name": "频域崩塌", "zh_desc": "消耗目标全部共振，每层造成 3 点术式伤害。"},
	"feedback_loop": {"zh_name": "反馈回路", "zh_desc": "若目标已有共振，获得 Echo，并再对目标施加 2 层共振。"},
	"blaze_forward_breach": {"zh_name": "煌·前突突破", "zh_desc": "对所有敌人造成 9 点伤害；若本回合你失去过生命，改为 13 点。"},
	"greythroat_suppression": {"zh_name": "灰喉·压制射击", "zh_desc": "造成 5 点伤害 2 次；若本回合打出过支援牌，额外再打 1 次。"},
	"frostleaf_delay_field": {"zh_name": "霜叶·迟滞领域", "zh_desc": "对敌人施加 2 层迟滞；若敌人有共振，再抽 1 张牌。"},
	"pain_for_power": {"zh_name": "以痛换力", "zh_desc": "失去 2 点生命，获得 1 点意志，下一张牌费用 -1。"},
	"burn": {"zh_name": "灼痕", "zh_desc": "无法打出。回合结束时若仍在手中，受到 2 点伤害。"},
	"nerve_burn": {"zh_name": "神经灼烧", "zh_desc": "造成 8 点术式伤害，并向手牌加入 1 张过载神经。"},
	"overloaded_nerves": {"zh_name": "过载神经", "zh_desc": "无法打出。回合结束时获得 1 层精神负荷，并在下回合开始时额外抽 1 张牌。"},
	"sealed_chimera": {"zh_name": "封闭嵌合", "zh_desc": "能力。每当你获得精神负荷，也获得 1 点意志。"},
	"zero_range_cast": {"zh_name": "零距施法", "zh_desc": "造成 14 点术式伤害；若目标本回合受到过支援伤害，再追加 6 点。"},
	"singing_fracture": {"zh_name": "裂唱", "zh_desc": "对目标造成 6 点术式伤害 3 次；若目标有共振，每段再 +1。"},
	"voice_of_the_team": {"zh_name": "团队之声", "zh_desc": "能力。每当你在同一回合打出第 2 张支援牌时，生成 1 张 0 费临时术式牌。"},
	"shared_burden": {"zh_name": "共负其重", "zh_desc": "能力。每回合第一次失去生命后，抽 1 张牌并获得 1 点意志。"},
	"forbidden_crown": {"zh_name": "禁忌冠冕", "zh_desc": "能力。你的术式牌额外造成 4 点伤害；回合结束时获得 1 层精神负荷。"},
	"chimera_protocol": {"zh_name": "嵌合协议", "zh_desc": "消耗全部意志与目标全部共振；每点意志造成 5 点术式伤害，每层共振造成 4 点术式伤害。"},
	"the_cost_of_mercy": {"zh_name": "仁慈的代价", "zh_desc": "回复 12 点生命，获得 2 点意志，并获得 2 层精神负荷。"}
	,
	"resonance_harvest": {"zh_name": "共振收割", "zh_desc": "每有一名带共振的敌人，抽 1 张牌；若抽到术式牌，其费用 -1。"},
	"harmonic_dominion": {"zh_name": "和声支配", "zh_desc": "能力。共振不会自然衰减；每回合开始时，随机一名敌人获得 1 层共振。"},
	"sevenfold_echo": {"zh_name": "七重回响", "zh_desc": "接下来 2 张术式牌获得 Echo 50%。"},
	"unified_battleplan": {"zh_name": "统一战斗计划", "zh_desc": "本回合所有支援牌费用 -1；本回合第一次打出支援牌后抽 2 张牌。"},
	"controlled_overload": {"zh_name": "受控过载", "zh_desc": "能力。你的过载类牌造成的自伤减半（向下取整）。"},
	"voice_of_the_leader": {"zh_name": "领袖之声", "zh_desc": "能力。本战中每打出第 2 张支援牌时，生成 1 张 0 费临时术式牌。"},
	"ashes_remember": {"zh_name": "灰烬铭记", "zh_desc": "统计本战已失去的生命值，将其中 50% 转化为对所有敌人的术式伤害。"},
	"final_directive": {"zh_name": "最终指令", "zh_desc": "本回合你的支援、术式、战术牌彼此都视为对方类型，并抽 2 张牌。"},
	"absolute_resonance": {"zh_name": "绝对共振", "zh_desc": "能力。每当你消耗共振，获得 Echo 50%。"},
	"landship_wide_order": {"zh_name": "全舰级命令", "zh_desc": "从支援池中调入 2 张 0 费支援牌到手牌。"},
	"ember_judgement": {"zh_name": "余烬裁定", "zh_desc": "若意志至少为 5 或精神负荷至少为 3，造成 36 点术式伤害；否则造成 18 点。"},
	"unstable_resonance": {"zh_name": "不稳定共振", "zh_desc": "对自己施加 2 层共振，抽 1 张牌。消耗。"},
	"delayed_directive": {"zh_name": "延迟指令", "zh_desc": "引导：下回合抽 2 张牌，然后下一张支援牌费用 -1。"},
	"echo_reserve": {"zh_name": "回响储备", "zh_desc": "引导：下回合获得 Echo 50%。"},
	"formation_hold": {"zh_name": "阵型固守", "zh_desc": "能力。每回合第一张支援牌为下回合储存 3 点护盾。"},
	"primed_arts": {"zh_name": "蓄能术式", "zh_desc": "引导：下回合你的下一张术式牌额外 +8 伤害。"},
	"terminal_charge": {"zh_name": "末端蓄能", "zh_desc": "回合结束时对随机敌人造成 12 点术式伤害；获得 1 层精神负荷。"},
	"twin_channel": {"zh_name": "双重引导", "zh_desc": "获得 1 点意志。引导：下回合获得 2 点意志并抽 1 张。"},
	"mental_noise": {"zh_name": "精神噪音", "zh_desc": "无法打出。回合结束时，若你本回合没有获得意志，则下回合少抽 1 张牌。"},
	"command_delay": {"zh_name": "指令延迟", "zh_desc": "无法打出。抽到时，你本回合打出的第一张支援牌不计作支援牌。"},
	"ashen_guilt": {"zh_name": "灰烬罪咎", "zh_desc": "无法打出。回合结束时，若你本回合失去过生命，再失去 1 点生命。"},
	"shattered_focus": {"zh_name": "破碎专注", "zh_desc": "无法打出。抽到时，失去 1 点意志。"},
	"arts_bolt_plus": {"zh_name": "术式击+", "zh_desc": "造成 9 点术式伤害。"},
	"focused_ray_plus": {"zh_name": "聚焦射线+", "zh_desc": "造成 12 点术式伤害；若意志至少为 3，再造成 6 点。"},
	"stabilize_line_plus": {"zh_name": "稳定战线+", "zh_desc": "获得 10 点护盾；若本回合打出过支援牌，净化 2 个负面状态。"},
	"channel_pulse_plus": {"zh_name": "引导脉冲+", "zh_desc": "下回合开始时获得 4 点意志并抽 2 张牌。"},
	"bloodline_casting_plus": {"zh_name": "透支施术+", "zh_desc": "失去 2 点生命，获得 2 点能量。"},
	"harmonic_cut_plus": {"zh_name": "谐律切断+", "zh_desc": "造成 9 点术式伤害；若目标已有共振，抽 1 张牌。"},
	"emergency_shield_plus": {"zh_name": "应急护盾+", "zh_desc": "获得 13 点护盾。"},
	"command_sync_plus": {"zh_name": "指挥同步+", "zh_desc": "返还 1 点能量并抽 1 张牌。"},
	"rhodes_formation_plus": {"zh_name": "罗德岛阵列+", "zh_desc": "能力。每当你打出支援牌，获得 3 点护盾。（费用 0）"},
	"reckless_invocation_plus": {"zh_name": "鲁莽唤起+", "zh_desc": "获得 2 层精神负荷；对所有敌人造成 24 点术式伤害。"},
	"arc_collapse_plus": {"zh_name": "弧塌缩+", "zh_desc": "造成 18 点术式伤害；若意志至少为 4，施加 2 层易伤。"},
	"burn_will_plus": {"zh_name": "燃烧意志+", "zh_desc": "失去 3 点生命，获得 4 点意志。"},
	"black_ring_method_plus": {"zh_name": "黑环术式+", "zh_desc": "造成 14 点术式伤害；再额外造成等同精神负荷层数的术式伤害。"},
	"tactical_calm_plus": {"zh_name": "战术冷静+", "zh_desc": "抽 3 张牌。所有敌人获得虚弱。"},
	"command_overflow_plus": {"zh_name": "指令溢出+", "zh_desc": "本回合支援牌的基础效果触发两次。（费用 1）"},
	"absolute_resonance_plus": {"zh_name": "绝对共振+", "zh_desc": "能力。每当你消耗共振，获得 Echo 50%。（费用 1）"},
	"ace_last_stand_plus": {"zh_name": "Ace·最后防线+", "zh_desc": "获得 20 点护盾；若生命值不高于 30%，额外获得 2 点能量。"},
	"arc_sliver_plus": {"zh_name": "弧光切片+", "zh_desc": "造成 9 点术式伤害；若意志至少为 2，再造成 4 点。"},
	"ashes_remember_plus": {"zh_name": "灰烬铭记+", "zh_desc": "统计本战已失去的生命值，将其中 60% 转化为对所有敌人的术式伤害。"},
	"ashes_to_ashes_plus": {"zh_name": "灰归灰+", "zh_desc": "对所有敌人造成 13 点术式伤害；再按当前精神负荷对每个敌人造成等额追加伤害。"},
	"barrier_formula_plus": {"zh_name": "屏障公式+", "zh_desc": "获得 8 点护盾。"},
	"blaze_forward_breach_plus": {"zh_name": "煌·前突突破+", "zh_desc": "对所有敌人造成 12 点伤害；若本回合你失去过生命，改为 17 点。"},
	"chain_reaction_plus": {"zh_name": "连锁反应+", "zh_desc": "对所有有共振的敌人造成 11 点术式伤害。"},
	"chimera_protocol_plus": {"zh_name": "嵌合协议+", "zh_desc": "消耗全部意志与目标全部共振；每点意志造成 6 点术式伤害，每层共振造成 5 点术式伤害。（费用 2）"},
	"clear_intent_plus": {"zh_name": "澄明意图+", "zh_desc": "抽 2 张牌。若手中至少有 2 张术式牌，再获得 2 点意志并额外抽 1。"},
	"collapse_frequency_plus": {"zh_name": "频域崩塌+", "zh_desc": "消耗目标全部共振，每层造成 4 点术式伤害。"},
	"controlled_detonation_plus": {"zh_name": "受控爆裂+", "zh_desc": "最多消耗 3 点意志；每点造成 7 点术式伤害。"},
	"controlled_overload_plus": {"zh_name": "受控过载+", "zh_desc": "能力。你的过载类牌造成的自伤减半。（费用 0）"},
	"coordinated_strike_plus": {"zh_name": "协同打击+", "zh_desc": "造成 9 点伤害；若本回合打出过支援牌，再造成 7 点。"},
	"crisis_surge_plus": {"zh_name": "危机涌流+", "zh_desc": "若生命高于 50%，获得 2 点意志；否则获得 3 点意志、抽 2 张牌并获得 1 点能量。"},
	"crowned_resolve_plus": {"zh_name": "冠冕意志+", "zh_desc": "能力。每当你获得意志，获得 1 点护盾。（费用 1）"},
	"delayed_directive_plus": {"zh_name": "延迟指令+", "zh_desc": "引导：下回合抽 3 张牌，然后下一张支援牌费用 -1。"},
	"desperate_focus_plus": {"zh_name": "绝境专注+", "zh_desc": "失去 3 点生命。抽 3 张牌。"},
	"discipline_note_plus": {"zh_name": "纪律笔记+", "zh_desc": "获得 2 点意志并抽 1 张牌。"},
	"dobermann_drill_order_plus": {"zh_name": "杜宾训令+", "zh_desc": "本回合下一张攻击或术式牌 +5 伤害；若本回合已打出 2 张牌，再抽 2。"},
	"echo_conduit_plus": {"zh_name": "回响导流+", "zh_desc": "造成 13 点术式伤害。每 1 点意志额外 +1，最多 +6。"},
	"echo_lattice_plus": {"zh_name": "回响格+", "zh_desc": "获得 Echo：下一张术式牌重复 75% 基础效果。"},
	"echo_reserve_plus": {"zh_name": "回响储备+", "zh_desc": "引导：下回合获得 Echo 75%。"},
	"elite_coordination_plus": {"zh_name": "精英协同+", "zh_desc": "能力。每当你打出支援牌，下一张术式牌额外 +2 伤害。（费用 1）"},
	"ember_judgement_plus": {"zh_name": "余烬裁定+", "zh_desc": "造成 24 点术式伤害；若意志至少为 4 或精神负荷至少为 2，再造成 24 点。（费用 2）"},
	"emergency_order_plus": {"zh_name": "紧急命令+", "zh_desc": "从弃牌堆取回 1 张支援牌到手牌；本回合下一张支援牌费用 -1；抽 1 张牌。"},
	"exusiai_cover_fire_plus": {"zh_name": "能天使掩护射击+", "zh_desc": "对随机敌人造成 4 点伤害 3 次；若目标已有共振，再追加 1 次。"},
	"feedback_loop_plus": {"zh_name": "反馈回路+", "zh_desc": "若目标已有共振，获得 Echo，并再对目标施加 3 层共振。"},
	"field_command_plus": {"zh_name": "战场指令+", "zh_desc": "本回合第一次打出支援牌后，抽 2 张牌。"},
	"final_directive_plus": {"zh_name": "最终指令+", "zh_desc": "本回合你的支援、术式、战术牌彼此都视为对方类型，并抽 3 张牌。"},
	"final_vector_plus": {"zh_name": "终向量+", "zh_desc": "造成 36 点术式伤害；若意志至少为 5，再施加 2 层易伤。（费用 2）"},
	"focus_pulse_plus": {"zh_name": "聚焦脉冲+", "zh_desc": "造成 10 点术式伤害。若本回合打出过支援牌，再 +3。"},
	"forbidden_crown_plus": {"zh_name": "禁忌冠冕+", "zh_desc": "能力。你的术式牌额外造成 4 点伤害；回合结束时获得 1 层精神负荷。（费用 1）"},
	"forbidden_formula_plus": {"zh_name": "禁式+", "zh_desc": "造成 21 点术式伤害，并向弃牌堆加入 1 张灼痕。"},
	"formation_hold_plus": {"zh_name": "阵型固守+", "zh_desc": "能力。每回合第一张支援牌储存 4 点护盾至下回合。（费用 0）"},
	"frequency_lock_plus": {"zh_name": "频锁+", "zh_desc": "对目标施加 3 层共振，并锁定其本回合的共振。"},
	"frostleaf_delay_field_plus": {"zh_name": "霜叶·迟滞领域+", "zh_desc": "对敌人施加 3 层迟滞；若敌人有共振，再抽 1 张牌。"},
	"grand_equation_plus": {"zh_name": "大术式方程+", "zh_desc": "造成 11 点术式伤害；再按当前意志每点追加 3 点；然后消耗 2 点意志。"},
	"greythroat_suppression_plus": {"zh_name": "灰喉·压制射击+", "zh_desc": "造成 7 点伤害 2 次；若本回合打出过支援牌，额外再打 1 次。"},
	"guard_pulse_plus": {"zh_name": "守护脉冲+", "zh_desc": "获得 8 点护盾。"},
	"guided_fire_plus": {"zh_name": "引导火力+", "zh_desc": "造成两次 7 点术式伤害。"},
	"harmonic_dominion_plus": {"zh_name": "和声支配+", "zh_desc": "能力。共振不会自然衰减；每回合开始时，随机一名敌人获得 1 层共振。（费用 1）"},
	"harmonic_spike_plus": {"zh_name": "共振刺点+", "zh_desc": "造成 7 点术式伤害；若目标已有共振，抽 1 张牌。"},
	"landship_wide_order_plus": {"zh_name": "全舰级命令+", "zh_desc": "从支援池中调入 3 张 0 费支援牌到手牌。（费用 2）"},
	"last_argument_plus": {"zh_name": "最后论证+", "zh_desc": "造成 24 点术式伤害；若当前生命值不高于 30%，再追加 16 点术式伤害。"},
	"measured_blast_plus": {"zh_name": "定量爆发+", "zh_desc": "造成 18 点术式伤害。"},
	"medical_evac_route_plus": {"zh_name": "医疗撤离路线+", "zh_desc": "回复 11 点生命；若本回合打出过 2 张支援牌，再净化全部负面状态。"},
	"mental_tuning_plus": {"zh_name": "精神校准+", "zh_desc": "抽 3 张牌，获得 1 点意志。"},
	"mind_alignment_plus": {"zh_name": "精神校准+", "zh_desc": "抽 3 张牌。获得 1 点意志。"},
	"mind_pressure_plus": {"zh_name": "心压+", "zh_desc": "获得 3 点意志；本回合不能获得护盾。"},
	"mirrored_wave_plus": {"zh_name": "镜波+", "zh_desc": "造成 13 点术式伤害；若你拥有 Echo，再额外造成 13 点。"},
	"nerve_burn_plus": {"zh_name": "神经灼烧+", "zh_desc": "造成 11 点术式伤害，并向手牌加入 1 张过载神经。"},
	"overclock_arts_plus": {"zh_name": "过载术式+", "zh_desc": "造成 21 点术式伤害，失去 2 点生命。"},
	"overclock_casting_plus": {"zh_name": "过载施术+", "zh_desc": "本回合下一张术式牌额外造成 8 点伤害，并获得 1 层精神负荷。"},
	"pain_for_power_plus": {"zh_name": "以痛换力+", "zh_desc": "失去 1 点生命，获得 1 点意志，下一张牌费用 -1。"},
	"phase_tap_plus": {"zh_name": "相位轻触+", "zh_desc": "施加 2 层共振。抽 1 张牌。"},
	"precise_break_plus": {"zh_name": "精准裂解+", "zh_desc": "造成 11 点术式伤害；无视目标 50% 护盾。"},
	"pressure_wave_plus": {"zh_name": "压缩波+", "zh_desc": "对所有敌人造成 6 点术式伤害。"},
	"primed_arts_plus": {"zh_name": "蓄力术式+", "zh_desc": "引导：下回合你的下一张术式牌额外造成 11 点伤害。"},
	"prism_shatter_plus": {"zh_name": "棱镜破裂+", "zh_desc": "对所有有共振的敌人造成 8 点术式伤害，并各消耗 1 层共振。"},
	"pulse_scan_plus": {"zh_name": "脉冲扫描+", "zh_desc": "查看抽牌堆顶 4 张牌。"},
	"rescue_corridor_plus": {"zh_name": "救援通道+", "zh_desc": "获得 8 点护盾，并额外获得 15 金币。"},
	"resonance_burst_plus": {"zh_name": "谐振爆发+", "zh_desc": "造成 16 点术式伤害。"},
	"resonance_field_plus": {"zh_name": "共振场+", "zh_desc": "能力。敌人获得共振时，随机另一名敌人获得 1 层共振。（费用 1）"},
	"resonance_harvest_plus": {"zh_name": "共振收割+", "zh_desc": "每有一名带共振的敌人，抽 1 张牌；若抽到术式牌，其费用 -1。再额外抽 1 张。"},
	"resonance_mark_plus": {"zh_name": "共振标记+", "zh_desc": "对目标施加 4 层共振。"},
	"resonant_insight_plus": {"zh_name": "共振洞察+", "zh_desc": "若任一敌人有共振，则抽 3；否则对随机敌人施加 3 层共振。"},
	"sealed_chimera_plus": {"zh_name": "封闭嵌合+", "zh_desc": "能力。每当你获得精神负荷，也获得 1 点意志。（费用 1）"},
	"sevenfold_echo_plus": {"zh_name": "七重回响+", "zh_desc": "接下来 3 张术式牌获得 Echo 50%。"},
	"shared_burden_plus": {"zh_name": "共负其重+", "zh_desc": "能力。每回合第一次失去生命后，抽 1 张牌并获得 1 点意志。（费用 0）"},
	"signal_relay_plus": {"zh_name": "信号中继+", "zh_desc": "从抽牌堆或弃牌堆取回一张支援牌。抽 1 张牌。"},
	"singing_fracture_plus": {"zh_name": "裂唱+", "zh_desc": "对目标造成 8 点术式伤害 3 次；若目标有共振，每段再 +1。"},
	"split_tone_plus": {"zh_name": "分裂音+", "zh_desc": "造成 5 点术式伤害两次；若目标已有共振，再造成 3 点。"},
	"strategic_rotation_plus": {"zh_name": "战术轮换+", "zh_desc": "弃 1 张牌，抽 3；若弃掉的是支援牌，获得 1 点能量。"},
	"survival_reflex_plus": {"zh_name": "求生反射+", "zh_desc": "若当前生命值不高于 40%，回复 8 点生命并移除 3 层精神负荷。"},
	"tactical_briefing_plus": {"zh_name": "战术简报+", "zh_desc": "抽 3 张牌；本回合下一张支援牌费用 -1。"},
	"tactical_encirclement_plus": {"zh_name": "战术合围+", "zh_desc": "造成 16 点术式伤害；本回合每打出 1 张支援牌，再追加 5 点术式伤害。"},
	"tactical_network_plus": {"zh_name": "战术网络+", "zh_desc": "能力。每回合第一次打出支援牌时，获得 1 点能量。（费用 0）"},
	"tactical_reorder_plus": {"zh_name": "战术重整+", "zh_desc": "抽 3 张牌。若本回合打出过术式牌，获得 1 点意志。"},
	"terminal_appeal_plus": {"zh_name": "终端诉求+", "zh_desc": "造成 16 点术式伤害；本战每失去过 10 点生命，额外 +5。"},
	"terminal_charge_plus": {"zh_name": "终端充能+", "zh_desc": "回合结束时对随机敌人造成 16 点术式伤害；获得 1 层精神负荷。"},
	"the_cost_of_mercy_plus": {"zh_name": "仁慈的代价+", "zh_desc": "回复 16 点生命，获得 3 点意志，并获得 2 层精神负荷。"},
	"thought_acceleration_plus": {"zh_name": "思维加速+", "zh_desc": "获得 3 点意志。本回合下一张术式牌费用 -1。"},
	"twin_channel_plus": {"zh_name": "双通道+", "zh_desc": "获得 2 点意志。引导：下回合获得 3 点意志并抽 1 张牌。"},
	"unified_battleplan_plus": {"zh_name": "统一战斗计划+", "zh_desc": "本回合所有支援牌费用 -1；本回合第一次打出支援牌后抽 3 张牌。"},
	"unstable_channel_plus": {"zh_name": "不稳定引导+", "zh_desc": "引导：下回合开始时对目标造成 16 点术式伤害并获得 3 点意志；获得 1 层精神负荷。"},
	"voice_of_the_leader_plus": {"zh_name": "领袖之声+", "zh_desc": "能力。本战中每打出第 2 张支援牌时，生成 1 张 0 费临时术式牌。（费用 1）"},
	"voice_of_the_team_plus": {"zh_name": "团队之声+", "zh_desc": "能力。每当你在同一回合打出第 2 张支援牌时，生成 1 张 0 费临时术式牌。（费用 1）"},
	"widened_spectrum_plus": {"zh_name": "扩谱+", "zh_desc": "对所有敌人造成 9 点术式伤害；若意志至少为 3，再额外造成 4 点。"},
	"will_transfusion_plus": {"zh_name": "意志转灌+", "zh_desc": "消耗 2 点意志，抽 3 张牌并获得 1 点能量。"},
	"zero_range_cast_plus": {"zh_name": "零距施法+", "zh_desc": "造成 18 点术式伤害；若目标本回合受到过支援伤害，再追加 8 点。"}
}

var module_text := {
	"ashen_thread": {"zh_name": "灰烬丝线", "zh_desc": "每次主动自伤后，你的下一张术式牌额外造成 3 点伤害。"},
	"ashen_halo": {"zh_name": "灰烬光环", "zh_desc": "每场战斗第一次进入 Overload 时，不受下一次 Overload 结算惩罚，并抽 2。"},
	"crown_of_responsibility": {"zh_name": "责任之冠", "zh_desc": "Will 上限 +3。回合结束失去 1 点生命。"},
	"dobermann_manual": {"zh_name": "杜宾训练手册", "zh_desc": "基础牌额外获得 1 点数值。"},
	"echo_pin": {"zh_name": "回响别针", "zh_desc": "每场战斗第一次获得 Echo 时，再抽 1。"},
	"field_command_badge": {"zh_name": "战地指挥徽章", "zh_desc": "每回合第一次支援联动会返还 1 点能量。"},
	"field_medic_pack": {"zh_name": "战地医疗包", "zh_desc": "每场战斗开始时恢复 4 点生命。"},
	"field_stabilizer": {"zh_name": "战线稳定器", "zh_desc": "回合结束若有未用能量，获得等量护盾。"},
	"kaltsits_log": {"zh_name": "凯尔希记录", "zh_desc": "每场战斗第一次使用 Channel 牌时，立即抽 2。"},
	"nearl_crest": {"zh_name": "临光护徽", "zh_desc": "每场战斗的第一回合获得 8 点护盾；获得护盾时额外 +20%。"},
	"originium_fragment": {"zh_name": "源石碎片", "zh_desc": "你每回合第一张 Arts 牌 +2 伤害。"},
	"pain_converter": {"zh_name": "痛觉换流器", "zh_desc": "每次失去 HP 后，下张 Arts 牌 +1 伤害，本回合累计。"},
	"recorder_of_resolve": {"zh_name": "意志记录仪", "zh_desc": "战斗开始时获得 1 Will。"},
	"reserve_battery": {"zh_name": "备用电池", "zh_desc": "每场战斗第一回合额外获得 1 点能量。"},
	"resonance_anchor": {"zh_name": "共振锚", "zh_desc": "敌人的 Resonance 不会在敌人回合结束时减少。"},
	"resonance_prism": {"zh_name": "共振棱镜", "zh_desc": "每次你消耗 Resonance，随机 1 张手牌费用 -1。"},
	"rhodes_tactical_console": {"zh_name": "罗德岛战术终端", "zh_desc": "代表罗德岛级别的指挥权限，并计入隐藏路线条件。"},
	"signal_booster": {"zh_name": "信号增幅器", "zh_desc": "每场战斗打出的第一张支援牌额外抽 1 张牌。"},
	"support_grid": {"zh_name": "支援阵列", "zh_desc": "你每回合第一张 Support 牌触发两次基础效果。"},
	"worn_terminal": {"zh_name": "旧通讯终端", "zh_desc": "事件节点更容易出现第 3 个选项。"}
}

var charm_text := {
	"rabbit_emblem": {"zh_name": "兔徽", "zh_desc": "开局额外获得 1 张【精神校准】。"},
	"rhodes_pin": {"zh_name": "罗德岛别针", "zh_desc": "每场战斗第一次打出支援牌时，返还 1 点能量。"},
	"broken_horn_token": {"zh_name": "断角徽饰", "zh_desc": "每次过载结算时，获得 4 点护盾。"},
	"silent_bell": {"zh_name": "静铃", "zh_desc": "每场战斗第一次施加共振时，额外再施加 2 层。"},
	"sterile_strap": {"zh_name": "无菌束带", "zh_desc": "所有治疗效果提高 30%。"},
	"burnt_paper_charm": {"zh_name": "灰纸挂坠", "zh_desc": "每当灼痕被加入你的牌堆或牌区时，抽 1 张牌。"},
	"operators_thread": {"zh_name": "干员系绳", "zh_desc": "每回合打出第二张支援牌后，下一张牌费用 -1。"},
	"embershard": {"zh_name": "余烬片", "zh_desc": "每当你消耗 3 点或以上意志时，获得 50% 回响。"}
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
	"w_boss": {"zh_name": "W"},
	"ash_echo": {"zh_name": "灰烬回响"},
	"reunion_bladefighter": {"zh_name": "整合运动刀手"},
	"stone_throwing_rioter": {"zh_name": "投石暴徒"},
	"molotov_thrower": {"zh_name": "燃烧瓶投掷手"},
	"demolition_runner": {"zh_name": "临时爆破兵"},
	"reunion_medic": {"zh_name": "整合医疗协助员"},
	"mortar_crossbow_operator": {"zh_name": "迫击弩机操作员"},
	"infected_fanatic": {"zh_name": "感染狂徒"},
	"drone_support_unit": {"zh_name": "机动无人机"},
	"originium_porter": {"zh_name": "源石搬运工"},
	"alley_arsonist": {"zh_name": "街区纵火者"},
	"disguised_scout": {"zh_name": "伪装侦察员"},
	"reunion_bugler": {"zh_name": "整合运动号手"},
	"frostbite_stalker": {"zh_name": "冻伤潜伏者"},
	"originium_pollutant": {"zh_name": "源石污染体"},
	"originium_slug": {"zh_name": "源石虫"},
	"originium_slug_alpha": {"zh_name": "源石虫 α"},
	"blazing_originium_slug": {"zh_name": "高能源石虫"},
	"acid_originium_slug": {"zh_name": "酸液源石虫"},
	"slug_broodmother": {"zh_name": "增殖源石虫母体"},
	"barricade_heavy_leader": {"zh_name": "路障重装头目"},
	"execution_demolitionist": {"zh_name": "处刑爆破专家"},
	"hunter_sniper_officer": {"zh_name": "猎杀狙击官"},
	"formation_caster": {"zh_name": "群聚术阵师"},
	"frenzied_smasher": {"zh_name": "狂化粉碎者"},
	"snowfield_ambush_captain": {"zh_name": "雪原潜袭队长"},
	"slug_hive_colossus": {"zh_name": "源石虫群聚合体"},
	"chernobog_suppression_convoy": {"zh_name": "切尔诺伯格镇压车组"},
	"originium_aberration_cluster": {"zh_name": "源石畸变聚合体"},
	"reunion_assault_commander": {"zh_name": "整合运动突击指挥官"},
	"frost_disaster_vanguard": {"zh_name": "寒灾先遣统领"}
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
	"Lockdown Slam 10": {"zh": "源石重击 10", "en": "Lockdown Slam 10"},
	"Barrier Fire 8": {"zh": "屏障火力 8", "en": "Barrier Fire 8"},
	"Containment Pulse": {"zh": "封控脉冲", "en": "Containment Pulse"},
	"Crush 8": {"zh": "重击 8", "en": "Crush 8"},
	"Bash 7": {"zh": "盾击 7", "en": "Bash 7"},
	"Originium Pulse 10": {"zh": "源石脉冲 10", "en": "Originium Pulse 10"},
	"Panic Static": {"zh": "恐慌静电", "en": "Panic Static"},
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
	"Double Charge": {"zh": "双重装药", "en": "Double Charge"},
	"Shrapnel Sweep": {"zh": "破片横扫", "en": "Shrapnel Sweep"},
	"Stage Sabotage": {"zh": "舞台破坏", "en": "Stage Sabotage"},
	"Detonation Line": {"zh": "引爆线", "en": "Detonation Line"},
	"Improvised Killzone": {"zh": "临时杀伤区", "en": "Improvised Killzone"},
	"Suppressing Fire": {"zh": "压制火力", "en": "Suppressing Fire"},
	"Feint Barrage": {"zh": "佯攻弹幕", "en": "Feint Barrage"},
	"Static Interference": {"zh": "静电干扰", "en": "Static Interference"},
	"Pressure Shot": {"zh": "施压射击", "en": "Pressure Shot"},
	"Threaten and Laugh": {"zh": "戏弄与威胁", "en": "Threaten and Laugh"},
	"Double Slash 4x2": {"zh": "双重斩击 4x2", "en": "Double Slash 4x2"},
	"Punish 10": {"zh": "惩罚斩击 10", "en": "Punish 10"},
	"Stone Throw 9": {"zh": "投石 9", "en": "Stone Throw 9"},
	"Shieldbreaker Stone 12": {"zh": "破盾投石 12", "en": "Shieldbreaker Stone 12"},
	"Molotov Burn": {"zh": "燃烧瓶灼烧", "en": "Molotov Burn"},
	"Fire Splash 6": {"zh": "火焰溅射 6", "en": "Fire Splash 6"},
	"Plant Delayed Charge": {"zh": "安置延时炸药", "en": "Plant Delayed Charge"},
	"Suicide Blast 14": {"zh": "自爆 14", "en": "Suicide Blast 14"},
	"Emergency Treatment": {"zh": "紧急治疗", "en": "Emergency Treatment"},
	"Defensive Shot 5": {"zh": "防卫射击 5", "en": "Defensive Shot 5"},
	"Mortar Bolt 11": {"zh": "迫击弩矢 11", "en": "Mortar Bolt 11"},
	"Area Suppression 5": {"zh": "区域压制 5", "en": "Area Suppression 5"},
	"Reload Mortar": {"zh": "迫击装填", "en": "Reload Mortar"},
	"Frenzied Blow 10": {"zh": "狂乱打击 10", "en": "Frenzied Blow 10"},
	"Blood Frenzy": {"zh": "血性狂化", "en": "Blood Frenzy"},
	"Drone Burst 3x3": {"zh": "无人机连射 3x3", "en": "Drone Burst 3x3"},
	"Drone Cover": {"zh": "无人机掩护", "en": "Drone Cover"},
	"Move Originium Cargo": {"zh": "搬运源石货箱", "en": "Move Originium Cargo"},
	"Cargo Smash 7": {"zh": "货箱重击 7", "en": "Cargo Smash 7"},
	"Alley Fire 6": {"zh": "街巷纵火 6", "en": "Alley Fire 6"},
	"Spread Flames": {"zh": "扩散火焰", "en": "Spread Flames"},
	"False Guard": {"zh": "伪装防御", "en": "False Guard"},
	"Sudden Stab 12": {"zh": "突刺 12", "en": "Sudden Stab 12"},
	"War Horn": {"zh": "战地号令", "en": "War Horn"},
	"Short Blade 5": {"zh": "短刃 5", "en": "Short Blade 5"},
	"Chilling Cut 6": {"zh": "冻伤切割 6", "en": "Chilling Cut 6"},
	"Frost Ambush 10": {"zh": "霜冻伏击 10", "en": "Frost Ambush 10"},
	"Mental Noise": {"zh": "精神噪音", "en": "Mental Noise"},
	"Pollution Arts 9": {"zh": "污染术式 9", "en": "Pollution Arts 9"},
	"Slug Bite 4": {"zh": "源石虫啃咬 4", "en": "Slug Bite 4"},
	"Swarm Bite 5": {"zh": "虫群啃咬 5", "en": "Swarm Bite 5"},
	"Alpha Bite 6": {"zh": "α 啃咬 6", "en": "Alpha Bite 6"},
	"Harden Shell": {"zh": "硬化外壳", "en": "Harden Shell"},
	"Blazing Bite 3": {"zh": "高能啃咬 3", "en": "Blazing Bite 3"},
	"Death Heat": {"zh": "死亡高热", "en": "Death Heat"},
	"Acid Bite 5": {"zh": "酸液啃咬 5", "en": "Acid Bite 5"},
	"Acid Spray": {"zh": "酸液喷洒", "en": "Acid Spray"},
	"Brood Call": {"zh": "母体呼唤", "en": "Brood Call"},
	"Mother Bite 7": {"zh": "母体啃咬 7", "en": "Mother Bite 7"},
	"Shield Counter 8": {"zh": "盾反 8", "en": "Shield Counter 8"},
	"Roadblock Crash 12": {"zh": "路障冲撞 12", "en": "Roadblock Crash 12"},
	"Raise Barricade": {"zh": "架设路障", "en": "Raise Barricade"},
	"Execution Charge": {"zh": "处刑炸药", "en": "Execution Charge"},
	"Remote Detonation 15": {"zh": "遥控引爆 15", "en": "Remote Detonation 15"},
	"Aim for Kill": {"zh": "瞄准处刑", "en": "Aim for Kill"},
	"Kill Shot 24": {"zh": "猎杀射击 24", "en": "Kill Shot 24"},
	"Arts Formation": {"zh": "群聚术阵", "en": "Arts Formation"},
	"Formation Pulse 6": {"zh": "术阵脉冲 6", "en": "Formation Pulse 6"},
	"Focused Arts 12": {"zh": "聚焦术式 12", "en": "Focused Arts 12"},
	"Heavy Charge": {"zh": "重锤蓄力", "en": "Heavy Charge"},
	"Crushing Hammer 28": {"zh": "粉碎重锤 28", "en": "Crushing Hammer 28"},
	"Freezing Cut 8": {"zh": "冻结切割 8", "en": "Freezing Cut 8"},
	"Low Temperature Zone": {"zh": "低温区", "en": "Low Temperature Zone"},
	"Cold Followup 10": {"zh": "寒冷追击 10", "en": "Cold Followup 10"},
	"Summon Slug Swarm": {"zh": "召唤源石虫群", "en": "Summon Slug Swarm"},
	"Hive Crush 10": {"zh": "虫群聚合重击 10", "en": "Hive Crush 10"},
	"Deploy Escort": {"zh": "部署护卫", "en": "Deploy Escort"},
	"Suppression Cannon 18": {"zh": "镇压炮击 18", "en": "Suppression Cannon 18"},
	"Armored Ram 12": {"zh": "装甲冲撞 12", "en": "Armored Ram 12"},
	"Aberration Noise": {"zh": "畸变噪音", "en": "Aberration Noise"},
	"Mutation Pulse 22": {"zh": "畸变脉冲 22", "en": "Mutation Pulse 22"},
	"Regenerate Core": {"zh": "核心再生", "en": "Regenerate Core"},
	"All-Out Command": {"zh": "全军号令", "en": "All-Out Command"},
	"Focused Assault 16": {"zh": "集火突击 16", "en": "Focused Assault 16"},
	"Advance Line 12": {"zh": "阵线推进 12", "en": "Advance Line 12"},
	"Frost Command 14": {"zh": "寒灾号令 14", "en": "Frost Command 14"},
	"Cold Punish 10": {"zh": "低温惩罚 10", "en": "Cold Punish 10"},
	"Unknown": {"zh": "未知", "en": "Unknown"},
	"Fortify": {"zh": "加固防线", "en": "Fortify"},
	"Brace": {"zh": "架盾防御", "en": "Brace"},
	"Enfeeble": {"zh": "削弱意志", "en": "Enfeeble"},
	"Inject Doubt": {"zh": "注入疑虑", "en": "Inject Doubt"},
	"Expose Weakness": {"zh": "暴露弱点", "en": "Expose Weakness"},
	"Disorienting Gas": {"zh": "迷幻毒雾", "en": "Disorienting Gas"},
	"Incantation": {"zh": "蓄力咏唱", "en": "Incantation"},
	"Channel Power": {"zh": "聚能引导", "en": "Channel Power"}
}

var event_text := {
	"temporary_ward": {
		"zh_title": "临时病房",
		"zh_body": "这地方原本像是个小店，现在临时收拾成了病房。破帘子挂在歪掉的货架上，灯也不够亮，照得人脸色都发白。药剂一支支摆在木箱上，可再摆整齐也不会凭空多出来。\n\n躺着的人里有刚从骚乱里拖回来的平民，也有还惦记着想站回前线的罗德岛干员。阿米娅听着医疗汇报，目光却老往街外飘。她心里很清楚，下一场麻烦随时会来，可你们手上的东西，救不了所有人。\n\n现在就看你怎么选了。花点钱把病房先稳住，今晚大概能多留下几个人。平均分，听起来公平，但谁都拿不到足够的量。要是把药全留给前线，那下一场会轻松些，可这地方留下来的安静，也不会那么快过去。"
	},
	"dobermann_inspection": {
		"zh_title": "杜宾的检查",
		"zh_body": "队伍刚喘口气，杜宾就把人叫停了，说要看看你现在这套构筑。她翻牌的表情，跟检查一把保养没做好的武器差不多，越看眉头越紧。\n\n在她眼里，犹豫就是拖后腿，不够果断就是纪律出问题。她不在乎一张牌看起来是不是「温和」，她只在乎真到局面崩的时候，这套东西顶不顶得住。阿米娅没顶嘴，但那话听着显然不轻。\n\n杜宾把路说得很直白。要么砍掉软的，牌组收紧一点。要么干脆更凶一点，别老想着两头都顾。再不然，就别说了，带着这点不舒服继续往前走。"
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
	},
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
	"You deny W the performance she wants and keep the squad intact for now. Still, the sense that an opportunity was left in the smoke lingers longer than anyone says aloud.": "你没顺着 W 的意思陪她演，队伍也算完整地撤了下来。只是那种「好像错过了点什么」的感觉，还是一直吊在心里。"
}


var character_profiles := {
	"amiya": {
		"zh_name": "阿米娅",
		"en_name": "Amiya",
		"zh_header": "Amiya | 罗德岛领袖",
		"en_header": "Amiya | Leader of Rhodes Island",
		"zh_stats": "生命 72/72    起始能量 3    核心资源：意志",
		"en_stats": "HP 72/72    Starting Energy 3    Core Resource: Will",
		"zh_intro": "阿米娅是罗德岛的年轻领导者，擅长强力术式，并会亲自前往前线解决问题。在这套构筑中，她的定位是高成长、高代价的术师领袖，既能打出爆发伤害，也能通过支援牌带动全局节奏。",
		"en_intro": "Amiya is Rhodes Island's young leader, wielding powerful Arts and stepping onto the front lines herself. In this deckbuilder she serves as a high-growth, high-cost caster leader who mixes burst damage with support-driven tempo.",
		"zh_mechanic": "特有机制：意志（Will）\n意志是阿米娅的专属资源。部分卡牌会积累意志，意志越高，她的高阶术式就越强，像终结牌和爆发牌都会随着意志提升伤害。\n但意志并不是越高越好：它代表精神负荷与承担的代价，部分牌会消耗意志，某些过载打法还会带来自伤或节奏风险。简单来说，意志就是阿米娅在战斗中把「责任」转化为力量的核心系统。",
		"en_mechanic": "Signature Mechanic: Will\nWill is Amiya's exclusive resource. Several cards build Will, and the more Will she has, the stronger her advanced Arts become. Finishers and burst spells scale directly with it.\nBut high Will comes with pressure: some cards spend it, and overload-style lines can cause self-damage or tempo loss. In short, Will is the system that turns Amiya's burden into combat power."
	},
	"nearl": {
		"zh_name": "临光",
		"en_name": "Nearl",
		"zh_header": "Nearl | 耀骑士防线",
		"en_header": "Nearl | Radiant Frontline",
		"zh_stats": "生命 80/80    起始能量 3    核心倾向：防御支援",
		"en_stats": "HP 80/80    Starting Energy 3    Core Focus: Defense Support",
		"zh_intro": "临光不靠花哨的爆发，而是用稳定护盾、治疗与支援牌把局面慢慢拉回自己这边。她的起始牌组更厚、更稳，适合把一场仗打成可控消耗战。",
		"en_intro": "Nearl does not win through flashy bursts. She stabilizes fights with Block, healing, and support cards until the battlefield bends back in her favor. Her starter deck is sturdier and more methodical.",
		"zh_mechanic": "特有倾向：防线运营\n临光的首发卡池围绕护盾、救援和支援运营展开。她不像阿米娅那样追求极限爆发，而是通过高容错的防御节奏，把强敌拖进对自己有利的回合。",
		"en_mechanic": "Signature Focus: Defensive Tempo\nNearl's opening pool leans into Block, rescue effects, and support sequencing. Instead of chasing burst ceilings, she turns tough fights into controlled, favorable turns."
	},
	"exusiai": {
		"zh_name": "能天使",
		"en_name": "Exusiai",
		"zh_header": "Exusiai | 快速火力投射",
		"en_header": "Exusiai | Rapid Fire Tempo",
		"zh_stats": "生命 68/68    起始能量 3    核心倾向：多段速攻",
		"en_stats": "HP 68/68    Starting Energy 3    Core Focus: Multi-hit Tempo",
		"zh_intro": "能天使的首发卡组更轻、更快，重点是连续打牌、多段命中和返还能量。她不靠厚防线，而是把战斗节奏压快，争取在敌人起势前把场面打穿。",
		"en_intro": "Exusiai opens with a lighter, faster deck built around chained plays, multi-hit attacks, and energy refunds. She does not tank through fights; she races ahead of enemy tempo instead.",
		"zh_mechanic": "特有倾向：速攻连射\n多段伤害、低费连段和节奏加速是能天使的主轴。她更适合处理虫群、后排脆皮和需要立刻点掉的高威胁目标。",
		"en_mechanic": "Signature Focus: Rapid Volley\nMulti-hit damage, cheap chains, and tempo acceleration define Exusiai's game plan. She excels at clearing swarms and deleting fragile backline threats early."
	},
	"kaltsit": {
		"zh_name": "凯尔希",
		"en_name": "Kal'tsit",
		"zh_header": "Kal'tsit | 冷静战术解析",
		"en_header": "Kal'tsit | Cold Tactical Analysis",
		"zh_stats": "生命 70/70    起始能量 3    核心倾向：战术控制",
		"en_stats": "HP 70/70    Starting Energy 3    Core Focus: Tactical Control",
		"zh_intro": "凯尔希的首发套牌偏向调度、检索、引导与回合管理。她不像临光那么稳，也不像能天使那么快，但更擅长把关键牌和关键回合握在自己手里。",
		"en_intro": "Kal'tsit begins with a deck built around routing, tutoring, channels, and turn management. She is neither as sturdy as Nearl nor as explosive as Exusiai, but she controls when key turns happen.",
		"zh_mechanic": "特有倾向：战术调度\n凯尔希依赖抽牌、检索、引导与支援线，让牌序和回合规划都更可控。她的强点不是正面硬顶，而是把局面提前拆开。",
		"en_mechanic": "Signature Focus: Tactical Routing\nKal'tsit leans on draw, tutoring, channels, and support sequencing to keep card order and turn structure under control. Her strength is pre-solving the fight rather than brute-forcing it."
	}
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

func character_name(character_id: String, fallback: String = "") -> String:
	var entry: Dictionary = character_profiles.get(character_id, {})
	if entry.is_empty():
		return fallback if not fallback.is_empty() else character_id.capitalize()
	return String(entry.get("zh_name" if current_language == LANG_ZH else "en_name", fallback))

func character_header(character_id: String, fallback: String = "") -> String:
	var entry: Dictionary = character_profiles.get(character_id, {})
	if entry.is_empty():
		return fallback if not fallback.is_empty() else character_name(character_id, character_id)
	return String(entry.get("zh_header" if current_language == LANG_ZH else "en_header", fallback))

func character_stats(character_id: String, fallback: String = "") -> String:
	var entry: Dictionary = character_profiles.get(character_id, {})
	if entry.is_empty():
		return fallback
	return String(entry.get("zh_stats" if current_language == LANG_ZH else "en_stats", fallback))

func character_intro(character_id: String, fallback: String = "") -> String:
	var entry: Dictionary = character_profiles.get(character_id, {})
	if entry.is_empty():
		return fallback
	return String(entry.get("zh_intro" if current_language == LANG_ZH else "en_intro", fallback))

func character_mechanic(character_id: String, fallback: String = "") -> String:
	var entry: Dictionary = character_profiles.get(character_id, {})
	if entry.is_empty():
		return fallback
	return String(entry.get("zh_mechanic" if current_language == LANG_ZH else "en_mechanic", fallback))

func active_character_name() -> String:
	if RunManager.character == null:
		return character_name("amiya", "Amiya")
	return character_name(RunManager.character.id, RunManager.character.display_name)

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

func charm_name(charm_data: CharmData) -> String:
	if charm_data == null:
		return ""
	if current_language == LANG_ZH and charm_text.has(charm_data.id):
		return String(charm_text[charm_data.id].get("zh_name", charm_data.display_name))
	return charm_data.display_name

func charm_name_by_id(charm_id: String) -> String:
	if current_language == LANG_ZH and charm_text.has(charm_id):
		return String(charm_text[charm_id].get("zh_name", charm_id))
	var charm_db: Dictionary = Util.load_charm_db()
	if charm_db.has(charm_id):
		return (charm_db[charm_id] as CharmData).display_name
	return charm_id

func charm_description(charm_data: CharmData) -> String:
	if charm_data == null:
		return ""
	if current_language == LANG_ZH and charm_text.has(charm_data.id):
		return String(charm_text[charm_data.id].get("zh_desc", charm_data.description))
	return charm_data.description

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
		"Infected":
			return "感染者"
		"Drone":
			return "无人机"
		"Originium":
			return "源石"
		"Slug":
			return "源石虫"
		"Burn":
			return "灼烧"
		"Bomb":
			return "爆破"
		"Support":
			return "支援"
		"Trick":
			return "欺骗"
		"Frost":
			return "寒冷"
		"Acid":
			return "酸液"
		"Hidden":
			return "隐藏"
	return tag

func ai_profile_name(ai_profile: String) -> String:
	match ai_profile:
		"basic":
			return text("codex.ai_basic")
		"w_boss":
			return text("codex.ai_w_boss")
		"tank":
			return text("codex.ai_tank")
		"debuffer":
			return text("codex.ai_debuffer")
		"caster":
			return text("codex.ai_caster")
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
