extends Control

const C_BG := Color("#e9f3ef")
const C_PANEL := Color("#f8fffc")
const C_PANEL_SOFT := Color("#edf7f3")
const C_INK := Color("#173f39")
const C_MUTED := Color("#54736d")
const C_JADE := Color("#4e9180")
const C_JADE_DARK := Color("#2f6e61")
const C_GOLD := Color("#b88a3d")
const C_RED := Color("#a54a3f")

var resource_labels := {}
var realm_label: Label
var status_label: Label
var log_label: RichTextLabel
var building_boxes := {}
var disciple_widgets: Array = []
var inventory_text: RichTextLabel
var recipe_status: Label
var expedition_status: Label
var cultivation_bar: ProgressBar
var cultivation_text: Label
var breakthrough_button: Button
var _ui_accumulator := 0.0

func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = load("res://assets/fonts/NotoSansSC.ttf")
	theme = ui_theme
	_build_interface()
	GameState.notice.connect(_show_notice)
	GameState.changed.connect(_refresh_all)
	_refresh_all()
	if not GameState.offline_summary.is_empty():
		var dialog := AcceptDialog.new()
		dialog.title = "掌门归来 · 离线收益"
		dialog.dialog_text = GameState.offline_summary
		dialog.ok_button_text = "收取"
		_style_dialog(dialog)
		add_child(dialog)
		dialog.popup_centered(Vector2i(420, 280))

func _process(delta: float) -> void:
	_ui_accumulator += delta
	if _ui_accumulator >= 0.25:
		_ui_accumulator = 0.0
		_refresh_header()
		_refresh_timers()

func _build_interface() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = load("res://assets/art/sect_background.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.90, 0.96, 0.94, 0.38)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	root.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	body.add_child(_build_disciples())
	body.add_child(_build_tabs())
	root.add_child(_build_footer())

func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 78
	panel.add_theme_stylebox_override("panel", _style(C_PANEL, 16, 0.94, C_JADE))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "太玄宗 · 掌门案"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title)
	realm_label = Label.new()
	realm_label.add_theme_font_size_override("font_size", 18)
	realm_label.add_theme_color_override("font_color", C_GOLD)
	box.add_child(realm_label)
	for data in [["stones", "灵石"], ["herbs", "药材"], ["ore", "矿材"], ["fortune", "气运"]]:
		var label := Label.new()
		label.custom_minimum_size.x = 130
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", C_INK)
		box.add_child(label)
		resource_labels[data[0]] = {"label": label, "name": data[1]}
	var save_button := _button("存档", C_JADE_DARK)
	save_button.pressed.connect(func():
		GameState.save_game()
		_show_notice("已保存至本地")
	)
	box.add_child(save_button)
	return panel

func _build_disciples() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 390
	panel.add_theme_stylebox_override("panel", _style(C_PANEL, 14, 0.96, C_JADE))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_section_title("弟子排班", "专长匹配可提高宗门产出"))
	for i in GameData.DISCIPLES.size():
		var disciple = GameData.DISCIPLES[i]
		var card := PanelContainer.new()
		card.custom_minimum_size.y = 185
		card.add_theme_stylebox_override("panel", _style(C_PANEL_SOFT, 12, 0.96, Color("#91b8ad")))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(120, 165)
		portrait.texture = load(disciple.portrait)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		row.add_child(portrait)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_label := Label.new()
		name_label.text = "%s · %s" % [disciple.name, disciple.path]
		name_label.add_theme_font_size_override("font_size", 19)
		name_label.add_theme_color_override("font_color", C_INK)
		info.add_child(name_label)
		var talent := Label.new()
		talent.text = "天赋：%s" % disciple.talent
		talent.add_theme_color_override("font_color", C_MUTED)
		info.add_child(talent)
		var realm := Label.new()
		realm.text = "境界：%s" % GameState.realm_text()
		realm.add_theme_color_override("font_color", C_GOLD)
		info.add_child(realm)
		var option := OptionButton.new()
		for assignment in ["待命", "灵田", "灵矿", "藏经阁", "闭关", "远征"]: option.add_item(assignment)
		option.item_selected.connect(func(value): GameState.assign_disciple(i, value))
		info.add_child(option)
		disciple_widgets.append({"realm": realm, "option": option})
		box.add_child(card)
	return panel

