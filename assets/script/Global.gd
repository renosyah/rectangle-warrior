extends Node

const NETWORK_TICKRATE = 0.08

var player = {
	id = GDUUID.v4(),
	name = "",
	html_color = ""
}

var battle_setting = {
	mode = "HOST",
	ip = "",
	port = 0,
	bots = []
}

var network_error = ""
