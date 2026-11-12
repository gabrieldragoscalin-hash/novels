extends SceneTree
const OUT := "res://prototypes/animation_lab/generated/"
var rig: Node2D
var body: Bone2D
func owned(node: Node, parent: Node) -> Node:
	parent.add_child(node); node.owner = rig; return node
func bone(name_value: String, parent: Node, pos: Vector2, angle: float, length_value: float) -> Bone2D:
	var b := Bone2D.new(); b.name = name_value; b.position = pos; b.rotation = angle
	b.set_autocalculate_length_and_angle(false); b.length = length_value; b.bone_angle = 0
	b.rest = b.transform; owned(b,parent); return b
func sprite(name_value: String, parent: Node, pos: Vector2, angle: float, z: int) -> Sprite2D:
	var s := Sprite2D.new(); s.name = name_value; s.position = pos; s.rotation = angle; s.z_index = z; owned(s,parent); return s
func add_track(anim: Animation, path: String, times: Array, values: Array) -> void:
	var index := anim.add_track(Animation.TYPE_VALUE); anim.track_set_path(index,NodePath(path))
	anim.track_set_interpolation_type(index,Animation.INTERPOLATION_LINEAR)
	for i in range(times.size()): anim.track_insert_key(index,times[i],values[i],1.0 if times.size()>10 or "Leg" in path or path=="Skeleton/Body:position" else -2.0)
func main_angles(shoulder: Vector2, target: Vector2, bend: float) -> Vector2:
	var delta := target-shoulder; var distance := delta.length()
	var a := (400-21.5*21.5+distance*distance)/(2*distance)
	var elbow := shoulder+delta.normalized()*a+Vector2(-delta.y,delta.x).normalized()*sqrt(maxf(0,400-a*a))*bend
	var first := (elbow-shoulder).angle()
	return Vector2(first,(target-elbow).angle()-first)
