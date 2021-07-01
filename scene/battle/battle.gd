extends Node

signal attack_target(target)


const WARRIOR = preload("res://scene/warrior/warrior.tscn")

onready var _rng = RandomNumberGenerator.new()
onready var _terrain = $terrain
onready var _waypoint = $waypoint
onready var _warrior_holder = $warrior_holder
onready var _bush_holder = $bush_holder
onready var _tree_holder = $tree_holder
onready var _network = $network
onready var _server_advertise = $ServerAdvertiser
onready var _loading_time = $loading_timer
onready var _camera = $Camera2D
onready var _control = $control

var scoredata = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	_rng.randomize()
	if Global.battle_setting.mode == "HOST":
		host()
	elif Global.battle_setting.mode == "JOIN":
		join()
		 
	
	_control.show_control(false)
	_control.set_minimap_camera(_camera)
	
	
func host():
	var _data = {
		id = Global.player_id,
		name = Global.player_name, 
		html_color = Global.html_color
	}
	_network.create_server(_network.MAX_PLAYERS,_network.DEFAULT_PORT, _data)
	update_score(_data, 0)
	
	for mob in Global.battle_setting.bots:
		update_score(mob.data, 0)
		spawn_mob(mob.network_master_id, mob.name, mob.data, true)
	
	_terrain.biom = Biom.BIOMS[_rng.randf_range(0,Biom.BIOMS.size())].id
	_terrain.create_simplex()
	_terrain.setup_enviroment()
	_terrain.generate_battlefield()
	
	for enviroment in _terrain.enviroments:
		if enviroment.type == "bush":
			_terrain.spawn_bush(_bush_holder,enviroment.texture_asset,enviroment.position)
		elif enviroment.type == "tree":
			_terrain.spawn_tree(_tree_holder,enviroment.texture_asset,enviroment.position)
		
	
	
func join():
	var _data = { 
		id = Global.player_id,
		name = Global.player_name, 
		html_color = Global.html_color
	}
	_network.connect_to_server(Global.battle_setting.ip, Global.battle_setting.port, _data)
	
	for mob in Global.battle_setting.bots:
		spawn_mob(mob.network_master_id, mob.name, mob.data, false)
	
	
	
	
# user interaction section
func _on_control_touch_position(pos):
	_waypoint.show_waypoint(Color.white, pos)
	
func _on_control_disconnect():
	for child in _warrior_holder.get_children():
		child.set_process(false)
		
	_network.disconnect_from_server()
	
func _on_control_autoplay_pressed(_autoplay):
	for child in _warrior_holder.get_children():
		if child.get_network_master() == get_tree().get_network_unique_id():
			child.make_ready()
			return
			
			
func _on_control_on_menu_press():
	if get_tree().is_network_server():
		_control.show_scoreboard(scoredata)
		return
		
	rpc_id(_network.PLAYER_HOST_ID, "_request_score_data", get_tree().get_network_unique_id())
	
	
	
	
	
# camera callback handler section
func _on_Camera2D_on_camera_moving(_pos, _zoom):
	var _transparacy =  _zoom.x

	if _transparacy > 0.6:
		_transparacy = 1.0
	elif _transparacy < 0.0:
		_transparacy = 0.4
		
	_tree_holder.modulate.a = _transparacy
	
	
	
	
	
	
	
	
	
# score data section
func update_score(for_player : Dictionary, add_kill_count:int = 0):
	if not scoredata.has(for_player.id):
		scoredata[for_player.id] = {
			name = for_player.name,
			kill_count = add_kill_count
		}
		return
		
	scoredata[for_player.id].kill_count += add_kill_count
	
# client request score data section
remote func _request_score_data(from_id):
	if not get_tree().is_network_server():
		return
		
	rpc_id(from_id,"_send_score_data", scoredata)
	
remote func _send_score_data(_score_data):
	if get_tree().is_network_server():
		return
		
	if _score_data.empty():
		return
		
	_control.show_scoreboard(_score_data)
	
	
	
	
