extends Control

signal on_close()

onready var _message = $Panel/VBoxContainer/HBoxContainer2/message

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func show_message(_text):
	_message.text = _text

func _on_ok_pressed():
	emit_signal("on_close")
