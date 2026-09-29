class_name GameData
extends RefCounted

const REALMS = [
	{"name": "炼气", "desc": "引气入体，洗练凡躯"},
	{"name": "筑基", "desc": "道基初成，寿元渐长"},
	{"name": "金丹", "desc": "丹成一粒，照彻灵台"},
	{"name": "元婴", "desc": "神胎自生，出入青冥"},
	{"name": "化神", "desc": "神识通玄，一念千里"},
	{"name": "炼虚", "desc": "炼神返虚，洞见万象"},
	{"name": "合体", "desc": "形神相合，道法自然"},
	{"name": "大乘", "desc": "道果圆满，静候天门"},
	{"name": "渡劫", "desc": "九霄雷落，生死一线"},
	{"name": "真仙", "desc": "超凡入圣，与天同寿"},
]

const STAGES = ["初期", "中期", "后期", "圆满"]

const QUALITIES = [
	{"name": "凡品", "color": Color("#879a95"), "mult": 1.0, "affixes": 0, "weight": 42.0},
	{"name": "良品", "color": Color("#5f9d7c"), "mult": 1.25, "affixes": 1, "weight": 25.0},
	{"name": "上品", "color": Color("#4a8fb8"), "mult": 1.6, "affixes": 1, "weight": 15.0},
	{"name": "极品", "color": Color("#7561bd"), "mult": 2.05, "affixes": 2, "weight": 9.0},
	{"name": "玄品", "color": Color("#b15aaa"), "mult": 2.7, "affixes": 2, "weight": 5.0},
	{"name": "地品", "color": Color("#d0783d"), "mult": 3.5, "affixes": 3, "weight": 2.5},
	{"name": "天品", "color": Color("#d5a52c"), "mult": 4.7, "affixes": 3, "weight": 1.2},
	{"name": "仙品", "color": Color("#e9d7a0"), "mult": 6.5, "affixes": 4, "weight": 0.3},
]

const BUILDINGS = [
	{"id": "hall", "name": "太虚殿", "icon": "殿", "base_cost": 120.0, "desc": "提升宗门品阶与全局产能"},
	{"id": "field", "name": "灵田", "icon": "田", "base_cost": 80.0, "desc": "持续产出灵药"},
	{"id": "alchemy", "name": "丹房", "icon": "丹", "base_cost": 100.0, "desc": "炼制突破与修炼丹药"},
	{"id": "mine", "name": "灵矿", "icon": "矿", "base_cost": 95.0, "desc": "产出灵石与炼器矿材"},
	{"id": "library", "name": "藏经阁", "icon": "经", "base_cost": 140.0, "desc": "提高修炼效率与悟性"},
]

const DISCIPLES = [
	{"id": "shen", "name": "沈青崖", "path": "剑修", "talent": "御剑", "portrait": "res://assets/art/shen_qingya.png", "bonus": "expedition"},
	{"id": "ning", "name": "宁知微", "path": "丹修", "talent": "药理", "portrait": "res://assets/art/ning_zhiwei.png", "bonus": "alchemy"},
	{"id": "lu", "name": "陆无咎", "path": "符修", "talent": "灵机", "portrait": "res://assets/art/lu_wujiu.png", "bonus": "library"},
]

const RECIPES = [
	{"id": "qi", "name": "聚气丹", "herbs": 30.0, "stones": 20.0, "duration": 12.0, "effect": "修为 +120"},
	{"id": "foundation", "name": "筑基丹", "herbs": 90.0, "stones": 65.0, "duration": 25.0, "effect": "突破成功率提高"},
	{"id": "spirit", "name": "养神丹", "herbs": 140.0, "stones": 110.0, "duration": 40.0, "effect": "修为 +900"},
	{"id": "marrow", "name": "洗髓丹", "herbs": 240.0, "stones": 180.0, "duration": 65.0, "effect": "弟子战力永久提升"},
	{"id": "void", "name": "破虚丹", "herbs": 520.0, "stones": 420.0, "duration": 95.0, "effect": "高境界突破辅助"},
	{"id": "immortal", "name": "九转仙丹", "herbs": 1200.0, "stones": 980.0, "duration": 150.0, "effect": "真仙境界突破辅助"},
]

const EXPEDITIONS = [
	{"id": "bamboo", "name": "青竹秘境", "realm": 0, "duration": 18.0, "power": 80, "reward": 1.0},
	{"id": "cave", "name": "玄阴古洞", "realm": 1, "duration": 28.0, "power": 170, "reward": 1.5},
	{"id": "ruins", "name": "离火遗墟", "realm": 2, "duration": 42.0, "power": 360, "reward": 2.1},
	{"id": "sea", "name": "云梦泽", "realm": 3, "duration": 58.0, "power": 700, "reward": 2.9},
	{"id": "palace", "name": "北斗天宫", "realm": 4, "duration": 78.0, "power": 1300, "reward": 4.0},
	{"id": "void", "name": "虚空裂隙", "realm": 5, "duration": 105.0, "power": 2500, "reward": 5.5},
	{"id": "tower", "name": "万法仙塔", "realm": 7, "duration": 138.0, "power": 5200, "reward": 7.5},
	{"id": "gate", "name": "天门古路", "realm": 8, "duration": 180.0, "power": 9200, "reward": 10.0},
]

const AFFIXES = ["攻击", "防御", "悟性", "根骨", "气运", "修炼速度", "远征收益", "炼丹品相"]

static func all_items() -> Array:
	var categories = {
		"武器": ["青锋剑", "流云剑", "赤霄剑", "玄铁重剑", "七星剑", "太乙拂尘", "惊雷枪", "龙渊刀", "无相扇", "仙陨剑"],
		"防具": ["青竹袍", "云纹衣", "玄龟甲", "赤霞披风", "星罗法衣", "天蚕宝衣", "龙鳞甲", "太清道袍", "九曜冠", "仙羽履"],
		"法宝": ["镇魂铃", "乾坤镜", "碧玉葫芦", "紫金炉", "山河印", "玲珑塔", "缚龙索", "定海珠", "混元幡", "太虚盘"],
		"功法": ["引气诀", "青木心法", "玄火经", "太阴真诀", "御剑术", "五雷正法", "星衍术", "无相经", "太虚剑典", "羽化仙章"],
		"丹药": ["聚气丹", "筑基丹", "养神丹", "洗髓丹", "凝婴丹", "化神丹", "破虚丹", "大乘丹", "渡厄丹", "九转仙丹"],
		"药材": ["凝露草", "青灵花", "赤阳果", "月华藤", "紫芝", "龙血参", "七星莲", "凤凰木", "太岁灵髓", "仙露琼浆"],
		"矿材": ["青石", "赤铜", "寒铁", "玄铁", "星银", "紫金", "陨铁", "龙骨晶", "太虚石", "仙玉"],
		"奇物": ["残缺玉简", "古修令牌", "无字天书", "剑冢石碑", "天机罗盘", "龙脉灵核", "混沌碎片", "雷劫余烬", "飞升台残石", "仙界道标"],
	}
	var result: Array = []
	var index := 0
	for category in categories:
		for item_name in categories[category]:
			result.append({"id": "item_%03d" % index, "name": item_name, "category": category, "tier": index % 10})
			index += 1
	return result

