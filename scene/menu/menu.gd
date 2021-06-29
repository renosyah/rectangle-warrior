extends Node

onready var _find_server = $CanvasLayer/find_server

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_environment("USERNAME"):
		Global.player_name = OS.get_environment("USERNAME")
	else:
	   Global.player_name = "Player"

func _on_host_button_pressed():
	Global.battle_setting.mode = "HOST"
	get_tree().change_scene("res://scene/battle/battle.tscn")


func _on_find_button_pressed():
	_find_server.start_finding()
	_find_server.visible = true


func _on_find_server_on_close():
	_find_server.stop_finding()
	_find_server.visible = false


func _on_find_server_on_join(info):
	Global.battle_setting.mode = "JOIN"
	Global.battle_setting.ip = info["ip"]
	Global.battle_setting.port = info["port"]
	Global.battle_setting.mobs = info["mobs"]
	
	get_tree().change_scene("res://scene/battle/battle.tscn")
	
	
	
