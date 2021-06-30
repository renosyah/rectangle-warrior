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
		_bots.append({
			id = GDUUID.v4(),
			network_master_id = 1,
			name = "mob-" + str(i),
			data = {
				id = GDUUID.v4(),
				name = RandomNameGenerator.generate() + " (Bot)",
				html_color = Color(_rng.randf(),_rng.randf(),_rng.randf(),1.0).to_html()
			}
		})

func _on_HSlider_value_changed(value):
	_bot_label.text = "Bots (%d)" % value
	generate_bots(value)
	
	
func _on_close_button_pressed():
	emit_signal("close")
	
	
func _on_create_button_pressed():
	emit_signal("create", _bots)
