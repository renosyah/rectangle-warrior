extends Control

signal on_close()
signal on_continue(_player_name)

onready var _ready_button = $disconect_dialog_confirm/VBoxContainer/HBoxContainer/continue
onready var _input_name = $disconect_dialog_confirm/VBoxContainer/HBoxContainer2/input_name

var player_name = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	_ready_button.disabled = true

func _on_continue_pressed():
	player_name = _input_name.text
	emit_signal("on_continue", player_name)
	
func _on_input_name_text_changed(new_text):
	_ready_button.disabled = str(new_text).empty()


func _on_button_close_pressed():
	emit_signal("on_close")
