extends Node

onready var _rng = RandomNumberGenerator.new()
onready var _terrain = $terrain
onready var _tree_holder = $tree_holder
onready var _main_menu = $CanvasLayer/main_menu
onready var _find_server = $CanvasLayer/find_server
onready var _dialog_input_name = $CanvasLayer/input_name
onready var _host_setting = $CanvasLayer/host_setting
onready var _error_dialog = $CanvasLayer/error_dialog

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.network_error != "":
		_error_dialog.show_message(Global.network_error)
		_error_dialog.visible = true
		
	set_background()
	_dialog_input_name.visible = false
	_host_setting.visible = false
	_find_server.visible = false
	_main_menu.visible = true
	
func set_background():
	_terrain.biom = Biom.BIOMS[_rng.randf_range(0,Biom.BIOMS.size())].id
	_terrain.create_simplex()
	_terrain.setup_enviroment()
	_terrain.generate_battlefield()
	
	for enviroment in _terrain.enviroments:
		if enviroment.type == "bush":
			_terrain.spawn_bush(_tree_holder,enviroment.texture_asset,enviroment.position)
		elif enviroment.type == "tree":
			_terrain.spawn_tree(_tree_holder,enviroment.texture_asset,enviroment.position)
		
	
func _on_find_button_pressed():
	_dialog_input_name.visible = true
	_main_menu.visible = false
	
func _on_find_server_on_close():
	_find_server.stop_finding()
	_find_server.visible = false
	_main_menu.visible = true
	
func _on_find_server_on_join(info):
	Global.battle_setting.mode = "JOIN"
	Global.battle_setting.ip = info["ip"]
	Global.battle_setting.port = info["port"]
	Global.battle_setting.bots = info["bots"]
	
	get_tree().change_scene("res://scene/battle/battle.tscn")
	
func _on_find_server_on_create():
	_host_setting.visible = true

	
func _on_input_name_on_continue(_player_name, html_color):
	Global.player.name = _player_name
	Global.player.html_color = html_color
	_dialog_input_name.visible = false
	
	_find_server.start_finding()
	_find_server.visible = true
	
func _on_input_name_on_close():
	_dialog_input_name.visible = false
	_main_menu.visible = true
	
func _on_host_setting_create(_bots):
	Global.battle_setting.mode = "HOST"
	Global.battle_setting.bots = _bots
	
	get_tree().change_scene("res://scene/battle/battle.tscn")
	
	
func _on_host_setting_close():
	_host_setting.visible = false
	
	
func _on_error_dialog_on_close():
	Global.network_error = ""
	_error_dialog.visible = false
