extends Node

signal changed
signal notice(text: String)

const SAVE_VERSION := 1
var resources := {"stones": 980.0, "herbs": 180.0, "ore": 90.0, "cultivation": 0.0, "fortune": 12.0}
var buildings := {"hall": 1, "field": 1, "alchemy": 1, "mine": 1, "library": 1}
var disciples: Array = []
var inventory: Array = []
var realm_index := 0
var realm_stage := 0
var active_recipe := {}
var expedition := {}
var logs: Array[String] = []
var offline_summary := ""
var _tick_accumulator := 0.0
var _save_accumulator := 0.0

func _ready() -> void:
	randomize()
	_load_or_create()
	set_process(true)

func _process(delta: float) -> void:
	_tick_accumulator += delta
	_save_accumulator += delta
	if _tick_accumulator >= 1.0:
		var seconds: float = floor(_tick_accumulator)
		_tick_accumulator -= seconds
		advance_time(seconds)
	if _save_accumulator >= 10.0:
		_save_accumulator = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

func _new_game() -> void:
	disciples.clear()
	for i in GameData.DISCIPLES.size():
		var base = GameData.DISCIPLES[i]
		disciples.append({"id": base.id, "name": base.name, "path": base.path, "assignment": i + 1, "power": 100 + i * 24, "level": 1})
	inventory.clear()
	for i in 6:
		inventory.append(_generate_item(0, i < 2))
	_add_log("太玄宗重开山门，三名弟子已入宗。")

func _load_or_create() -> void:
	var data = SaveManager.load_data()
	if data.is_empty():
		_new_game()
		return
	resources = data.get("resources", resources)
	buildings = data.get("buildings", buildings)
	disciples = data.get("disciples", [])
	inventory = data.get("inventory", [])
	realm_index = int(data.get("realm_index", 0))
	realm_stage = int(data.get("realm_stage", 0))
	active_recipe = data.get("active_recipe", {})
	expedition = data.get("expedition", {})
	logs.assign(data.get("logs", []))
	if disciples.is_empty():
		_new_game()
	var last_time := float(data.get("saved_at", Time.get_unix_time_from_system()))
	var elapsed: float = clamp(Time.get_unix_time_from_system() - last_time, 0.0, 28800.0)
	if elapsed >= 5.0:
		var before_stones := float(resources.stones)
		var before_herbs := float(resources.herbs)
		advance_time(elapsed, false)
		offline_summary = "闭关 %s\n灵石 +%s\n药材 +%s\n修为持续增长" % [_duration_text(elapsed), _compact(resources.stones - before_stones), _compact(resources.herbs - before_herbs)]
		_add_log("离线收益已结算：%s" % _duration_text(elapsed))

func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"resources": resources,
		"buildings": buildings,
		"disciples": disciples,
		"inventory": inventory,
		"realm_index": realm_index,
		"realm_stage": realm_stage,
		"active_recipe": active_recipe,
		"expedition": expedition,
		"logs": logs.slice(max(0, logs.size() - 30)),
	}
	return SaveManager.save_data(data)

func reset_game() -> void:
	SaveManager.reset_save()
	resources = {"stones": 980.0, "herbs": 180.0, "ore": 90.0, "cultivation": 0.0, "fortune": 12.0}
	buildings = {"hall": 1, "field": 1, "alchemy": 1, "mine": 1, "library": 1}
	realm_index = 0
	realm_stage = 0
	active_recipe = {}
	expedition = {}
	logs.clear()
	_new_game()
	save_game()
	changed.emit()

func advance_time(seconds: float, emit_signal := true) -> void:
	var rates := get_rates()
	resources.stones += rates.stones * seconds
	resources.herbs += rates.herbs * seconds
	resources.ore += rates.ore * seconds
	resources.cultivation += rates.cultivation * seconds
	resources.fortune = min(999.0, resources.fortune + 0.003 * seconds)
	_process_recipe(seconds)
	_process_expedition(seconds)
	while realm_stage < 3 and resources.cultivation >= cultivation_required():
		resources.cultivation -= cultivation_required()
		realm_stage += 1
		_add_log("境界精进：%s %s" % [GameData.REALMS[realm_index].name, GameData.STAGES[realm_stage]])
	if emit_signal:
		changed.emit()

func get_rates() -> Dictionary:
	var hall := float(buildings.hall)
	var field := float(buildings.field)
	var mine := float(buildings.mine)
	var library := float(buildings.library)
	var stone_rate := 2.0 + mine * 3.8 + hall * 0.8
	var herb_rate := 0.7 + field * 2.4
	var ore_rate := 0.35 + mine * 1.25
	var cultivation_rate := 2.0 + library * 2.2 + hall * 0.7
	for disciple in disciples:
		match int(disciple.assignment):
			1: herb_rate += 1.7
			2: stone_rate += 2.2; ore_rate += 0.6
			3: cultivation_rate += 2.8
			4: cultivation_rate += 3.8
	return {"stones": stone_rate, "herbs": herb_rate, "ore": ore_rate, "cultivation": cultivation_rate}

