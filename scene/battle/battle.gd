extends Node

signal attack_target(target)

const WARRIOR = preload("res://scene/warrior/warrior.tscn")

onready var _rng = RandomNumberGenerator.new()
onready var _terrain = $terrain
onready var _waypoint = $waypoint
onready var _player_holder = $player_holder
onready var _mob_holder = $mob_holder
onready var _network = $network
onready var _server_advertise = $ServerAdvertiser
onready var _control = $control
onready var _camera = $Camera2D

var battle_setting = {
	mode = "HOST",
	ip = "",
	port = 0,
	mobs = []
}

# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.set_target_fps(60)
	
	var s = SaveLoad.new()
	battle_setting = s.load_save(SaveFileName.BATTLE_SETTING_FILENAME)
	if not battle_setting:
		return
	
	if battle_setting.mode == "HOST":
		host()
	elif battle_setting.mode == "JOIN":
		join()
	
	
func host():
	_network.create_server(_network.MAX_PLAYERS,_network.DEFAULT_PORT, { name = "host player" })
	
	var mobs_count = 1#_rng.randf_range(1,2)
	for i in mobs_count:
		battle_setting.mobs.append({
			network_master_id = 1,
			name = "mob-" + str(i),
			data = {
				name = RandomNameGenerator.generate()
			}
		})
		
	for mob in battle_setting.mobs:
		 spawn_mob(mob.network_master_id, mob.name, mob.data, true)
		
	_terrain.create_simplex()
	_terrain.generate_battlefield()
	
	
	
func join():
	_network.connect_to_server(battle_setting.ip, battle_setting.port, { name = "client player" })
	
	for mob in battle_setting.mobs:
		 spawn_mob(mob.network_master_id, mob.name, mob.data, false)
	
	
	
	
	
func _on_control_touch_position(pos):
	_waypoint.show_waypoint(Color.white, pos)
	
func _on_control_disconnect():
	for child in _player_holder.get_children():
		child.set_process(false)
		
	for child in _mob_holder.get_children():
		child.set_process(false)
		
	_network.disconnect_from_server()
	
	
	
func _on_network_player_connected(player_network_unique_id, data):
	var warrior = WARRIOR.instance()
	warrior.name = str(player_network_unique_id)
	warrior.set_network_master(player_network_unique_id)
	warrior.data = data
	warrior.label_color = Color.red
	warrior.connect("on_click", self,"_on_warrior_click")
	warrior.connect("on_ready", self, "_on_warrior_ready")
	warrior.visible = false
	_player_holder.add_child(warrior)
	
	
func _on_warrior_ready(warrior):
	warrior.get_update_from_master()
	warrior.visible = true
	
func _on_warrior_click(warrior):
	_waypoint.show_waypoint(Color.red, warrior.position)
	emit_signal("attack_target", warrior)
	
	
	
func spawn_mob(network_master_id, _name, data, is_master):
	var warrior = WARRIOR.instance()
	warrior.name = _name
	warrior.data = data
	warrior.label_color = Color.gray
	warrior.set_network_master(network_master_id)
	warrior.connect("on_click", self,"_on_warrior_click")
	_mob_holder.add_child(warrior)
	
	if is_master:
		_on_mob_ready(warrior)
		warrior.connect("on_ready", self, "_on_mob_ready")
	
func _on_mob_ready(mob):
	mob.move_to(Vector2(_rng.randf_range(-400,400),_rng.randf_range(-400,400)))
	
	
	
remote func _request_terrain_data(from_id):
	if not get_tree().is_network_server():
		return
		
	var _terrain_data = {
		biom = _terrain.biom,
		simplex_seed = _terrain.simplex_seed,
		size = _terrain.tile_size,
	}
		
	rpc_id(from_id,"_send_terrain_data", _terrain_data)
		
remote func _send_terrain_data(_terrain_data):
	if get_tree().is_network_server():
		return
		
	if _terrain_data.empty():
		return
		
	_terrain.biom = _terrain_data.biom
	_terrain.simplex_seed = _terrain_data.simplex_seed
	_terrain.tile_size = _terrain_data.size
	_terrain.generate_battlefield()
	
	
	
	
	
func _on_network_server_player_connected(player_network_unique_id, data):
	spawn_playable_character(player_network_unique_id, data)
	_server_advertise.setup()
	_server_advertise.serverInfo["name"] = OS.get_name()
	_server_advertise.serverInfo["port"] = _network.DEFAULT_PORT
	_server_advertise.serverInfo["public"] = true
	_server_advertise.serverInfo["mobs"] = battle_setting.mobs
	
	
func _on_network_client_player_connected(player_network_unique_id, data):
	spawn_playable_character(player_network_unique_id, data)
	rpc_id(_network.PLAYER_HOST_ID,"_request_terrain_data",player_network_unique_id)
	
	
func spawn_playable_character(player_network_unique_id, data):
	var warrior = WARRIOR.instance()
	warrior.name = str(player_network_unique_id)
	warrior.set_network_master(player_network_unique_id)
	warrior.data = data
	warrior.label_color = Color.blue
	warrior.camera = _camera.get_path()
	warrior.set_process(false)
	_player_holder.add_child(warrior)
	
	_camera.set_anchor(warrior)
	_control.connect("touch_position", warrior, "move_to")
	connect("attack_target", warrior, "attack_target")
	
	
	
func _on_network_player_disconnected(player_network_unique_id):
	for child in _player_holder.get_children():
		if child.get_network_master() == player_network_unique_id:
			child.set_process(false)
			child.queue_free()
	
func _on_network_server_disconnected():
	for child in _player_holder.get_children():
			child.set_process(false)
			child.queue_free()
		
	for child in _mob_holder.get_children():
			child.set_process(false)
			child.queue_free()
			
	get_tree().change_scene("res://scene/menu/menu.tscn")
	
func _on_network_error(err):
	print(err)
	
	
func _on_network_connection_closed():
	_on_network_server_disconnected()
