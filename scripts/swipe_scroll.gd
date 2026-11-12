extends ScrollContainer
## Capture touch drags before item buttons; a swipe must never become a tap.
signal swipe_started
var finger := -1
var origin := Vector2.ZERO
var initial_scroll := 0
var dragging := false
var suppress_until := 0
var velocity := 0.0
func suppress_click() -> bool:
	return dragging or Time.get_ticks_msec() < suppress_until
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): finger = -1; velocity = 0; return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and get_global_rect().has_point(event.position):
			finger = event.index; origin = event.position; initial_scroll = scroll_vertical; dragging = false; velocity = 0
		elif event.index == finger and not event.pressed:
			if dragging:
				suppress_until = Time.get_ticks_msec() + 250
				get_viewport().set_input_as_handled()
			finger = -1; dragging = false
	elif event is InputEventScreenDrag and event.index == finger:
		if not dragging and absf(event.position.y - origin.y) > 10:
			dragging = true; swipe_started.emit()
		if dragging:
			scroll_vertical = initial_scroll + roundi(origin.y - event.position.y)
			velocity = -event.velocity.y
			get_viewport().set_input_as_handled()
func _process(delta: float) -> void:
	if finger != -1 or not is_visible_in_tree(): return
	if absf(velocity) > 5:
		var previous := scroll_vertical
		scroll_vertical += roundi(velocity * delta)
		velocity = move_toward(velocity, 0, 2400 * delta)
		if previous == scroll_vertical: velocity = 0
