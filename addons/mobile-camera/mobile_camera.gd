extends Camera2D
class_name MobileCamera

signal on_camera_moving( _pos, _zoom)

var achor_is_set : bool = false
var center_anchor : Node = null
var max_distance_from_achor : float = 750.0

var min_zoom : float = 0.4
var max_zoom : float = 2.2
var zoom_sensitivity : float = 10.0
var zoom_speed : float = 0.05

var events : Dictionary = {}
var last_drag_distance : float = 0.0
var enable  : bool = true
var drag_speed : float = 200.0

func set_anchor(pos : Node, max_dis : float = 750.0) -> void:
	achor_is_set = true
	center_anchor = pos
	max_distance_from_achor = max_dis
	
func _process(delta):
	if !enable:
		return
		
	var velocity = Vector2.ZERO
	velocity.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up") 
	
	if achor_is_set and is_instance_valid(center_anchor):
		var distance_to_anchor = (global_position + velocity * delta * 1250).distance_to(center_anchor.global_position)
		if distance_to_anchor > max_distance_from_achor:
			return
		
	position += velocity * delta * 1250
	
func parsing_input(event) -> void:
	_unhandled_input(event)
	
func _unhandled_input(event):
	if !enable:
		return
		
	if smoothing_enabled:
		smoothing_enabled = false
		
	if event.is_action("scroll_up"):
		if(zoom.x - zoom_speed>= min_zoom && zoom.y - zoom_speed >= min_zoom):
			zoom.x -= zoom_speed
			zoom.y -= zoom_speed

	elif event.is_action("scroll_down"):
		if(zoom.x + zoom_speed <= max_zoom && zoom.y + zoom_speed <= max_zoom):
			zoom.x += zoom_speed
			zoom.y += zoom_speed
			
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
			
		else:
			events.erase(event.index)

	if event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() == 1:
			
			if achor_is_set and is_instance_valid(center_anchor):
				var distance_to_anchor = (global_position + ((-event.relative) * zoom.x)).distance_to(center_anchor.global_position)
				if distance_to_anchor > max_distance_from_achor:
					return
					
			position += (-event.relative) * zoom.x
			
		elif events.size() == 2:
			var drag_distance = events[0].position.distance_to(events[1].position)
			if abs(drag_distance - last_drag_distance) > zoom_sensitivity:
				var new_zoom = (1 + zoom_speed) if drag_distance < last_drag_distance else (1 - zoom_speed)
				new_zoom = clamp(zoom.x * new_zoom, min_zoom, max_zoom)
				zoom = Vector2.ONE * new_zoom
				last_drag_distance = drag_distance
				
	emit_signal("on_camera_moving", position, zoom)
				
				
				
