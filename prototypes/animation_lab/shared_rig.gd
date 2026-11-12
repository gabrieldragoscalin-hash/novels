@tool
extends Node2D
## One humanoid rig. Skins contain only artwork; equipment contains attachment data.
const Assets = preload("res://prototypes/animation_lab/assets.gd")
const UPPER := 20.0
const LOWER := 21.5 # Forearm18 + palm3.5, measured to the grip center.
@export_enum("aster","guard") var skin := "aster"
@export var string_pull := 0.0
@export_enum("sun_bow","moon_bow","hammer") var weapon_id := "sun_bow"
@export_enum("front","back","side","left") var view := "side"
var walking := false
var attacking := true
var paused := false
var debug_contacts := false
var pose_time := 0.0
var speed := 1.0
var animation: AnimationPlayer
var walk_animation: AnimationPlayer
var socket: Node2D
var weapon_sprite: Sprite2D
var grip_error := 0.0
var correction_radians := 0.0
var _last_look := ""
func _ready() -> void:
	animation = $AnimationPlayer; walk_animation = $WalkPlayer
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	walk_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	socket = $Skeleton/Body/MainUpper/MainLower/MainHand/WeaponSocket
	weapon_sprite = socket.get_node("Weapon")
	configure(skin,weapon_id,view)
func configure(next_skin: String, next_weapon: String, next_view: String) -> void:
	skin = next_skin; weapon_id = next_weapon; view = next_view
	if animation==null: return
	_last_look = appearance_key()
	var facing: String = "side" if view=="left" else view
	$Skeleton.scale.x = -1 if view=="left" else 1
	var sizes := {"head":Vector2(25,27),"torso":Vector2(36 if facing!="side" else 27,50),"cape":Vector2(44 if facing!="side" else 24,57),"thigh":Vector2(13,25),"shin":Vector2(11,24),"hand":Vector2(6,8)}
	for pair in [["Head/Art","head"],["Torso","torso"],["Cape","cape"],["MainLeg/Art","thigh"],["OffLeg/Art","thigh"],["MainLeg/Shin/Art","shin"],["OffLeg/Shin/Art","shin"]]:
		var sprite: Sprite2D = get_node("Skeleton/Body/"+pair[0]); _sprite(sprite,Assets.frame(skin+"_"+facing+"_"+pair[1]),sizes[pair[1]])
	for arm in ["Main","Off"]:
		var hand: Sprite2D = get_node("Skeleton/Body/"+arm+"Upper/"+arm+"Lower/"+arm+"Hand/Art")
		_sprite(hand,Assets.frame(skin+"_grip_"+facing),sizes["hand"])
		hand.flip_h = arm=="Off"
		for segment in ["Upper","Lower"]:
			var mesh: Polygon2D = get_node("Skeleton/"+arm+segment+"Mesh")
			var key := skin+"_"+facing+"_"+("upper" if segment=="Upper" else "lower")
			mesh.texture = Assets.SHEETS[skin]
			var rect: Rect2i = Assets.Atlas.REGIONS[key]
			var uv := PackedVector2Array()
			for step in range(3):
				for edge in [0,1]: uv.append(Vector2(rect.position)+Vector2(edge*rect.size.x,step*rect.size.y/2.0))
			mesh.uv = uv
			mesh.z_index = -2 if facing=="back" or (facing=="side" and arm=="Off") or segment=="Upper" else 2
	if facing=="side": get_node("Skeleton/MainUpperMesh").z_index = 1
	$Skeleton/Body/MainLeg.position.x = 3 if facing=="side" else 8
	$Skeleton/Body/OffLeg.position.x = -3 if facing=="side" else -8
	var info: Resource = Assets.WEAPONS[weapon_id]
	_sprite(weapon_sprite,Assets.frame(weapon_id),info["size"])
	weapon_sprite.position = (Vector2.ONE*0.5-info["grip"])*info["size"]
	weapon_sprite.flip_h = facing=="back" and info["family"]=="bow"
	if weapon_sprite.flip_h: weapon_sprite.position.x *= -1
	var clip: String = info["family"]+"_"+facing
	animation.play(clip); animation.seek(pose_time*animation.current_animation_length,true)
	walk_animation.play("walk"); _support_contact(); refresh_overlays()
