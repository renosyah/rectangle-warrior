extends Control

signal disconnect

onready var _score_container = $CenterContainer/Panel/VBoxContainer/ScrollContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func showscore(scoredata):
	for child in _score_container.get_children():
		_score_container.remove_child(child)
	
	for key in scoredata.keys():
		var item = preload("res://scene/control/score_board/item/item.tscn").instance()
		item.data = scoredata[key]
		_score_container.add_child(item)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_disconnect_button_pressed():
	emit_signal("disconnect")


func _on_button_close_pressed():
	visible = false
