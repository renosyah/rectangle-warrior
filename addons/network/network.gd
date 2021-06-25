extends Node

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5
const PLAYER_HOST_ID = 1

var players_data = {}
var data = {}

signal server_player_connected(player_network_unique_id, data)
signal client_player_connected(player_network_unique_id, data)
signal player_connected(player_network_unique_id,data)
signal player_disconnected(player_network_unique_id)
signal server_disconnected()
signal error(err)

func _ready():
	get_tree().connect('network_peer_connected', self, '_on_player_connected')
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
func create_server(_max_player : int = MAX_PLAYERS, _port :int = DEFAULT_PORT, _data : Dictionary = {}):
	players_data[PLAYER_HOST_ID] = _data
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(_port, _max_player)
	if err != OK:
		emit_signal("error",err)
		return
		
	get_tree().set_network_peer(peer)
	emit_signal("server_player_connected", PLAYER_HOST_ID, _data)
	
func connect_to_server(_ip:String = DEFAULT_IP, _port :int = DEFAULT_PORT, _data: Dictionary = {}):
	data = _data
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(_ip,_port)
	if err != OK:
		emit_signal("error",err)
		return
		
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	get_tree().set_network_peer(peer)
	
func _on_server_disconnected():
	for _signal in get_tree().get_signal_connection_list("connected_to_server"):
		get_tree().disconnect("connected_to_server",self, _signal.method)
		
	emit_signal("server_disconnected")
	
# if player want to disconnect
# from server, just call this func
func disconnect_from_server():
	if not is_instance_valid(get_tree().get_network_peer()):
		return
		
	for _signal in get_tree().get_signal_connection_list("connected_to_server"):
		get_tree().disconnect("connected_to_server",self, _signal.method)
		
	get_tree().get_network_peer().close_connection()
	
# player connect to server
# pov from joined player
func _connected_to_server():
	var local_player_id = get_tree().get_network_unique_id()
	emit_signal("client_player_connected", local_player_id, data)
	rpc('_send_player_info', local_player_id, data)
	
	
# newly join player connect to server
# pov from other player already join
func _on_player_connected(connected_player_id):
	if get_tree().is_network_server():
		return
		
	rpc_id(PLAYER_HOST_ID, '_request_player_info', get_tree().get_network_unique_id(), connected_player_id)
	
# server tell other player there is
# new join player connect to server
# pov from server player
remote func _request_player_info(request_from_id, player_network_unique_id):
	if not get_tree().is_network_server():
		return
		
	if not players_data.has(player_network_unique_id):
		return
		
		
	rpc_id(request_from_id, '_send_player_info', player_network_unique_id, players_data[player_network_unique_id])
	
# to spawn new joined player in game
# once connected,this function call for every
# other player join before
# pov from other player already join including server
remote func _send_player_info(player_network_unique_id, _data):
	emit_signal("player_connected", player_network_unique_id, _data)
		
	if not get_tree().is_network_server():
		return
		
	players_data[player_network_unique_id] = _data
	
	
func _on_player_disconnected(player_network_unique_id):
	if not players_data.has(player_network_unique_id):
		return
		
	players_data.erase(player_network_unique_id)
	emit_signal("player_disconnected",player_network_unique_id)
	
	
