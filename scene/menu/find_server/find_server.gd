extends Node

const ITEM = preload("res://scene/menu/find_server/item/item.tscn")

signal on_close()
signal on_join(info)
signal on_create()

onready var _item_container = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer
onready var _server_listener = $ServerListener
onready var _find_server_label = $PanelContainer/VBoxContainer/Label
onready var _server_list_scroll = $PanelContainer/VBoxContainer/ScrollContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func start_finding():
	_find_server_label.visible = true
	_server_list_scroll.visible = false
	_server_listener.setup()
	
func stop_finding():
	_find_server_label.visible = false
	_server_list_scroll.visible = true
	_server_listener.stop()
	
func _on_close_button_pressed():
	stop_finding()
	emit_signal("on_close")

func _join(info):
	stop_finding()
	emit_signal("on_join", info)
	
func _on_ServerListener_new_server(serverInfo):
	_find_server_label.visible = false
	_server_list_scroll.visible = true
	var item = ITEM.instance()
	item.info = serverInfo.duplicate()
	item.connect("join", self, "_join")
	_item_container.add_child(item)
	
	
func _on_ServerListener_remove_server(serverIp):
	_find_server_label.visible = _item_container.get_children().empty()
	_server_list_scroll.visible = not _item_container.get_children().empty()
	for child in _item_container.get_children():
		if child.info["ip"] == serverIp:
			_item_container.remove_child(child)
			return
			
func _on_host_button_pressed():
	emit_signal("on_create")
	
	
	
	
