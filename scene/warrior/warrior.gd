extends KinematicBody2D

enum { IDLE,WALKING }
const MOVE_SPEED = 120.0
const RANGE_ATTACK = 80.0

signal on_click(warrior)
signal on_ready(warrior)

onready var _rng = RandomNumberGenerator.new()
onready var _label = $Node2D/Label
onready var _body = $body
onready var _upper_animation = $body/AnimationPlayer
onready var _animation = $AnimationPlayer
onready var _idle_timer = $Timer
onready var _remote_transform = $RemoteTransform2D
onready var _touch_input = $touch_input
onready var _attack_delay = $attack_delay

var is_alive = true
var target : KinematicBody2D = null
var camera = null # nodePath
var rally_point = null # vector2

puppet var _position = position
puppet var _state = IDLE
puppet var _dir = 1

var label_color = Color.white
var data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(false)
	
	if camera:
		_remote_transform.remote_path = camera
		_remote_transform.update()
		
	if data.empty():
		return
	
	_label.text = data.name
	_label.self_modulate = label_color
	
	_idle_timer.wait_time = 1.0
	_idle_timer.start()
	
func move_to(_pos: Vector2):
	rally_point = _pos
	rpc("_holsted")
	set_process(true)
	
func attack_target(_target : KinematicBody2D):
	rally_point = null
	target = _target
	set_process(true)

func get_update_from_master():
	if not is_instance_valid(get_tree().get_network_peer()):
		return
		
	if is_network_master():
		return
		
	rpc("_get_update_from_master")

func _check_facing_direction(_dir) -> int:
	if _dir.x > 0:
		return 1
	return -1

remotesync func _play_attack():
	_upper_animation.play("punch")
	
remotesync func _holsted():
	_upper_animation.play("nothing")
	
remote func _get_update_from_master():
	if not is_network_master():
		return
		
	rset("_position", position)
	rset_unreliable("_dir", _body.scale.x)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_network_master():
		_master_move(_delta)
	else:
		_puppet_move()
		
	
func _master_move(_delta):
	var velocity = Vector2.ZERO
	var direction = Vector2.ZERO
	var distance_to_target = 0.0
	var state = IDLE
	var facing_dir = 1
	
	if rally_point:
		direction = (rally_point - global_position).normalized()
		distance_to_target = global_position.distance_to(rally_point)
		facing_dir = _check_facing_direction(direction)
		
		if distance_to_target > 55.0:
			_body.scale.x = facing_dir
			velocity = direction * MOVE_SPEED
			state = WALKING
			_animation.play("walking")
			
		else:
			state = IDLE
			_animation.play("idle")
			rally_point = null
			set_process(false)
			_idle_timer.wait_time = _rng.randf_range(1,2)
			_idle_timer.start()
			
	elif target:
		direction = (target.global_position - global_position).normalized()
		distance_to_target = global_position.distance_to(target.global_position)
		facing_dir = _check_facing_direction(direction)
		
		if target.is_alive:
			
			if distance_to_target > RANGE_ATTACK:
				_body.scale.x = facing_dir
				state = WALKING
				_animation.play("walking")
				velocity = direction * MOVE_SPEED
				
			elif distance_to_target <= RANGE_ATTACK:
				_body.scale.x = facing_dir
				state = IDLE
				_animation.play("idle")
				rpc("_play_attack")
				if _attack_delay.is_stopped():
					_attack_delay.wait_time = 1.0
					_attack_delay.start()
					
		else:
			rpc("_holsted")
			target = null
			
	else:
		state = IDLE
		_animation.play("idle")
		set_process(false)
		
	move_and_slide(velocity)
	
	rset("_position", position)
	rset_unreliable("_state", state)
	rset_unreliable("_dir", facing_dir)
	
func _puppet_move():
	position = _position
	_body.scale.x = _dir
	
	match _state:
		IDLE:
			_animation.play("idle")
		WALKING:
			_animation.play("walking")
		
		
func _on_Timer_timeout():
	emit_signal("on_ready", self)
	
	
func _on_Control_gui_input(event):
	if event is InputEventMouseButton and event.is_action_pressed("left_click"):
		on_warrior_click()
		
	_touch_input.check_input(event)

func _on_touch_input_any_gesture(_sig, val):
	if val is InputEventSingleScreenTap:
		on_warrior_click()
	
func on_warrior_click():
	emit_signal("on_click", self)
	
	
	
	
	

