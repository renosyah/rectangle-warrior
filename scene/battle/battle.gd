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
onready var _loading_time = $loading_timer
onready var _loading = $loading
onready var _deadscreen = $deadscreen

var scoredata = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	_rng.randomize()
	if Global.battle_setting.mode == "HOST":
		host()
	elif Global.battle_setting.mode == "JOIN":
		join()
		 
	_loading.show_loading(true)
	_control.show_control(false)
	_deadscreen.show_deadscreen(false)
	_control.set_minimap_camera(_camera)
	
	_control.connect("on_menu_press", self ,"_on_menu_press")
	
func host():
	var _data = {
		id = GDUUID.v4(),
		name = Global.player_name, 
		html_color = Color(_rng.randf(),_rng.randf(),_rng.randf(),1.0).to_html()
	}
	_network.create_server(_network.MAX_PLAYERS,_network.DEFAULT_PORT, _data)
	Global.battle_setting.mobs.clear()
	
	var mobs_count = 10 #_rng.randf_range(1,5)
	for i in mobs_count:
		Global.battle_setting.mobs.append({
			id = GDUUID.v4(),
			network_master_id = 1,
			name = "mob-" + str(i),
			data = {
				id = GDUUID.v4(),
				name = RandomNameGenerator.generate() + " (Bot)",
				html_color = Color(_rng.randf(),_rng.randf(),_rng.randf(),1.0).to_html()
			}
		})
		
	for mob in Global.battle_setting.mobs:
		 spawn_mob(mob.network_master_id, mob.name, mob.data, true)
	
	_terrain.biom = Biom.BIOMS[_rng.randf_range(0,Biom.BIOMS.size())].id
	_terrain.create_simplex()
	_terrain.generate_battlefield()
	
func join():
	var _data = { 
		id = GDUUID.v4(),
		name = Global.player_name, 
		html_color = Color(_rng.randf(),_rng.randf(),_rng.randf(),1.0).to_html()
	}
	_network.connect_to_server(Global.battle_setting.ip, Global.battle_setting.port, _data)
	
	for mob in Global.battle_setting.mobs:
		 spawn_mob(mob.network_master_id, mob.name, mob.data, false)
	
	
	
	
# user interaction section
func _on_control_touch_position(pos):
	_waypoint.show_waypoint(Color.white, pos)
	
func _on_control_disconnect():
	for child in _player_holder.get_children():
		child.set_process(false)
		
	for child in _mob_holder.get_children():
		child.set_process(false)
		
	_network.disconnect_from_server()
	
func _on_control_autoplay_pressed(_autoplay):
	for child in _player_holder.get_children():
		if child.get_network_master() == get_tree().get_network_unique_id():
			child.make_ready()
			return
			
			
func _on_menu_press():
	if get_tree().is_network_server():
		_control.show_scoreboard(scoredata)
		return
		
	rpc_id(_network.PLAYER_HOST_ID, "_request_score_data", get_tree().get_network_unique_id())
	
	
	
	
	
# score data section
func update_score(for_player : Dictionary, add_kill_count:int = 1):
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
	_player_holder.add_child(_puppet_warrior)
	
func _on_network_player_connected_data_not_found(player_network_unique_id):
	yield(get_tree().create_timer(1.0), "timeout")
	_network.request_player_info(player_network_unique_id)
	
func _on_network_player_connected_data_receive(player_network_unique_id, data):
	var _puppet_warrior = get_node(NodePath(str(_player_holder.get_path()) + "/" + str(player_network_unique_id))) 
	if not is_instance_valid(_puppet_warrior):
		return
		
	_puppet_warrior = get_node(NodePath(str(_player_holder.get_path()) + "/" + str(player_network_unique_id))) 
	_puppet_warrior.data = data
	_puppet_warrior.visible = true
	_puppet_warrior.label_color = Color.red
	_puppet_warrior.connect("on_click", self,"_on_warrior_click")
	_puppet_warrior.make_ready()
	
	_control.add_minimap_object(_puppet_warrior)
	