func _sprite(sprite: Sprite2D, texture: Texture2D, size: Vector2) -> void:
	sprite.texture = texture; sprite.scale = size/texture.get_size()
func _process(delta: float) -> void:
	if animation==null: return
	if Engine.is_editor_hint():
		if _last_look!=appearance_key(): configure(skin,weapon_id,view)
		refresh_overlays(); return
	if not paused:
		if attacking: animation.advance(delta*speed)
		else: animation.seek(0,true)
		if walking: walk_animation.advance(delta*speed)
		else: walk_animation.seek(0,true)
		pose_time = animation.current_animation_position/animation.current_animation_length
	_support_contact(); refresh_overlays()
func seek_phase(phase: float) -> void:
	pose_time = clampf(phase,0,0.999)
	animation.seek(pose_time*animation.current_animation_length,true); _support_contact(); refresh_overlays()
func _support_contact() -> void:
	# Only the support arm receives a grip correction. Main arm and weapon motion
	# are authored AnimationPlayer tracks, never reconstructed from enemy aim.
	var info: Resource = Assets.WEAPONS[weapon_id]
	var offset: Vector2 = info.support
	if info["family"]=="bow": offset = Vector2((info["string_x"]-string_pull)*(-1 if view=="back" else 1),0)
	var target: Vector2 = $Skeleton/Body.to_local(socket.to_global(offset))
	var upper: Bone2D = $Skeleton/Body/OffUpper
	var lower: Bone2D = $Skeleton/Body/OffUpper/OffLower
	var delta: Vector2 = target-upper.position
	var distance: float = delta.length()
	if distance>UPPER+LOWER or distance<absf(UPPER-LOWER)+0.1:
		grip_error = $Skeleton/Body/OffUpper/OffLower/OffHand.to_global(Vector2(3.5,0)).distance_to(socket.to_global(offset)); return
	var along: float = (UPPER*UPPER-LOWER*LOWER+distance*distance)/(2*distance)
	var bend := -1.0 if view=="back" else 1.0
	var elbow: Vector2 = upper.position+delta.normalized()*along+Vector2(-delta.y,delta.x).normalized()*sqrt(maxf(0,UPPER*UPPER-along*along))*bend
	var next_upper := (elbow-upper.position).angle()
	var next_lower := (target-elbow).angle()-next_upper
	correction_radians = maxf(absf(wrapf(next_upper-upper.rotation,-PI,PI)),absf(wrapf(next_lower-lower.rotation,-PI,PI)))
	upper.rotation = next_upper
	lower.rotation = next_lower
	var hand: Bone2D = $Skeleton/Body/OffUpper/OffLower/OffHand
	hand.rotation = 0
	grip_error = hand.to_global(Vector2(3.5,0)).distance_to(socket.to_global(offset))
func draw_overlay(canvas: CanvasItem, contacts: bool) -> void:
	if socket==null: return
	var info: Resource = Assets.WEAPONS[weapon_id]
	if not contacts and info["family"]=="bow":
		var mirror_x := -1 if view=="back" else 1
		var tips: Vector2 = info["tips"]
		var grip := Vector2((info["string_x"]-string_pull)*mirror_x,0)
		for sign_value in [-1,1]:
			canvas.draw_line(to_local(socket.to_global(Vector2(tips.x*mirror_x,tips.y*sign_value))),to_local(socket.to_global(grip)),Color("ead9ad"),0.8,true)
	if contacts and debug_contacts:
		for point in [socket.global_position,$Skeleton/Body/OffUpper/OffLower/OffHand.to_global(Vector2(3.5,0))]: canvas.draw_circle(to_local(point),2,Color.GREEN)

func appearance_key() -> String:
	var profile: Resource = Assets.WEAPONS[weapon_id]
	return str(skin,weapon_id,view,profile.size,profile.grip,profile.string_x,profile.tips,profile.support,profile.texture)

func refresh_overlays() -> void:
	for path in ["Strings","ContactMarkers"]:
		if has_node(path): get_node(path).queue_redraw()
