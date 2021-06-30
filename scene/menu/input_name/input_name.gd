extends Control

signal on_close()
signal on_continue(_player_name, html_color)

onready var _rng = RandomNumberGenerator.new()
onready var _input_color_button_color = $disconect_dialog_confirm/VBoxContainer/HBoxContainer2/choose_color/ColorRect
onready var _ready_button = $disconect_dialog_confirm/VBoxContainer/HBoxContainer/continue
onready var _input_name = $disconect_dialog_confirm/VBoxContainer/HBoxContainer2/input_name

var player_name = ""
var html_color = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	_input_name.text = RandomNameGenerator.generate()
	_rng.randomize()
	_ready_button.disabled = false
	_on_choose_color_pressed()

func _on_continue_pressed():
	player_name = _input_name.text
	emit_signal("on_continue", player_name, html_color)
	
func _on_input_name_text_changed(new_text):
	_ready_button.disabled = str(new_text).empty()


func _on_button_close_pressed():
	emit_signal("on_close")


func _on_choose_color_pressed():
	var _color = Color(_rng.randf(),_rng.randf(),_rng.randf(),1.0)
	html_color = _color.to_html()
	_input_color_button_color.color = _color
	
	
	
	
	
	
