extends RigidBody2D


onready var rng = RandomNumberGenerator.new()
onready var _sprite = $Sprite
onready var _collision = $CollisionShape2D

var texture_asset = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	_sprite.texture = load(texture_asset)
