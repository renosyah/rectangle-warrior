extends KinematicBody2D

enum { IDLE,WALKING }
const MOVE_SPEED = 90.0
const RANGE_ATTACK = 80.0
var HIT_POINT = 10.0
var ATTACK_DMG = 1.0
var ATTACK_ACCURACY = 0.5
var MINIMAP_MARKER = "troop"


const dead_sound = [
	preload("res://assets/sound/maledeath1.wav"),
	preload("res://assets/sound/maledeath2.wav"),
	preload("res://assets/sound/maledeath3.wav"),
	preload("res://assets/sound/maledeath4.wav"),
]
const combats_sound = [
	preload("res://assets/sound/fight1.wav"),
	preload("res://assets/sound/fight2.wav"),
	preload("res://assets/sound/stab2.wav"),
	preload("res://assets/sound/stab2.wav"),
	preload("res://assets/sound/fight3.wav"),
	preload("res://assets/sound/stab1.wav"),
	preload("res://assets/sound/fight4.wav"),
	preload("res://assets/sound/stab1.wav"),
	preload("res://assets/sound/fight5.wav"),
	preload("res://assets/sound/stab1.wav"),
	preload("res://assets/sound/stab2.wav"),
]
const stabs_sound = [
	preload("res://assets/sound/stab1.wav"),
	preload("res://assets/sound/stab2.wav"),
]

signal on_click(warrior)
signal on_ready(warrior)
signal on_attacked(warrior, attack_by_node_name)
signal on_dead(warrior, killed_by_player_name)

onready var _rng = RandomNumberGenerator.new()
onready var _label = $Node2D/Label
onready var _body = $body
onready var _upper_animation = $body/AnimationPlayer
onready var _animation = $AnimationPlayer
onready var _idle_timer = $Timer
onready var _remote_transform = $RemoteTransform2D
onready var _touch_input = $touch_input
onready var _attack_delay = $attack_delay
onready var _tween = $Tween
onready var _spawn_time = $spawn_time
onready var _hitpoint = $Node2D/hitpoint
onready var _hit_delay = $hit_delay
onready var _audio = $AudioStreamPlayer2D
onready var _highlight = $Node2D/highlight

var is_alive = true
var target : KinematicBody2D = null
var camera = null # nodePath
var rally_point = null # vector2
var _killed_by = ""

var _velocity = Vector2.ZERO
var _state = IDLE
var _facing_direction = 1

puppet var _puppet_position = position setget puppet_position_set
puppet var _puppet_state = IDLE
puppet var _puppet_facing_direction = 1
puppet var _puppet_velocity = Vector2.ZERO

var label_color = Color.white
var data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(false)
	_highlight.visible = false
	make_ready()
	
func make_ready():
	
	if camera:
		_remote_transform.remote_path = camera
		_remote_transform.update()
		
	if data.empty():
		return
	
	_label.text = data.name
	_label.self_modulate = label_color
	
	rally_point = null
	target = null
	_hitpoint.value = HIT_POINT

	_idle_timer.wait_time = 1.0
	_idle_timer.start()
	
func move_to(_pos: Vector2):
	if not is_alive:
		return
		
	rally_point = _pos
	target = null
	rpc("_holsted")
	set_process(true)
	
func attack_target(_target : KinematicBody2D):
	if not is_alive:
		return
		
	rally_point = null
	target = _target
	set_process(true)
	
func highlight():
	_highlight.visible = true

func _check_facing_direction(_direction) -> int:
	if _direction.x > 0:
		return 1
	return -1


func puppet_position_set(_val):
	_puppet_position = _val
	_tween.interpolate_property(self,"position", position, _puppet_position, 0.1)
	_tween.start()
	
	
	
remotesync func _play_attack():
	_upper_animation.play("swing")
	
remotesync func _holsted():
	_upper_animation.play("nothing")
	
func _on_attack_execute():
	if is_network_master() and is_instance_valid(target):
		if _rng.randf() < ATTACK_ACCURACY:
			target.rpc("hit", ATTACK_DMG, name, data.name)

