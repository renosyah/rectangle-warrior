extends KinematicBody2D

enum { IDLE,WALKING }
const MOVE_SPEED = 800.0

signal on_ready(warrior)

onready var _rng = RandomNumberGenerator.new()
onready var _label = $Node2D/Label
onready var _sprite = $Sprite
onready var _animation = $AnimationPlayer
onready var _idle_timer = $Timer
onready var _remote_transform = $RemoteTransform2D

var camera = null #nodePath
var rally_point = null #vector2

puppet var _position = position
puppet var _state = IDLE

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
	emit_signal("on_ready", self)
	
func move_to(_pos: Vector2):
	rally_point = _pos
	rpc("_facing_direction",(rally_point - global_position).normalized())
	set_process(true)

remotesync func _facing_direction(_dir):
	if _dir.x > 0:
		_sprite.scale.x = 1
	else:
		_sprite.scale.x = -1

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
	
	if rally_point:
		direction = (rally_point - global_position).normalized()
		distance_to_target = global_position.distance_to(rally_point)
		
		if distance_to_target > 55.0:
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
			
	else:
		state = IDLE
		_animation.play("idle")
		set_process(false)
		
	move_and_slide(velocity)
		
	rset("_position", position)
	rset_unreliable("_state", state)
	
func _puppet_move():
	position = _position
	
	match _state:
		IDLE:
			_animation.play("idle")
		WALKING:
			_animation.play("walking")
		
func _on_Timer_timeout():
	emit_signal("on_ready", self)
	