func _build_tabs() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(C_PANEL, 14, 0.96, C_JADE))
	var tabs := TabContainer.new()
	tabs.tab_alignment = TabBar.ALIGNMENT_LEFT
	tabs.add_theme_font_size_override("font_size", 18)
	tabs.add_theme_color_override("font_selected_color", C_INK)
	tabs.add_theme_color_override("font_unselected_color", C_MUTED)
	tabs.add_theme_color_override("font_hovered_color", C_JADE_DARK)
	tabs.add_theme_stylebox_override("panel", _style(Color("#edf7f3"), 10, 0.82, Color("#9cbfb6")))
	tabs.add_theme_stylebox_override("tab_selected", _style(C_PANEL, 7, 1.0, C_JADE))
	tabs.add_theme_stylebox_override("tab_unselected", _style(Color("#dceae5"), 7, 0.96, Color("#a9bdb7")))
	tabs.add_theme_stylebox_override("tab_hovered", _style(Color("#e7f2ee"), 7, 1.0, C_GOLD))
	panel.add_child(tabs)
	tabs.add_child(_overview_tab())
	tabs.add_child(_inventory_tab())
	tabs.add_child(_alchemy_tab())
	tabs.add_child(_expedition_tab())
	tabs.add_child(_cultivation_tab())
	return panel

func _overview_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "宗门总览"
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for building in GameData.BUILDINGS:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(370, 185)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style(C_PANEL_SOFT, 12, 0.96, Color("#9cbfb6")))
		var box := VBoxContainer.new()
		card.add_child(box)
		var heading := Label.new()
		heading.text = "%s  %s" % [building.icon, building.name]
		heading.add_theme_font_size_override("font_size", 22)
		heading.add_theme_color_override("font_color", C_INK)
		box.add_child(heading)
		var desc := Label.new()
		desc.text = building.desc
		desc.add_theme_color_override("font_color", C_MUTED)
		box.add_child(desc)
		var detail := Label.new()
		detail.add_theme_font_size_override("font_size", 16)
		detail.add_theme_color_override("font_color", C_JADE_DARK)
		detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(detail)
		var up := _button("升级", C_JADE_DARK)
		up.pressed.connect(func(): GameState.upgrade_building(building.id))
		box.add_child(up)
		grid.add_child(card)
		building_boxes[building.id] = {"detail": detail, "button": up}
	return scroll

func _inventory_tab() -> Control:
	var box := VBoxContainer.new()
	box.name = "库存与品相"
	box.add_child(_section_title("万宝阁", "八种品相 · 随机词条 · 高品装备自动穿戴"))
	var actions := HBoxContainer.new()
	var dismantle := _button("分解一件凡品 / 良品", C_RED)
	dismantle.pressed.connect(func(): GameState.dismantle_common())
	actions.add_child(dismantle)
	var hint := Label.new()
	hint.text = "  凡品 → 良品 → 上品 → 极品 → 玄品 → 地品 → 天品 → 仙品"
	hint.add_theme_color_override("font_color", C_MUTED)
	actions.add_child(hint)
	box.add_child(actions)
	inventory_text = RichTextLabel.new()
	inventory_text.bbcode_enabled = true
	inventory_text.fit_content = false
	inventory_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_text.add_theme_font_size_override("normal_font_size", 17)
	box.add_child(inventory_text)
	return box

func _alchemy_tab() -> Control:
	var box := VBoxContainer.new()
	box.name = "丹房炼制"
	box.add_child(_section_title("丹炉温养", "弟子宁知微在岗时，炼制速度提高 25%"))
	recipe_status = Label.new()
	recipe_status.add_theme_font_size_override("font_size", 20)
	recipe_status.add_theme_color_override("font_color", C_GOLD)
	box.add_child(recipe_status)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for i in GameData.RECIPES.size():
		var recipe = GameData.RECIPES[i]
		var button := _button("%s\n药材 %d · 灵石 %d · %s\n%s" % [recipe.name, recipe.herbs, recipe.stones, GameState._duration_text(recipe.duration), recipe.effect], C_JADE_DARK)
		button.custom_minimum_size = Vector2(390, 95)
		button.pressed.connect(func(): GameState.start_recipe(i))
		grid.add_child(button)
	return box