func assign_disciple(index: int, assignment: int) -> void:
	if index < 0 or index >= disciples.size(): return
	disciples[index].assignment = assignment
	_add_log("%s 已调任至 %s" % [disciples[index].name, assignment_name(assignment)])
	changed.emit()

func assignment_name(value: int) -> String:
	return ["待命", "灵田", "灵矿", "藏经阁", "闭关", "远征"][clamp(value, 0, 5)]

func building_cost(id: String) -> float:
	var config = GameData.BUILDINGS.filter(func(b): return b.id == id)[0]
	return config.base_cost * pow(1.72, int(buildings[id]) - 1)

func upgrade_building(id: String) -> bool:
	var cost := building_cost(id)
	if resources.stones < cost:
		_emit_notice("灵石不足，还需 %s" % _compact(cost - resources.stones))
		return false
	resources.stones -= cost
	buildings[id] += 1
	_add_log("%s 升至 %d 级" % [_building_name(id), buildings[id]])
	changed.emit()
	save_game()
	return true

func start_recipe(index: int) -> bool:
	if not active_recipe.is_empty():
		_emit_notice("丹炉正在温养，暂不可更换配方。")
		return false
	var recipe = GameData.RECIPES[index]
	if resources.herbs < recipe.herbs or resources.stones < recipe.stones:
		_emit_notice("炼丹材料不足。")
		return false
	resources.herbs -= recipe.herbs
	resources.stones -= recipe.stones
	var speed := 1.25 if _disciple_has_bonus("alchemy") else 1.0
	active_recipe = {"index": index, "remaining": recipe.duration / speed, "total": recipe.duration / speed}
	_add_log("丹炉起火：开始炼制 %s" % recipe.name)
	changed.emit()
	return true

func _process_recipe(seconds: float) -> void:
	if active_recipe.is_empty(): return
	active_recipe.remaining = max(0.0, float(active_recipe.remaining) - seconds)
	if active_recipe.remaining <= 0.0:
		var recipe = GameData.RECIPES[int(active_recipe.index)]
		var quality_bonus: int = min(5, int(buildings.alchemy / 3))
		var item := _generate_specific_item(recipe.name, "丹药", quality_bonus)
		inventory.append(item)
		if recipe.id == "qi": resources.cultivation += 120.0
		elif recipe.id == "spirit": resources.cultivation += 900.0
		_add_log("丹成！获得%s %s" % [item.quality, item.name])
		active_recipe = {}

func start_expedition(index: int) -> bool:
	if not expedition.is_empty():
		_emit_notice("已有远征队正在秘境中。")
		return false
	var config = GameData.EXPEDITIONS[index]
	if realm_index < int(config.realm):
		_emit_notice("需达到 %s 才能进入。" % GameData.REALMS[int(config.realm)].name)
		return false
	var power := total_power()
	var duration := float(config.duration) * (0.82 if _disciple_has_bonus("expedition") else 1.0)
	expedition = {"index": index, "remaining": duration, "total": duration, "power": power}
	_add_log("远征队进入%s，预计 %s 后返回" % [config.name, _duration_text(duration)])
	changed.emit()
	return true

func _process_expedition(seconds: float) -> void:
	if expedition.is_empty(): return
	expedition.remaining = max(0.0, float(expedition.remaining) - seconds)
	if expedition.remaining <= 0.0:
		var config = GameData.EXPEDITIONS[int(expedition.index)]
		var win_chance: float = clamp(float(expedition.power) / float(config.power), 0.25, 1.0)
		var won: bool = randf() <= win_chance
		if won:
			var loot_count := 1 + int(config.reward / 2.5)
			for i in loot_count:
				inventory.append(_generate_item(realm_index + int(config.reward)))
			resources.stones += 90.0 * float(config.reward)
			resources.herbs += 24.0 * float(config.reward)
			_add_log("%s凯旋，带回 %d 件战利品" % [config.name, loot_count])
		else:
			resources.stones += 25.0 * float(config.reward)
			_add_log("远征受阻，弟子平安归来并带回少量灵石。")
		expedition = {}

func cultivation_required() -> float:
	return 240.0 * pow(2.15, realm_index) * (1.0 + realm_stage * 0.48)

func breakthrough_cost() -> Dictionary:
	return {"stones": 260.0 * pow(2.0, realm_index), "herbs": 65.0 * pow(1.78, realm_index)}

