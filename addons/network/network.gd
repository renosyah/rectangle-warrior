extends Node

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5
const PLAYER_HOST_ID = 1

var players = {}
var data = {}

signal server_player_connected(player_network_unique_id, data)
signal client_player_connected(player_network_unique_id, data)
signal player_connected(player_network_unique_id)
signal player_connected_data_receive(player_network_unique_id,data)
signal player_connected_data_not_found(player_network_unique_id)
signal player_disconnected(player_network_unique_id)
signal server_disconnected()
signal connection_closed()
signal error(err)

func _ready():
	get_tree().connect('network_peer_connected', self, '_network_peer_connected')
	get_tree().connect('network_peer_disconnected', self, '_on_peer_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
func create_server(_max_player : int = MAX_PLAYERS, _port :int = DEFAULT_PORT, _data : Dictionary = {}):
	data = _data
	players[PLAYER_HOST_ID] = data
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(_port, _max_player)
	if err != OK:
		emit_signal("error",err)
		return
		
	get_tree().set_network_peer(null) 
	get_tree().set_network_peer(peer)
	emit_signal("server_player_connected", PLAYER_HOST_ID, data)
	rpc('_receive_broadcast_player_info', PLAYER_HOST_ID, data)
	
	
func connect_to_server(_ip:String = DEFAULT_IP, _port :int = DEFAULT_PORT, _data: Dictionary = {}):
	data = _data
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(_ip,_port)
	if err != OK:
		emit_signal("error",err)
		return
		
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	get_tree().set_network_peer(null) 
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
	get_tree().set_network_peer(null)
	emit_signal("connection_closed")
	
	
	
# player connect to server
# pov from joined player
func _connected_to_server():
	var local_player_id = get_tree().get_network_unique_id()
	emit_signal("client_player_connected", local_player_id, data)
	rpc_id(PLAYER_HOST_ID,'_send_player_info', local_player_id, data)
	
# server receive data
# from joined player and prepare
# puppet for newly joined player
remote func _send_player_info(player_network_unique_id, _data):
	if not get_tree().is_network_server():
		return
		
	players[player_network_unique_id] = _data
	emit_signal("player_connected", player_network_unique_id)
	emit_signal("player_connected_data_receive", player_network_unique_id, _data)
	
# this will be emit by everybody
# except joined player
func _network_peer_connected(player_network_unique_id):
	if get_tree().is_network_server():
		return
		
	emit_signal("player_connected", player_network_unique_id)
	request_player_info(player_network_unique_id)
	
	
func request_player_info(player_network_unique_id):
	rpc_id(PLAYER_HOST_ID,'_request_player_info', get_tree().get_network_unique_id(), player_network_unique_id)
	
	
# other client request
# data from newly join player
# to server
remote func _request_player_info(from_player_network_unique_id, requested_player_network_unique_id):
	if not get_tree().is_network_server():
		return
	
	var _data = {}
	if players.has(requested_player_network_unique_id):
		_data = players[requested_player_network_unique_id]
	
	rpc_id(from_player_network_unique_id,'_receive_player_info', requested_player_network_unique_id, _data)
	
# other client receive
# data from newly join player
# from server and prepare
# puppet for newly joined player 
remote func _receive_player_info(player_network_unique_id, _data):
	if get_tree().is_network_server():
		return
		
	if _data.empty():
		emit_signal("player_connected_data_not_found", player_network_unique_id)
		return
		
	emit_signal("player_connected_data_receive", player_network_unique_id, _data)
	
	
	
# this will be emit by everybody
# except diconnected player
func _on_peer_disconnected(player_network_unique_id):
	emit_signal("player_disconnected",player_network_unique_id)
	
	if not get_tree().is_network_server():
		return
		
	players.erase(player_network_unique_id)
	
	
	
