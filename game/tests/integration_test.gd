extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("GameState")
	var failures: Array[String] = []
	state.reset_game()
	state.resources.stones = 10000000.0
	state.resources.herbs = 10000000.0
	state.resources.ore = 10000000.0
	state.resources.cultivation = 10000000.0
	state.resources.fortune = 999.0

	if not state.upgrade_building("hall") or int(state.buildings.hall) != 2:
		failures.append("building_upgrade")

	var inventory_before: int = state.inventory.size()
	if not state.start_recipe(0):
		failures.append("recipe_start")
	state.advance_time(30.0, false)
	if state.inventory.size() <= inventory_before or not state.active_recipe.is_empty():
		failures.append("recipe_complete")

	var loot_before: int = state.inventory.size()
	if not state.start_expedition(0):
		failures.append("expedition_start")
	state.advance_time(60.0, false)
	if state.inventory.size() <= loot_before or not state.expedition.is_empty():
		failures.append("expedition_complete")

	state.resources.cultivation = 10000000.0
	state.advance_time(0.0, false)
	if state.realm_stage != 3:
		failures.append("stage_progression")
	for attempt in 10:
		state.resources.cultivation = 10000000.0
		state.resources.stones = 10000000.0
		state.resources.herbs = 10000000.0
		state.attempt_breakthrough()
		if state.realm_index >= 1:
			break
	if state.realm_index < 1:
		failures.append("breakthrough")

	if not state.save_game() or not FileAccess.file_exists("user://savegame.json"):
		failures.append("save")

	if failures.is_empty():
		print("INTEGRATION_TEST_OK building=2 recipe=complete expedition=complete realm=", state.realm_index, " inventory=", state.inventory.size())
		quit(0)
	else:
		push_error("INTEGRATION_TEST_FAILED " + ",".join(failures))
		quit(1)
