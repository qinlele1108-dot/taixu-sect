extends SceneTree

var frames := 0

func _initialize() -> void:
	var state = root.get_node("GameState")
	state.resources = {"stones": 980.0, "herbs": 180.0, "ore": 90.0, "cultivation": 0.0, "fortune": 12.0}
	state.buildings = {"hall": 1, "field": 1, "alchemy": 1, "mine": 1, "library": 1}
	state.realm_index = 0
	state.realm_stage = 0
	state.active_recipe = {}
	state.expedition = {}
	state.offline_summary = ""
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 3:
		var state = root.get_node("GameState")
		state.resources = {"stones": 980.0, "herbs": 180.0, "ore": 90.0, "cultivation": 0.0, "fortune": 12.0}
		state.buildings = {"hall": 1, "field": 1, "alchemy": 1, "mine": 1, "library": 1}
		state.realm_index = 0
		state.realm_stage = 0
		state.offline_summary = ""
		state.changed.emit()
		for child in root.get_children():
			for nested in child.get_children():
				if nested is AcceptDialog:
					nested.hide()
	if frames == 45:
		var image := root.get_texture().get_image()
		var output := ProjectSettings.globalize_path("res://../work/qa-main.png")
		var error := image.save_png(output)
		print("CAPTURE_RESULT ", error, " ", output, " size=", image.get_size())
		quit(0)
	return false
