extends Node

const WARRIOR = preload("res://scene/warrior/warrior.tscn")
const MOBS = [
	{
		network_master_id = 1,
		name = "mob-1",
		data = {
			name = "bob"
		}
	},
	{
		network_master_id = 1,
		name = "mob-2",
		data = {
			name = "susan"
		}
	}
]

onready var _rng = RandomNumberGenerator.new()
onready var _waypoint = $waypoint
onready var _player_holder = $player_holder
onready var _mob_holder = $mob_holder
onready var _network = $network
onready var _control = $control
onready var _camera = $Camera2D

# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.set_target_fps(60)
	
func _on_control_host():
	_control.show_button(false)
	_network.create_server(_network.MAX_PLAYERS,_network.DEFAULT_PORT, { name = "host player" })
		
	for mob in MOBS:
		 spawn_mob(mob.network_master_id, mob.name, mob.data, true)
	
func _on_control_join():
	_control.show_button(false)
	_network.connect_to_server("192.168.100.62",_network.DEFAULT_PORT, { name = "client player" })
	
	for mob in MOBS:
		 spawn_mob(mob.network_master_id, mob.name, mob.data, false)
	
func _on_network_self_connected(player_network_unique_id):
	var warrior = WARRIOR.instance()
	warrior.name = str(player_network_unique_id)
	warrior.set_network_master(player_network_unique_id)
	warrior.data = _network.self_data.data
	warrior.label_color = Color.blue
	warrior.camera = _camera.get_path()
	_player_holder.add_child(warrior)
	
	_camera.set_anchor(warrior)
	_control.connect("touch_position", warrior, "move_to")
	
func _on_control_touch_position(pos):
	_waypoint.show_waypoint(Color.white, pos)
	
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
	
func _on_network_player_connected(player_network_unique_id, data):
	var warrior = WARRIOR.instance()
	warrior.name = str(player_network_unique_id)
	warrior.set_network_master(player_network_unique_id)
	warrior.data = data
	warrior.label_color = Color.red
	warrior.connect("on_click", self,"_on_warrior_click")
	_player_holder.add_child(warrior)
		
		
func _on_warrior_click(warrior):
	_waypoint.show_waypoint(Color.red, warrior.position)
		
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