remotesync func hit(_dmg, _node_name ,_by):
	HIT_POINT -= _dmg
	_hitpoint.value = HIT_POINT
	_play_stab_sound()
	
	emit_signal("on_attacked", self, _node_name)
	
	_body.modulate = Color.red
	_hit_delay.start()
	
	if HIT_POINT < 0.0:
		rpc("die", _by)
		

	
remotesync func die(_by):
	_killed_by = _by
	is_alive = false
	_play_dead_sound()
	_animation.play("die")
	
	
func _on_dead():
	visible = false
	emit_signal("on_dead", self, _killed_by)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_network_master():
		_master_move(_delta)
	else:
		puppet_update(_delta)
	
func _master_move(_delta):
	var distance_to_target = 0.0
	
	if not is_alive:
		rpc("_holsted")
		target = null
		return
	
	if rally_point:
		var direction = (rally_point - global_position).normalized()
		distance_to_target = global_position.distance_to(rally_point)
		_facing_direction = _check_facing_direction(direction)
		
		if distance_to_target > 55.0:
			_state = WALKING
			_animation.play("walking")
			_body.scale.x = _facing_direction
			
			_velocity = direction * MOVE_SPEED
			
		else:
			_state = IDLE
			_animation.play("idle")
			rally_point = null
			set_process(false)
			
			_idle_timer.wait_time = _rng.randf_range(1,2)
			_idle_timer.start()
			
			_velocity = Vector2.ZERO
			
	elif is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		distance_to_target = global_position.distance_to(target.global_position)
		_facing_direction = _check_facing_direction(direction)
		
		if target.is_alive:
			if distance_to_target > RANGE_ATTACK:
				_state = WALKING
				_animation.play("walking")
				_body.scale.x = _facing_direction
				
				_velocity = direction * MOVE_SPEED
				
			elif distance_to_target <= RANGE_ATTACK:
				_body.scale.x = _facing_direction
				rpc("_play_attack")
				
				if _attack_delay.is_stopped():
					_attack_delay.wait_time = 1.0
					_attack_delay.start()
					
				_velocity = Vector2.ZERO
				
		else:
			_state = IDLE
			_animation.play("idle")
			rpc("_holsted")
			target = null
			set_process(false)
			
			_idle_timer.wait_time = _rng.randf_range(1,2)
			_idle_timer.start()
			
	else:
		_state = IDLE
		_animation.play("idle")
		set_process(false)
		
		_idle_timer.wait_time = _rng.randf_range(1,2)
		_idle_timer.start()
		
	_velocity = move_and_slide(_velocity)
		
		
func puppet_update(_delta):
	if not is_alive:
		return
		
	_body.scale.x = _puppet_facing_direction
	if not _tween.is_active():
		move_and_slide(_puppet_velocity)
		
	match _puppet_state:
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
	
func _on_network_tickrate_timeout():
	if is_network_master():
		rset_unreliable("_puppet_position", position)
		rset_unreliable("_puppet_state", _state)
		rset_unreliable("_puppet_facing_direction", _facing_direction)
		rset_unreliable("_puppet_velocity", _velocity)
	
	
func _on_spawn_time_timeout():
	rpc("spawn")
	
func set_spawn_time():
	_spawn_time.wait_time = 5.0
	_spawn_time.start()
	
remotesync func spawn():
	HIT_POINT = 10.0
	_hitpoint.value = HIT_POINT
	is_alive = true
	visible = true
	_state = IDLE
	_animation.play("idle")
	emit_signal("on_ready", self)


func _on_hit_delay_timeout():
	_body.modulate = Color.white
	
	
func _play_fighting_sound():
	if not visible:
		return
		
	_rng.randomize()
	_audio.stream = combats_sound[_rng.randf_range(0,combats_sound.size())]
	_audio.play()
	
func _play_stab_sound():
	if not visible:
		return
		
	_rng.randomize()
	_audio.stream = stabs_sound[_rng.randf_range(0,stabs_sound.size())]
	_audio.play()
	
func _play_dead_sound():
	if not visible:
		return
		
	_rng.randomize()
	_audio.stream = dead_sound[_rng.randf_range(0,dead_sound.size())]
	_audio.play()








