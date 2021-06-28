extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var _bg = $CanvasLayer/bg
onready var _screen = $CanvasLayer/CenterContainer
onready var _killedby = $CanvasLayer/CenterContainer/VBoxContainer/killedby

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_deadscreen(_is_show : bool, _killed_by : String = ""):
	_bg.visible = _is_show
	_screen.visible = _is_show
	_killedby.text = "Killed By " + _killed_by

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