func motions() -> AnimationLibrary:
	var library := AnimationLibrary.new()
	for family in ["bow","hammer"]:
		for view in ["front","back","side"]:
			var main_shoulder := Vector2(-4,-91) if view=="side" else Vector2(12 if view=="front" else -12,-91)
			var off_shoulder := Vector2(-6,-91) if view=="side" else Vector2(-12 if view=="front" else 12,-91)
			var hold: Vector2; var prep: Vector2; var hit: Vector2; var angles: Array
			if family=="bow":
				hold = Vector2(34,-84) if view=="side" else Vector2(24 if view=="front" else -24,-78)
				prep = hold+Vector2(0,2 if view=="side" else -2); hit = hold+Vector2(1 if view!="back" else -1,1)
				angles = [0.0,0.0,0.0,0.0,0.0]
			else:
				hold = Vector2(18,-72) if view=="side" else Vector2(12 if view=="front" else -12,-72)
				prep = Vector2(2,-99) if view=="side" else Vector2(10 if view=="front" else -10,-96)
				hit = Vector2(22,-72) if view=="side" else Vector2(14 if view=="front" else -14,-65)
				angles = [-0.3,-1.1,1.25,1.25,-0.3] if view=="side" else [0.0,-0.3,0.4,0.4,0.0]
			var times: Array = [0.0,0.48,0.64,0.78,1.25]
			var primary: Array = []; var lower: Array = []; var weapon_angles: Array = []; var support_upper: Array = []; var support_lower: Array = []
			var poses: Array = [hold,prep,hit,hit,hold]
			if family=="hammer":
				times = [0.0,0.4,0.55,0.67,0.80,1.04,1.25]
				var through := Vector2(22,-82) if view=="side" else Vector2(12 if view=="front" else -12,-84)
				hit = Vector2(10,-68) if view=="side" else Vector2(4 if view=="front" else -4,-68)
				poses = [hold,prep,through,hit,hit,Vector2(2 if view=="side" else 0,-82),hold]
				angles = [-0.3,-1.1,0.9,2.8,2.8,1.1,-0.3] if view=="side" else ([0.0,-0.3,1.0,PI,PI,1.1,0.0] if view=="front" else [0.0,0.3,-1.0,-PI,-PI,-1.1,0.0])
			for i in range(poses.size()):
				var bend := 1.0 if view in ["back","side"] else -1.0
				if family=="hammer" and i==1 and view!="side": bend *= -1
				var a := main_angles(main_shoulder,poses[i],bend)
				var global_forearm := a.x+a.y
				if i>0:
					a.x = primary[-1]+angle_difference(primary[-1],a.x)
					var previous_global: float = primary[-1]+lower[-1]
					global_forearm = previous_global+angle_difference(previous_global,global_forearm)
				a.y = global_forearm-a.x
				primary.append(a.x); lower.append(a.y); weapon_angles.append(angles[i]-a.x-a.y)
				var pulls: Array = [0.0,10.0,0.0,0.0,0.0]
				var offset := Vector2((-35.0-pulls[i])*(-1 if view=="back" else 1),0) if family=="bow" else Vector2(0,-13).rotated(angles[i])
				var off := main_angles(off_shoulder,poses[i]+offset,1 if view!="back" else -1)
				var off_global := off.x+off.y
				if i>0:
					off.x = support_upper[-1]+angle_difference(support_upper[-1],off.x)
					var previous_off: float = support_upper[-1]+support_lower[-1]
					off_global = previous_off+angle_difference(previous_off,off_global)
				off.y = off_global-off.x
				support_upper.append(off.x); support_lower.append(off.y)
			var animation := Animation.new(); animation.length = 1.25; animation.loop_mode = Animation.LOOP_LINEAR
			add_track(animation,"Skeleton/Body/MainUpper:position",[0.0],[main_shoulder])
			add_track(animation,"Skeleton/Body/OffUpper:position",[0.0],[off_shoulder])
			add_track(animation,"Skeleton/Body/MainUpper:rotation",times,primary)
			add_track(animation,"Skeleton/Body/OffUpper:rotation",times,support_upper)
			add_track(animation,"Skeleton/Body/OffUpper/OffLower:rotation",times,support_lower)
			add_track(animation,"Skeleton/Body/MainUpper/MainLower:rotation",times,lower)
			add_track(animation,"Skeleton/Body/MainUpper/MainLower/MainHand/WeaponSocket:rotation",times,weapon_angles)
			add_track(animation,".:string_pull",times,[0.0,10.0,0.0,0.0,0.0] if family=="bow" else [0.0,0.0,0.0,0.0,0.0,0.0,0.0])
			# Bake the support-arm contact curve once per family/view. It is shared
			# by every skin; runtime correction only adapts different grip artwork.
			var sampled_times: Array = []; var baked_upper: Array = []; var baked_lower: Array = []
			for sample in range(51):
				var t := sample*1.25/50.0
				var up: float = animation.value_track_interpolate(animation.find_track(NodePath("Skeleton/Body/MainUpper:rotation"),Animation.TYPE_VALUE),t)
				var lo: float = animation.value_track_interpolate(animation.find_track(NodePath("Skeleton/Body/MainUpper/MainLower:rotation"),Animation.TYPE_VALUE),t)
				var turn: float = animation.value_track_interpolate(animation.find_track(NodePath("Skeleton/Body/MainUpper/MainLower/MainHand/WeaponSocket:rotation"),Animation.TYPE_VALUE),t)
				var pull: float = animation.value_track_interpolate(animation.find_track(NodePath(".:string_pull"),Animation.TYPE_VALUE),t)
				var point := main_shoulder+Vector2.from_angle(up)*20+Vector2.from_angle(up+lo)*21.5
				var offset := Vector2((-35-pull)*(-1 if view=="back" else 1),0) if family=="bow" else Vector2(0,-13).rotated(up+lo+turn)
				assert(point.distance_to(off_shoulder-offset)<41.5,"Authored pose exceeds support reach")
				var a := main_angles(off_shoulder,point+offset,1 if view!="back" else -1)
				var global_angle := a.x+a.y
				if sample>0:
					a.x = baked_upper[-1]+angle_difference(baked_upper[-1],a.x)
					var previous_angle: float = baked_upper[-1]+baked_lower[-1]
					global_angle = previous_angle+angle_difference(previous_angle,global_angle)
				sampled_times.append(t); baked_upper.append(a.x); baked_lower.append(global_angle-a.x)
			for path in ["Skeleton/Body/OffUpper:rotation","Skeleton/Body/OffUpper/OffLower:rotation"]:
				animation.remove_track(animation.find_track(NodePath(path),Animation.TYPE_VALUE))
			add_track(animation,"Skeleton/Body/OffUpper:rotation",sampled_times,baked_upper)
			add_track(animation,"Skeleton/Body/OffUpper/OffLower:rotation",sampled_times,baked_lower)
			library.add_animation(family+"_"+view,animation)
	return library