func _expedition_tab() -> Control:
	var box := VBoxContainer.new()
	box.name = "秘境远征"
	box.add_child(_section_title("山河秘境", "自动远征，不会永久损失弟子或装备"))
	expedition_status = Label.new()
	expedition_status.add_theme_font_size_override("font_size", 20)
	expedition_status.add_theme_color_override("font_color", C_GOLD)
	box.add_child(expedition_status)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for i in GameData.EXPEDITIONS.size():
		var expedition_data = GameData.EXPEDITIONS[i]
		var button := _button("%s\n需 %s · 战力 %d · %s" % [expedition_data.name, GameData.REALMS[expedition_data.realm].name, expedition_data.power, GameState._duration_text(expedition_data.duration)], C_JADE_DARK)
		button.custom_minimum_size = Vector2(390, 85)
		button.pressed.connect(func(): GameState.start_expedition(i))
		grid.add_child(button)
	return box

func _cultivation_tab() -> Control:
	var box := VBoxContainer.new()
	box.name = "境界与功法"
	box.add_child(_section_title("十境天阶", "四十个阶段，从炼气到真仙"))
	cultivation_text = Label.new()
	cultivation_text.add_theme_font_size_override("font_size", 24)
	cultivation_text.add_theme_color_override("font_color", C_INK)
	box.add_child(cultivation_text)
	cultivation_bar = ProgressBar.new()
	cultivation_bar.custom_minimum_size.y = 30
	cultivation_bar.show_percentage = false
	box.add_child(cultivation_bar)
	breakthrough_button = _button("凝聚道果 · 尝试突破", C_GOLD)
	breakthrough_button.custom_minimum_size.y = 55
	breakthrough_button.pressed.connect(func(): GameState.attempt_breakthrough())
	box.add_child(breakthrough_button)
	var separator := HSeparator.new()
	box.add_child(separator)
	var realms := GridContainer.new()
	realms.columns = 5
	realms.add_theme_constant_override("h_separation", 8)
	realms.add_theme_constant_override("v_separation", 8)
	box.add_child(realms)
	for i in GameData.REALMS.size():
		var realm = GameData.REALMS[i]
		var card := Label.new()
		card.text = "%02d · %s\n%s" % [i + 1, realm.name, realm.desc]
		card.custom_minimum_size = Vector2(170, 90)
		card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_color_override("font_color", C_INK if i <= GameState.realm_index else Color("#9baaa6"))
		card.add_theme_stylebox_override("normal", _style(C_PANEL_SOFT, 10, 0.92, C_JADE if i <= GameState.realm_index else Color("#c4d2ce")))
		realms.add_child(card)
	return box

func _build_footer() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 98
	panel.add_theme_stylebox_override("panel", _style(C_PANEL, 12, 0.94, C_JADE))
	var row := HBoxContainer.new()
	panel.add_child(row)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.fit_content = false
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.add_theme_font_size_override("normal_font_size", 14)
	log_label.add_theme_color_override("default_color", C_INK)
	row.add_child(log_label)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 330
	row.add_child(right)
	status_label = Label.new()
	status_label.text = "宗门运转中"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_color_override("font_color", C_JADE_DARK)
	right.add_child(status_label)
	var reset := _button("重开山门", C_RED)
	reset.pressed.connect(_confirm_reset)
	right.add_child(reset)
	return panel

func _refresh_all() -> void:
	_refresh_header()
	for i in disciple_widgets.size():
		disciple_widgets[i].realm.text = "境界：%s · 战力 %d" % [GameState.realm_text(), GameState.disciples[i].power]
		disciple_widgets[i].option.select(int(GameState.disciples[i].assignment))
	for building in GameData.BUILDINGS:
		var level := int(GameState.buildings[building.id])
		var cost := GameState.building_cost(building.id)
		building_boxes[building.id].detail.text = "等级 %d\n升级消耗：%s 灵石" % [level, GameState._compact(cost)]
		building_boxes[building.id].button.text = "升级至 %d 级" % (level + 1)
	_refresh_inventory()
	_refresh_timers()
	_refresh_cultivation()
	_refresh_log()

func _refresh_header() -> void:
	realm_label.text = GameState.realm_text()
	for key in resource_labels:
		resource_labels[key].label.text = "%s\n%s" % [resource_labels[key].name, GameState._compact(float(GameState.resources[key]))]

func _refresh_inventory() -> void:
	if inventory_text == null: return
	var lines: Array[String] = []
	var sorted_items = GameState.inventory.duplicate()
	sorted_items.sort_custom(func(a, b): return int(a.quality_index) > int(b.quality_index))
	for item in sorted_items.slice(0, 45):
		var color: Color = GameData.QUALITIES[int(item.quality_index)].color
		var affix_text := " · " + " / ".join(item.affixes) if not item.affixes.is_empty() else ""
		var equipped := "  [已装备]" if item.equipped else ""
		lines.append("[color=#%s]◆ %s · %s[/color]  %s  战力 %.0f%s%s" % [color.to_html(false), item.quality, item.category, item.name, item.power, affix_text, equipped])
	inventory_text.text = "\n".join(lines) if not lines.is_empty() else "库存空空，派遣弟子探索秘境吧。"

