extends SceneTree
const Rig = preload("res://prototypes/animation_lab/generated/shared_champion.tscn")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var first = Rig.instantiate(); root.add_child(first); first.paused = true
	var second = Rig.instantiate(); root.add_child(second); second.paused = true; second.configure("guard","sun_bow","side")
	assert(first.get_node("Skeleton") is Skeleton2D)
	assert(first.get_node("Skeleton/MainUpperMesh").get_bone_count()==2)
	assert(first.get_node("Skeleton/Body/Head/Art").texture.atlas!=second.get_node("Skeleton/Body/Head/Art").texture.atlas)
	assert(first.animation.get_animation_library("")==second.animation.get_animation_library(""))
	var max_error := 0.0; var correction := 0.0
	for weapon in ["sun_bow","moon_bow","hammer"]:
		for view in ["front","back","side","left"]:
			first.configure("aster",weapon,view); second.configure("guard",weapon,view)
			assert(first.animation.assigned_animation.begins_with("hammer" if weapon=="hammer" else "bow"))
			for step in range(101):
				for rig in [first,second]:
					rig.seek_phase(step/101.0)
					assert(is_finite(rig.grip_error))
					max_error = maxf(max_error,rig.grip_error)
					correction = maxf(correction,rig.correction_radians)
				assert(first.get_node("Skeleton/Body/MainUpper").rotation==second.get_node("Skeleton/Body/MainUpper").rotation)
	assert(max_error<0.1,"Weapon support grip lost contact")
	assert(correction<0.5,"Variant needs excessive correction")
	print("LAB measurements: max grip error ",max_error," px; correction ",rad_to_deg(correction)," degrees")
	first.queue_free(); second.queue_free(); quit()
