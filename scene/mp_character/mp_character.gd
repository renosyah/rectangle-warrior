extends KinematicBody2D

signal _on_puppet_position_update(_pos)
signal _on_puppet_facing_direction_update(_fd)
signal _on_puppet_velocity_update(_vel)
signal _on_puppet_state_update(_st)

enum { IDLE,WALKING }
const MOVE_SPEED = 90.0
const RANGE_ATTACK = 80.0
var HIT_POINT = 10.0
var ATTACK_DMG = 1.0
var ATTACK_ACCURACY = 0.5
var MINIMAP_MARKER = "troop"
var MINIMAP_COLOR = Color.white

puppet var _puppet_position : Vector2 = position setget _set_puppet_position
puppet var _puppet_state : int = IDLE setget _set_puppet_state
puppet var _puppet_facing_direction : int = 1 setget _set_puppet_facing_direction
puppet var _puppet_velocity : Vector2 = Vector2.ZERO setget _set_puppet_velocity

func _set_puppet_position(_val : Vector2):
	_puppet_position = _val
	emit_signal("_on_puppet_position_update", _puppet_position)
	
func _set_puppet_facing_direction(_val : int):
	_puppet_facing_direction = _val
	emit_signal("_on_puppet_facing_direction_update", _puppet_facing_direction)
	
func _set_puppet_velocity(_val : Vector2):
	_puppet_velocity = _val
	emit_signal("_on_puppet_velocity_update", _puppet_velocity)
	
func _set_puppet_state(_val : int):
	_puppet_state = _val
	emit_signal("_on_puppet_state_update", _puppet_state)





