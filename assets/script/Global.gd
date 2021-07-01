extends Node

var player_id = GDUUID.v4()
var player_name = ""
var html_color = ""

var battle_setting = {
	mode = "HOST",
	ip = "",
	port = 0,
	bots = []
}

var network_error = ""
