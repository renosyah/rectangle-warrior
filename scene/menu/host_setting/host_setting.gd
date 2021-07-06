extends PanelContainer

signal create(_bots)
signal close

onready var _rng = RandomNumberGenerator.new()
onready var _bot_label = $VBoxContainer/HBoxContainer/VBoxContainer/Label

var _bots = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_rng.randomize()
	generate_bots(1)

func generate_bots(_count):
	_bots.clear()
	for i in _count:
		var _id = GDUUID.v4()
		var _data = WarriorData.getDefaultData()
		_data.owner_id = _id
		_data.name = RandomNameGenerator.generate() + " (Bot)"
		_data.html_color = Color(_rng.randf(),_rng.randf(),_rng.randf(),1.0).to_html()
		
		_bots.append({
			id = _id,
			network_master_id = 1,
			name = "mob-" + str(i),
			data = _data
		})

func _on_HSlider_value_changed(value):
	_bot_label.text = "Bots (%d)" % value
	generate_bots(value)
	
	
func _on_close_button_pressed():
	emit_signal("close")
	
	
func _on_create_button_pressed():
	emit_signal("create", _bots)