func _on_warrior_click(warrior):
	_waypoint.show_waypoint(Color.red, warrior.position)
	emit_signal("attack_target", warrior)
	
	
	
	
	
	
	
	
# mob section
func spawn_mob(network_master_id, _name, data, is_host_master):
	var warrior = WARRIOR.instance()
	warrior.name = _name
	warrior.data = data
	warrior.label_color = Color.gray
	warrior.position = _get_random_position()
	warrior.set_network_master(network_master_id)
	warrior.connect("on_click", self,"_on_mob_click")
	_mob_holder.add_child(warrior)
	
	_control.add_minimap_object(warrior)
	
	if is_host_master:
		_on_mob_ready(warrior)
		warrior.connect("on_ready", self, "_on_mob_ready")
		warrior.connect("on_attacked", self, "_on_mob_attacked")
		warrior.connect("on_dead", self, "_on_mob_dead")
	
func _on_mob_ready(mob):
	mob.move_to(Vector2(_rng.randf_range(-800,800),_rng.randf_range(-800,800)))
	if randf() < 0.30:
		var _targets = _player_holder.get_children() + _mob_holder.get_children()
		var _target = _targets[rand_range(0,_targets.size())]
		if _target == mob:
			mob.make_ready()
			return
			
		mob.attack_target(_target)
		
func _on_mob_click(mob):
	_waypoint.show_waypoint(Color.red, mob.position)
	emit_signal("attack_target", mob)
	
func _on_mob_attacked(mob,_node_name):
	var _targets = _player_holder.get_children() + _mob_holder.get_children()
	for _target in _targets:
		if _target.name == _node_name:
			mob.attack_target(_target)
			return
		
func _on_mob_dead(mob, killed_by):
	mob.position = _get_random_position()
	mob.set_spawn_time()
	
	update_score(killed_by)
	
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
	
	
	
	
# player connection as host/client section
func _on_network_server_player_connected(player_network_unique_id, data):
	spawn_playable_character(player_network_unique_id, data)
	_server_advertise.setup()
	_server_advertise.serverInfo["name"] = Global.player_name + " on " + OS.get_name()
	_server_advertise.serverInfo["port"] = _network.DEFAULT_PORT
	_server_advertise.serverInfo["public"] = true
	_server_advertise.serverInfo["mobs"] = Global.battle_setting.mobs
	
	
func _on_network_client_player_connected(player_network_unique_id, data):
	spawn_playable_character(player_network_unique_id, data)
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
	warrior.connect("on_attacked", self, "_on_player_attacked")
	warrior.connect("on_dead", self, "_on_player_dead")
	_player_holder.add_child(warrior)
	warrior.highlight()
	
	_camera.set_anchor(warrior)
	_control.connect("touch_position", warrior, "move_to")
	connect("attack_target", warrior, "attack_target")
	
	_control.add_minimap_object(warrior)
	
	_loading_time.wait_time = 1.0
	_loading_time.start()
	
	
func _on_player_ready(warrior):
	_control.show_control(true)
	_deadscreen.show_deadscreen(false)
	
	if _control.autoplay:
		autoplay(warrior)
		
func autoplay(warrior):
	var _targets = _player_holder.get_children() + _mob_holder.get_children()
	var _target = _targets[rand_range(0,_targets.size())]
	if _target == warrior:
		warrior.make_ready()
		return
		
	warrior.attack_target(_target)
	
func _on_player_attacked(warrior,_node_name):
	var _targets = _player_holder.get_children() + _mob_holder.get_children()
	for _target in _targets:
		if _target.name == _node_name:
			warrior.attack_target(_target)
			return
			
func _on_player_dead(warrior, killed_by):
	warrior.position = Vector2(_rng.randf_range(-400,400),_rng.randf_range(-400,400))
	warrior.set_spawn_time()
	_control.show_control(false)
	_deadscreen.show_deadscreen(true, killed_by.name)
	
	if get_tree().is_network_server():
		update_score(killed_by)
	
	
	
# network event section
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
	
func _on_loading_timer_timeout():
	_loading.show_loading(false)
	_control.show_control(true)