func _refresh_timers() -> void:
	if recipe_status:
		if GameState.active_recipe.is_empty(): recipe_status.text = "丹炉空闲 · 选择一种丹方"
		else:
			var recipe = GameData.RECIPES[int(GameState.active_recipe.index)]
			recipe_status.text = "正在炼制 %s · 剩余 %s" % [recipe.name, GameState._duration_text(GameState.active_recipe.remaining)]
	if expedition_status:
		if GameState.expedition.is_empty(): expedition_status.text = "远征队待命 · 当前总战力 %d" % GameState.total_power()
		else:
			var exp = GameData.EXPEDITIONS[int(GameState.expedition.index)]
			expedition_status.text = "%s探索中 · 剩余 %s" % [exp.name, GameState._duration_text(GameState.expedition.remaining)]

func _refresh_cultivation() -> void:
	if cultivation_text == null: return
	var required := GameState.cultivation_required()
	cultivation_text.text = "%s  ·  修为 %s / %s\n%s" % [GameState.realm_text(), GameState._compact(GameState.resources.cultivation), GameState._compact(required), GameData.REALMS[GameState.realm_index].desc]
	cultivation_bar.max_value = required
	cultivation_bar.value = min(required, GameState.resources.cultivation)
	breakthrough_button.disabled = GameState.realm_stage < 3 or GameState.realm_index >= GameData.REALMS.size() - 1
	if GameState.realm_stage < 3: breakthrough_button.text = "修炼至圆满后可突破"
	elif GameState.realm_index >= 9: breakthrough_button.text = "真仙道果已成"
	else:
		var cost := GameState.breakthrough_cost()
		breakthrough_button.text = "渡劫突破 · %s 灵石 · %s 药材" % [GameState._compact(cost.stones), GameState._compact(cost.herbs)]

func _refresh_log() -> void:
	if log_label == null: return
	var entries = GameState.logs.slice(max(0, GameState.logs.size() - 4))
	log_label.text = "[color=#4e9180]宗门纪事[/color]\n" + "\n".join(entries)

func _show_notice(text: String) -> void:
	status_label.text = text
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(func(): status_label.text = "宗门运转中 · 自动存档")
	_refresh_log()

func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "重开山门"
	dialog.dialog_text = "将清除当前本地存档并重新开始。此操作不可撤销。"
	dialog.ok_button_text = "确认重开"
	dialog.cancel_button_text = "保留存档"
	_style_dialog(dialog)
	dialog.confirmed.connect(func():
		GameState.reset_game()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(460, 220))

func _style_dialog(dialog: AcceptDialog) -> void:
	dialog.add_theme_stylebox_override("panel", _style(C_PANEL, 12, 1.0, C_JADE))
	dialog.add_theme_color_override("title_color", C_INK)
	dialog.get_label().add_theme_color_override("font_color", C_INK)
	dialog.get_label().add_theme_font_size_override("font_size", 17)
	var ok: Button = dialog.get_ok_button()
	ok.add_theme_color_override("font_color", Color.WHITE)
	ok.add_theme_stylebox_override("normal", _style(C_JADE_DARK, 8, 1.0, C_JADE))
	ok.add_theme_stylebox_override("hover", _style(C_JADE, 8, 1.0, C_GOLD))
	if dialog is ConfirmationDialog:
		var cancel: Button = dialog.get_cancel_button()
		cancel.add_theme_color_override("font_color", C_INK)
		cancel.add_theme_stylebox_override("normal", _style(C_PANEL_SOFT, 8, 1.0, C_JADE))

func _section_title(title_text: String, subtitle: String) -> Control:
	var box := VBoxContainer.new()
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_INK)
	box.add_child(title)
	var sub := Label.new()
	sub.text = subtitle
	sub.add_theme_color_override("font_color", C_MUTED)
	box.add_child(sub)
	return box

func _button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, 9, 0.96, color.lightened(0.12)))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.10), 9, 1.0, C_GOLD))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.08), 9, 1.0, C_GOLD))
	button.add_theme_stylebox_override("disabled", _style(Color("#9eb0ab"), 9, 0.8, Color("#bfcac7")))
	return button

func _style(color: Color, radius: int, alpha: float, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, alpha)
	style.border_color = Color(border, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
