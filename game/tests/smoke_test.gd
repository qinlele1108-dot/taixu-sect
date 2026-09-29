extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	if GameData.REALMS.size() != 10: failures.append("realms")
	if GameData.QUALITIES.size() != 8: failures.append("qualities")
	if GameData.all_items().size() != 80: failures.append("items")
	if GameData.BUILDINGS.size() != 5: failures.append("buildings")
	if GameData.RECIPES.size() != 6: failures.append("recipes")
	if GameData.EXPEDITIONS.size() != 8: failures.append("expeditions")
	if failures.is_empty():
		print("SMOKE_TEST_OK realms=10 qualities=8 items=80 buildings=5 recipes=6 expeditions=8")
		quit(0)
	else:
		push_error("SMOKE_TEST_FAILED " + ",".join(failures))
		quit(1)

