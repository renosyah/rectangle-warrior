extends Node2D

signal touch_position(pos)
signal autoplay_pressed(_autoplay)
signal on_menu_press
signal disconnect

onready var _control_ui = $CanvasLayer/Control
onready var _touch_input = $touch_input
onready var _minimap = $CanvasLayer/Control/MiniMap
onready var _autoplay_label = $CanvasLayer/Control/bottom_menu/HBoxContainer/auto_play_label
onready var _autoplay_button_icon = $CanvasLayer/Control/bottom_menu/HBoxContainer/autoplay_button/TextureRect
onready var _expand_map_button_icon = $CanvasLayer/Control/bottom_menu/HBoxContainer/expand_map_button/TextureRect
onready var _disconnect_dialog = $CanvasLayer/Control/disconect_dialog_confirm
onready var _tween = $Tween
onready var _score_board = $CanvasLayer/Control/score_board
onready var _loading = $CanvasLayer/loading
onready var _deadscreen = $CanvasLayer/Control/deadscreen

var _minimap_fix_position : Vector2
var autoplay = false


# Called when the node enters the scene tree for the first time.
func _ready():
	_autoplay_label.text = "Autoplay : off"
	_disconnect_dialog.visible = false
	_loading.show_loading(true)
	_deadscreen.show_deadscreen(false)
	
func show_control(_is_show : bool):
	_control_ui.visible = _is_show
	
func show_loading(_is_show : bool):
	_loading.show_loading(_is_show)
	
func show_deadscreen(_is_show : bool, _killed_by : String = ""):
	_deadscreen.show_deadscreen(_is_show, _killed_by)
	
func set_interface_color(_color):
	_minimap.set_minimap_border_color(_color)
	_autoplay_button_icon.self_modulate = _color
	_expand_map_button_icon.self_modulate = _color
	
func set_minimap_camera(camera):
	_minimap.set_camera(camera)

func add_minimap_object(object):
	_minimap.add_object(object)
	
func remove_minimap_object(object):
	_minimap.remove_object(object)
	
	
func _set_minimap_to_fullsize():
	_minimap.mode = _minimap.EXPAND
	_minimap.anchor_top = 0
	_minimap.anchor_bottom = 0
	_minimap.anchor_left = 0
	_minimap.anchor_right = 0
	_minimap.rect_position = Vector2.ZERO
	_tween.interpolate_property(_minimap, "rect_size", _minimap.rect_size, get_viewport().size, 0.1)
	_tween.start()
	
func _set_minimap_to_smallsize():
	_minimap.mode = _minimap.NORMAL
	_minimap.anchor_top = 0
	_minimap.anchor_bottom = 0
	_minimap.anchor_left = 0
	_minimap.anchor_right = 0
	_minimap.rect_position = _minimap_fix_position
	_tween.interpolate_property(_minimap, "rect_size", _minimap.rect_size, Vector2(200,200), 0.1)
	_tween.start()
	
func show_scoreboard():
	_score_board.visible = true
	
func update_scoreboard(_scoredata):
	_score_board.set_scoredata(_scoredata)
	
func _on_touch_input_any_gesture(_sig, val):
	if val is InputEventSingleScreenTap:
		emit_signal("touch_position", get_global_mouse_position())

func _unhandled_input(event):
	if autoplay:
		return
		
	if event is InputEventMouseButton and event.is_action_pressed("left_click"):
		emit_signal("touch_position", get_global_mouse_position())
			
	_touch_input.check_input(event)
	
func _on_menu_button_pressed():
	emit_signal("on_menu_press")
	
func _on_score_board_disconnect():
	_score_board.visible = false
	_disconnect_dialog.visible = true
	
	
func _on_disconect_dialog_confirm_on_no():
	_disconnect_dialog.visible = false
	
	
func _on_disconect_dialog_confirm_on_yes():
	emit_signal("disconnect")
	
	
func _on_autoplay_button_toggled(button_pressed):
	var _icn = preload("res://assets/ui/icons/auto_play_start.png")
	_autoplay_label.text = "Autoplay : off"
		
	if button_pressed:
		_autoplay_label.text = "Autoplay : on"
		_icn = preload("res://assets/ui/icons/auto_play_stop.png")
		
	_autoplay_button_icon.texture = _icn
	
	autoplay = button_pressed
	emit_signal("autoplay_pressed", autoplay)
	
func _on_expand_map_button_toggled(button_pressed):
	if button_pressed:
		_set_minimap_to_fullsize()
	else:
		_set_minimap_to_smallsize()














