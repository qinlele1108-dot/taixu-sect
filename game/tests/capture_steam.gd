extends SceneTree

const OUTPUT_DIR := "res://../outputs/steam-release-kit/store-assets/screenshots"
const SHOTS := [
	{"tab": 0, "name": "01-宗门总览.png"},
	{"tab": 1, "name": "02-万象宝库.png"},
	{"tab": 2, "name": "03-丹炉温养.png"},
	{"tab": 3, "name": "04-山河秘境.png"},
	{"tab": 4, "name": "05-境界成长.png"},
]

var frames := 0
var tabs: TabContainer
var next_shot := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var state = root.get_node("GameState")
	state.resources = {"stones": 9800.0, "herbs": 1800.0, "ore": 900.0, "cultivation": 2400.0, "fortune": 88.0}
	state.buildings = {"hall": 3, "field": 3, "alchemy": 3, "mine": 3, "library": 3}
	state.realm_index = 3
	state.realm_stage = 1
	state.active_recipe = {}
	state.expedition = {}
	state.offline_summary = ""
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 10:
		tabs = _find_tabs(root)
		if tabs == null:
			push_error("Steam screenshot capture could not find TabContainer")
			quit(1)
			return false
		tabs.current_tab = SHOTS[0].tab
	if tabs != null and next_shot < SHOTS.size() and frames == 45 + next_shot * 35:
		var shot: Dictionary = SHOTS[next_shot]
		var image := root.get_texture().get_image()
		var output := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, shot.name])
		var error := image.save_png(output)
		print("STEAM_CAPTURE ", error, " ", output, " size=", image.get_size())
		next_shot += 1
		if next_shot >= SHOTS.size():
			quit(0)
		else:
			tabs.current_tab = SHOTS[next_shot].tab
	return false


func _find_tabs(node: Node) -> TabContainer:
	if node is TabContainer:
		return node
	for child in node.get_children():
		var found := _find_tabs(child)
		if found != null:
			return found
	return null
