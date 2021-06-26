extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var _bg = $CanvasLayer/bg

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_loading(_is_show : bool):
	_bg.visible = _is_show

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