func arm_mesh(skeleton: Skeleton2D, prefix: String, segment: String) -> void:
	var mesh := Polygon2D.new(); mesh.name = prefix+segment+"Mesh"; owned(mesh,skeleton); mesh.skeleton = NodePath("..")
	var upper := body.get_node(prefix+"Upper") as Bone2D
	var lower := upper.get_node(prefix+"Lower") as Bone2D
	var start := upper.position if segment=="Upper" else upper.position+Vector2(0,20)
	var length_value := 20.0 if segment=="Upper" else 18.0
	var width := 9.0 if segment=="Upper" else 7.0
	var vertices := PackedVector2Array()
	for step in range(3):
		for edge in [-1,1]: vertices.append(start+Vector2(edge*(([13.0,9.0,7.0][step]) if segment=="Upper" else width)/2,step*length_value/2-3 if step==0 and segment=="Upper" else step*length_value/2))
	mesh.polygon = vertices; mesh.polygons = [PackedInt32Array([0,1,3,2]),PackedInt32Array([2,3,5,4])]
	var up: PackedFloat32Array = [1,1,1,1,0.55,0.55] if segment=="Upper" else [0.2,0.2,0,0,0,0]
	var down: PackedFloat32Array = []
	for weight in up: down.append(1-weight)
	mesh.add_bone(NodePath("Body/"+prefix+"Upper"),up)
	mesh.add_bone(NodePath("Body/"+prefix+"Upper/"+prefix+"Lower"),down)
func _initialize() -> void:
	var library := motions(); assert(ResourceSaver.save(library,OUT+"motions.tres")==OK)
	rig = Node2D.new(); rig.name = "SharedChampion"; rig.z_index = 10; rig.set_script(load("res://prototypes/animation_lab/shared_rig.gd"))
	var skeleton := Skeleton2D.new(); skeleton.name = "Skeleton"; owned(skeleton,rig)
	body = bone("Body",skeleton,Vector2.ZERO,0,1)
	sprite("Cape",body,Vector2(0,-72),0,-8)
	sprite("Torso",body,Vector2(0,-74),0,0)
	var head := bone("Head",body,Vector2(0,-112),0,1); sprite("Art",head,Vector2.ZERO,0,7)
	for side in ["Main","Off"]:
		var sign_value := 1 if side=="Main" else -1
		var leg := bone(side+"Leg",body,Vector2(sign_value*8,-49),PI/2,25)
		sprite("Art",leg,Vector2(12.5,0),-PI/2,-4)
		var shin := bone("Shin",leg,Vector2(25,0),0,24); sprite("Art",shin,Vector2(12,0),-PI/2,-4)
		var upper := bone(side+"Upper",body,Vector2(sign_value*12,-91),PI/2,20)
		var lower := bone(side+"Lower",upper,Vector2(20,0),0,18)
		var hand := bone(side+"Hand",lower,Vector2(18,0),0,7)
		sprite("Art",hand,Vector2(3.5,0),-PI/2,4)
		if side=="Main":
			var socket := Node2D.new(); socket.name = "WeaponSocket"; socket.position = Vector2(3.5,0); owned(socket,hand)
			sprite("Weapon",socket,Vector2.ZERO,0,3)
		arm_mesh(skeleton,side,"Upper"); arm_mesh(skeleton,side,"Lower")
	var player := AnimationPlayer.new(); player.name = "AnimationPlayer"; player.add_animation_library("",library); owned(player,rig)
	var walk := AnimationPlayer.new(); walk.name = "WalkPlayer"; var walk_library := AnimationLibrary.new(); var a := Animation.new(); a.length = 0.8; a.loop_mode = Animation.LOOP_LINEAR
	add_track(a,"Skeleton/Body:position",[0.0,0.2,0.4,0.6,0.8],[Vector2.ZERO,Vector2(0,-2),Vector2.ZERO,Vector2(0,-2),Vector2.ZERO])
	for side in ["Main","Off"]:
		var sign_value := 1 if side=="Main" else -1
		add_track(a,"Skeleton/Body/"+side+"Leg:rotation",[0.0,0.2,0.4,0.6,0.8],[PI/2,PI/2+sign_value*0.32,PI/2,PI/2-sign_value*0.32,PI/2])
		add_track(a,"Skeleton/Body/"+side+"Leg/Shin:rotation",[0.0,0.2,0.4,0.6,0.8],[0.0,-0.22*sign_value,0.0,0.22*sign_value,0.0])
	walk_library.add_animation("walk",a); walk.add_animation_library("",walk_library); owned(walk,rig)
	for is_contact in [false,true]:
		var overlay := Node2D.new(); overlay.name = "ContactMarkers" if is_contact else "Strings"
		overlay.set_script(load("res://prototypes/animation_lab/overlay.gd")); overlay.contacts = is_contact; overlay.z_index = 9 if is_contact else 3; owned(overlay,rig)
	var scene := PackedScene.new(); assert(scene.pack(rig)==OK); assert(ResourceSaver.save(scene,OUT+"shared_champion.tscn")==OK)
	rig.free(); print("Saved editable Bone2D rig, weighted arm meshes, six shared attack clips and walking library"); quit()
