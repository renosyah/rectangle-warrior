extends Node

const ITEM = preload("res://scene/menu/find_server/item/item.tscn")

signal on_close()
signal on_join(info)

onready var _item_container = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer
onready var _server_listener = $ServerListener

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func start_finding():
	_server_listener.setup()
	
func stop_finding():
	_server_listener.stop()
	
func _on_close_button_pressed():
	emit_signal("on_close")

func _join(info):
	emit_signal("on_join", info)
	
func _on_ServerListener_new_server(serverInfo):
	var item = ITEM.instance()
	item.info = serverInfo.duplicate()
	item.connect("join", self, "_join")
	_item_container.add_child(item)
	
	
func _on_ServerListener_remove_server(serverIp):
	for child in _item_container.get_children():
		if child.info["ip"] == serverIp:
			_item_container.remove_child(child)
			return
