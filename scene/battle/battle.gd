extends Node

const WARRIOR = preload("res://scene/warrior/warrior.tscn")

onready var _rng = RandomNumberGenerator.new()
onready var _player_holder = $player_holder
onready var _mob_holder = $mob_holder
onready var _network = $network
onready var _control = $control
onready var _camera = $Camera2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _on_control_host():
	_control.show_button(false)
	_network.create_server(_network.MAX_PLAYERS,_network.DEFAULT_PORT, { name = "host player" })
		
	for i in 2:
		 spawn_mob(get_tree().get_network_unique_id(), GDUUID.v4(), { name = "mob"}, true)
	
func _on_control_join():
	_control.show_button(false)
	_network.connect_to_server("192.168.100.62",_network.DEFAULT_PORT, { name = "client player" })
	
	
func _on_network_self_connected(player_network_unique_id):
	var warrior = WARRIOR.instance()
	warrior.name = str(player_network_unique_id)
	warrior.set_network_master(player_network_unique_id)
	warrior.data = _network.self_data.data
	warrior.label_color = Color.blue
	warrior.camera = _camera.get_path()
	_player_holder.add_child(warrior)
	
	_control.connect("touch_position", warrior, "move_to")
	
	if get_tree().is_network_server():
		return
		
	rpc_id(_network.PLAYER_HOST_ID, '_request_mob_info', player_network_unique_id)
	
	
func spawn_mob(network_master_id, _name, data, is_master):
	var warrior = WARRIOR.instance()
	warrior.name = _name
	warrior.data = data
	warrior.label_color = Color.gray
	warrior.set_network_master(network_master_id)
	_mob_holder.add_child(warrior)
	
	if is_master:
		_on_mob_ready(warrior)
		warrior.connect("on_ready", self, "_on_mob_ready")
	
func _on_mob_ready(mob):
	mob.move_to(Vector2(_rng.randf_range(-1400,1400),_rng.randf_range(-1400,1400)))
	
remote func _request_mob_info(request_from_id):
	if not get_tree().is_network_server():
		return
		
	var mobs = []
	for child in _mob_holder.get_children():
		mobs.append({
			network_master_id = child.get_network_master(),
			name = child.name,
			data = child.data
		})
			
	rpc_id(request_from_id, '_send_mob_info', mobs)
		
remote func _send_mob_info(mobs):
	if get_tree().is_network_server():
		return
		
	if mobs.empty():
		return
		
	for child in _mob_holder.get_children():
		_mob_holder.remove_child(child)
		
	for m in mobs:
		spawn_mob(m.network_master_id, m.name, m.data, false)
		
func _on_network_player_connected(player_network_unique_id, data):
	var warrior = WARRIOR.instance()
	warrior.name = str(player_network_unique_id)
	warrior.set_network_master(player_network_unique_id)
	warrior.data = data
	warrior.label_color = Color.red
	_player_holder.add_child(warrior)
		
		
func _on_network_player_disconnected(_player_network_unique_id):
	for child in _player_holder.get_children():
		if child.get_network_master() == _player_network_unique_id:
			child.set_process(false)
			child.queue_free()
			
	for child in _mob_holder.get_children():
		if child.get_network_master() == _player_network_unique_id:
			child.set_process(false)
			child.queue_free()
			
			
func _on_network_server_disconnected():
	for child in _player_holder.get_children():
			child.set_process(false)
			child.queue_free()
			
	for child in _mob_holder.get_children():
			child.set_process(false)
			child.queue_free()
			
	_control.show_button(true)
		
		
func _on_network_error(err):
	print(err)
	
func _on_control_disconnect():
	for child in _player_holder.get_children():
		child.set_process(false)

	for child in _mob_holder.get_children():
		child.set_process(false)
		
	_network.disconnect_from_server()
	_on_network_server_disconnected()
