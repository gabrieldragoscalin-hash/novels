extends SceneTree
const Progression = preload("res://scripts/progression.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
func _initialize() -> void:
	var definitions := {
		"meteor":["wand",[["meteor",1],["multishot",5],["multiple_shots",5],["ricochet",5],["attack_speed",8],["piercing",3],["follow",1]]],
		"laser":["wand",[["perpetuum",1],["multishot",2],["ricochet",2],["follow",1],["attack_speed",3]]],
		"explosive":["bow",[["explosive",1],["multishot",2],["attack_speed",3]]]
	}
	var result := {}
	for name in definitions:
		var p = Progression.new(); p.weapon = definitions[name][0]
		var plan: Array = []
		for pair in definitions[name][1]:
			for i in range(pair[1]):
				var index: int = p.available_upgrades().find(pair[0]); assert(index>=0)
				plan.append(index); p.grant_upgrade(pair[0])
		result[name] = {"weapon":p.weapon,"plan":plan}
	var d = Dungeon.new(9)
	for floor_number in range(9): d.advance()
	for cell in d.rooms:
		if d.rooms[cell]["role"]=="combat": result["combat_room"] = cell.y*5+cell.x; break
	var args := OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else "/tmp/vfx-ui-plans.json"
	var file := FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(result));file.close()
	quit()
