extends Control

signal disconnect

onready var _score_container = $CenterContainer/Panel/VBoxContainer/ScrollContainer/VBoxContainer

class ScoreSorter:
	static func sort(a, b):
		if a["kill_count"] > b["kill_count"]:
			return true
		return false
		
		
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func set_scoredata(scoredata):
	if scoredata.empty():
		return
		
	var _scores = []
	for key in scoredata.keys():
		_scores.append(scoredata[key])
		
	_scores.sort_custom(ScoreSorter, "sort")
		
	for child in _score_container.get_children():
		_score_container.remove_child(child)
		
	for score in _scores:
		var item = preload("res://scene/control/score_board/item/item.tscn").instance()
		item.data = score
		_score_container.add_child(item)
	

func _on_disconnect_button_pressed():
	emit_signal("disconnect")


func _on_button_close_pressed():
	visible = false