# player puppet section
func _on_network_player_connected(player_network_unique_id):
	var _puppet_warrior = WARRIOR.instance()
	_puppet_warrior.name = str(player_network_unique_id)
	_puppet_warrior.visible = false
	_puppet_warrior.set_network_master(player_network_unique_id)
	_warrior_holder.add_child(_puppet_warrior)
	
func _on_network_player_connected_data_not_found(player_network_unique_id):
	yield(get_tree().create_timer(1.0), "timeout")
	_network.request_player_info(player_network_unique_id)
	
func _on_network_player_connected_data_receive(player_network_unique_id, data):
	var _puppet_warrior = get_node(NodePath(str(_warrior_holder.get_path()) + "/" + str(player_network_unique_id))) 
	if not is_instance_valid(_puppet_warrior):
		return
		
	if get_tree().is_network_server():
		update_score(data, 0)
		
	_puppet_warrior = get_node(NodePath(str(_warrior_holder.get_path()) + "/" + str(player_network_unique_id))) 
	_puppet_warrior.data = data
	_puppet_warrior.visible = true
	_puppet_warrior.label_color = Color.red
	_puppet_warrior.connect("on_click", self,"_on_puppet_warrior_click")
	_puppet_warrior.connect("on_dead", self, "_on_puppet_warrior_dead")
	_puppet_warrior.make_ready()
	
	_control.add_minimap_object(_puppet_warrior)
	
func _on_puppet_warrior_click(warrior):
	_waypoint.show_waypoint(Color.red, warrior.position)
	emit_signal("attack_target", warrior)
	
func _on_puppet_warrior_dead(warrior, killed_by):
	if get_tree().is_network_server():
		update_score(killed_by, 1)
	
	
	
	
# mob section
func spawn_mob(network_master_id, _name, data, is_host_master):
	var warrior = WARRIOR.instance()
	warrior.name = _name
	warrior.data = data
	warrior.label_color = Color.gray
	warrior.position = _get_random_position()
	warrior.set_network_master(network_master_id)
	warrior.connect("on_click", self,"_on_mob_click")
	_warrior_holder.add_child(warrior)
	
	_control.add_minimap_object(warrior)
	
	if is_host_master:
		_on_mob_ready(warrior)
		warrior.connect("on_ready", self, "_on_mob_ready")
		warrior.connect("on_attacked", self, "_on_mob_attacked")
		warrior.connect("on_dead", self, "_on_mob_dead")
	
func _on_mob_ready(mob):
	mob.move_to(Vector2(_rng.randf_range(-800,800),_rng.randf_range(-800,800)))
	if randf() < 0.30:
		var _targets = _warrior_holder.get_children()
		var _target = _targets[rand_range(0,_targets.size())]
		if _target == mob:
			mob.make_ready()
			return
			
		mob.attack_target(_target)
		
func _on_mob_click(mob):
	_waypoint.show_waypoint(Color.red, mob.position)
	emit_signal("attack_target", mob)
	
func _on_mob_attacked(mob,_node_name):
	var _targets = _warrior_holder.get_children()
	for _target in _targets:
		if _target.name == _node_name:
			mob.attack_target(_target)
			return
		
func _on_mob_dead(mob, killed_by):
	mob.position = _get_random_position()
	mob.set_spawn_time()
	
	update_score(killed_by, 1)
	
func _get_random_position() -> Vector2:
	return Vector2(_rng.randf_range(-800,800),_rng.randf_range(-800,800))
	
	
	