func attempt_breakthrough() -> bool:
	if realm_stage < 3:
		_emit_notice("需先修炼至本境界圆满。")
		return false
	if realm_index >= GameData.REALMS.size() - 1:
		_emit_notice("已证真仙道果。")
		return false
	var req := cultivation_required()
	var cost := breakthrough_cost()
	if resources.cultivation < req or resources.stones < cost.stones or resources.herbs < cost.herbs:
		_emit_notice("突破所需修为或资源不足。")
		return false
	resources.cultivation -= req
	resources.stones -= cost.stones
	resources.herbs -= cost.herbs
	var chance: float = min(0.95, 0.72 + float(buildings.library) * 0.012 + float(resources.fortune) * 0.001)
	if randf() <= chance:
		realm_index += 1
		realm_stage = 0
		resources.fortune += 4.0
		_add_log("雷劫散尽，成功突破至 %s！" % GameData.REALMS[realm_index].name)
		_emit_notice("突破成功 · %s" % GameData.REALMS[realm_index].name)
	else:
		resources.cultivation += req * 0.35
		_add_log("突破未成，保留部分修为，静候下次天机。")
		_emit_notice("渡劫未成，弟子无恙。")
	changed.emit()
	save_game()
	return true

func total_power() -> float:
	var result := 0.0
	for disciple in disciples: result += float(disciple.power) * (1.0 + realm_index * 0.75 + realm_stage * 0.16)
	for item in inventory:
		if item.get("equipped", false): result += float(item.power)
	return result

func dismantle_common() -> bool:
	for i in inventory.size():
		if inventory[i].quality_index <= 1 and not inventory[i].get("locked", false):
			var item = inventory.pop_at(i)
			resources.ore += 8.0 * (int(item.quality_index) + 1)
			_add_log("分解%s，获得精炼矿材" % item.name)
			changed.emit()
			return true
	_emit_notice("没有可分解的凡品或良品。")
	return false

func _generate_item(level_hint: int, guaranteed_useful := false) -> Dictionary:
	var items := GameData.all_items()
	var max_tier: int = clamp(level_hint + 2, 1, 9)
	var candidates = items.filter(func(item): return int(item.tier) <= max_tier)
	var base = candidates[randi() % candidates.size()]
	var q := _roll_quality(level_hint + (2 if guaranteed_useful else 0))
	return _make_item(base, q)

func _generate_specific_item(item_name: String, category: String, quality_bonus: int) -> Dictionary:
	var base := {"id": "crafted_%s" % item_name, "name": item_name, "category": category, "tier": realm_index}
	return _make_item(base, _roll_quality(quality_bonus))

func _make_item(base: Dictionary, quality_index: int) -> Dictionary:
	var quality = GameData.QUALITIES[quality_index]
	var affixes: Array[String] = []
	for i in int(quality.affixes):
		affixes.append(GameData.AFFIXES[randi() % GameData.AFFIXES.size()])
	return {"uid": "%d_%d" % [Time.get_ticks_usec(), randi()], "id": base.id, "name": base.name, "category": base.category, "quality": quality.name, "quality_index": quality_index, "power": (22.0 + int(base.tier) * 11.0) * quality.mult, "affixes": affixes, "locked": false, "equipped": quality_index >= 3}

func _roll_quality(bonus: int) -> int:
	var roll := randf() * 100.0
	var accumulated := 0.0
	for i in GameData.QUALITIES.size():
		var adjusted_weight: float = float(GameData.QUALITIES[i].weight) * (1.0 + max(0, i - 1) * bonus * 0.08)
		accumulated += adjusted_weight
		if roll <= accumulated: return i
	return min(7, 1 + bonus / 2)

func _disciple_has_bonus(bonus: String) -> bool:
	for i in disciples.size():
		if GameData.DISCIPLES[i].bonus == bonus and int(disciples[i].assignment) != 0: return true
	return false

func _building_name(id: String) -> String:
	for building in GameData.BUILDINGS:
		if building.id == id: return building.name
	return id

func _add_log(text: String) -> void:
	logs.append(text)
	if logs.size() > 40: logs.pop_front()

func _emit_notice(text: String) -> void:
	_add_log(text)
	notice.emit(text)

func realm_text() -> String:
	return "%s · %s" % [GameData.REALMS[realm_index].name, GameData.STAGES[realm_stage]]

func _compact(value: float) -> String:
	if value >= 1000000.0: return "%.2fM" % (value / 1000000.0)
	if value >= 10000.0: return "%.1f万" % (value / 10000.0)
	return "%d" % round(value)

func _duration_text(seconds: float) -> String:
	if seconds >= 3600.0: return "%d时%d分" % [int(seconds / 3600.0), int(fmod(seconds, 3600.0) / 60.0)]
	if seconds >= 60.0: return "%d分%d秒" % [int(seconds / 60.0), int(fmod(seconds, 60.0))]
	return "%d秒" % int(seconds)
