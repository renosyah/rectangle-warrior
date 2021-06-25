extends Node

onready var _find_server = $CanvasLayer/find_server

var battle_setting = {
	mode = "HOST",
	ip = "",
	port = 0
}

# Called when the node enters the scene tree for the first time.
func _ready():
	var s = SaveLoad.new()
	s.delete_save("battle_setting.data")

func _on_host_button_pressed():
	battle_setting.mode = "HOST"
	
	var s = SaveLoad.new()
	s.save("battle_setting.data", battle_setting)
	
	get_tree().change_scene("res://scene/battle/battle.tscn")


func _on_find_button_pressed():
	_find_server.visible = true


func _on_find_server_on_close():
	_find_server.visible = false


func _on_find_server_on_join(info):
	battle_setting.mode = "JOIN"
	battle_setting.ip = info["ip"]
	battle_setting.port = info["port"]
	
	var s = SaveLoad.new()
	s.save("battle_setting.data", battle_setting)
	
	get_tree().change_scene("res://scene/battle/battle.tscn")
	
	
	