# client request terrain data section
remote func _request_terrain_data(from_id):
	if not get_tree().is_network_server():
		return
		
	var _terrain_data = {
		biom = _terrain.biom,
		simplex_seed = _terrain.simplex_seed,
		size = _terrain.tile_size,
		enviroments = _terrain.enviroments,
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
	_terrain.enviroments = _terrain_data.enviroments
	_terrain.generate_battlefield()
	
	for enviroment in _terrain_data.enviroments:
		if enviroment.type == "bush":
			_terrain.spawn_bush(_bush_holder,enviroment.texture_asset,enviroment.position)
		elif enviroment.type == "tree":
			_terrain.spawn_tree(_tree_holder,enviroment.texture_asset,enviroment.position)
		
	
# player connection as host/client section
func _on_network_server_player_connected(player_network_unique_id, data):
	spawn_playable_character(player_network_unique_id, data)
	_control.set_interface_color(Color(data.html_color))
	_server_advertise.setup()
	_server_advertise.serverInfo["name"] = Global.player_name + " on " + OS.get_name()
	_server_advertise.serverInfo["port"] = _network.DEFAULT_PORT
	_server_advertise.serverInfo["public"] = true
	_server_advertise.serverInfo["bots"] = Global.battle_setting.bots
	
	
func _on_network_client_player_connected(player_network_unique_id, data):
	spawn_playable_character(player_network_unique_id, data)
	_control.set_interface_color(Color(data.html_color))
	rpc_id(_network.PLAYER_HOST_ID,"_request_terrain_data",player_network_unique_id)
	
	
	
	
	
	
# player playable character section
func spawn_playable_character(player_network_unique_id, data):
	var warrior = WARRIOR.instance()
	warrior.name = str(player_network_unique_id)
	warrior.set_network_master(player_network_unique_id)
	warrior.data = data
	warrior.label_color = Color.blue
	warrior.camera = _camera.get_path()
	warrior.position = _get_random_position()
	warrior.set_process(false)
	warrior.connect("on_ready", self, "_on_player_ready")
	warrior.connect("on_respawn", self, "_on_player_respawn")
	warrior.connect("on_attacked", self, "_on_player_attacked")
	warrior.connect("on_dead", self, "_on_player_dead")
	_warrior_holder.add_child(warrior)
	warrior.highlight()
	
	_camera.set_anchor(warrior)
	_control.connect("touch_position", warrior, "move_to")
	connect("attack_target", warrior, "attack_target")
	
	_control.add_minimap_object(warrior)
	
	_loading_time.wait_time = 1.0
	_loading_time.start()
	
func _on_player_respawn(_warrior):
	_control.show_deadscreen(false)
	
func _on_player_ready(warrior):
	if _control.autoplay:
		autoplay(warrior)
	
func autoplay(warrior):
	var _targets = _warrior_holder.get_children()
	var _target = _targets[rand_range(0,_targets.size())]
	if _target == warrior:
		warrior.make_ready()
		return
		
	warrior.attack_target(_target)
	
func _on_player_attacked(warrior,_node_name):
	var _targets = _warrior_holder.get_children()
	for _target in _targets:
		if _target.name == _node_name:
			warrior.attack_target(_target)
			return
			
func _on_player_dead(warrior, killed_by):
	warrior.position = Vector2(_rng.randf_range(-400,400),_rng.randf_range(-400,400))
	warrior.set_spawn_time()
	_control.show_deadscreen(true, killed_by.name)
	
	if get_tree().is_network_server():
		update_score(killed_by, 1)
	
	
	
# network event section
func to_main_menu():
	for child in _warrior_holder.get_children():
		child.set_process(false)
		child.queue_free()
		
	get_tree().change_scene("res://scene/menu/menu.tscn")
	
	
func _on_network_player_disconnected(player_network_unique_id):
	for child in _warrior_holder.get_children():
		if child.get_network_master() == player_network_unique_id:
			child.set_process(false)
			child.queue_free()
	
func _on_network_server_disconnected():
	Global.network_error = "Disconnected from server!"
	to_main_menu()
	
func _on_network_error(err):
	Global.network_error = str(err)
	
func _on_network_connection_closed():
	to_main_menu()
	
func _on_loading_timer_timeout():
	_control.show_loading(false)
	_control.show_control(true)





