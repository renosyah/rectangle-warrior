extends Control

signal on_yes
signal on_no

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_yes_pressed():
	emit_signal("on_yes")


func _on_no_pressed():
	emit_signal("on_no")
