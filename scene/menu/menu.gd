extends Node

onready var _find_server = $CanvasLayer/find_server
onready var _dialog_input_name = $CanvasLayer/input_name
onready var _host_setting = $CanvasLayer/host_setting

# Called when the node enters the scene tree for the first time.
func _ready():
	_dialog_input_name.visible = false
	_host_setting.visible = false
	_find_server.visible = false
	
func _on_find_button_pressed():
	_dialog_input_name.visible = true
	
	
func _on_find_server_on_close():
	_find_server.stop_finding()
	_find_server.visible = false
	
	
func _on_find_server_on_join(info):
	Global.battle_setting.mode = "JOIN"
	Global.battle_setting.ip = info["ip"]
	Global.battle_setting.port = info["port"]
	Global.battle_setting.mobs = info["mobs"]
	
	get_tree().change_scene("res://scene/battle/battle.tscn")
	
func _on_find_server_on_create():
	_host_setting.visible = true

	
func _on_input_name_on_continue(_player_name, html_color):
	Global.player_name = _player_name
	Global.html_color = html_color
	_dialog_input_name.visible = false
	
	_find_server.start_finding()
	_find_server.visible = true
	
func _on_input_name_on_close():
	_dialog_input_name.visible = false
	
	
func _on_host_setting_create(_bots):
	Global.battle_setting.mode = "HOST"
	Global.battle_setting.mobs = _bots
	
	get_tree().change_scene("res://scene/battle/battle.tscn")
	
	
func _on_host_setting_close():
	_host_setting.visible = false




