extends RigidBody2D


onready var rng = RandomNumberGenerator.new()
onready var _sprite = $Sprite
onready var _collision = $CollisionShape2D

var texture_asset = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	_show_bush() # Replace with function body.


func _show_bush():
	rng.randomize()
	_sprite.texture = load(texture_asset)


func _on_Timer_timeout():
	mode = RigidBody2D.MODE_STATIC
	_collision.disabled = true
