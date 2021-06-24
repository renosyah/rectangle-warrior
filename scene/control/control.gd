extends Node2D
signal touch_position(pos)
signal join
signal host
signal disconnect

onready var _touch_input = $touch_input
onready var _disconnect_button = $CanvasLayer/disconnect
onready var _button_layout = $CanvasLayer/HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_button(_show):
	_button_layout.visible = _show
	_disconnect_button.visible = not _show

func _on_touch_input_any_gesture(_sig, val):
	if val is InputEventSingleScreenTap:
		emit_signal("touch_position", get_global_mouse_position())

func _on_Control_gui_input(event):
	if event is InputEventMouseButton and event.is_action_pressed("left_click"):
		emit_signal("touch_position", get_global_mouse_position())
		
	_touch_input.check_input(event)
	
func _on_join_pressed():
	emit_signal("join")
	
func _on_host_pressed():
	emit_signal("host")
	
func _on_disconnect_pressed():
	emit_signal("disconnect")
