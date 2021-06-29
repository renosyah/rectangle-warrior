extends HBoxContainer


onready var _warrior_name = $warrior_name
onready var _kill_count = $kill_count
var data = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	_warrior_name.text = data.name
	_kill_count.text = str(data.kill_count)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
