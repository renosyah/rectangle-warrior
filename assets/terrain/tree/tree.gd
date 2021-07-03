extends RigidBody2D

onready var rng = RandomNumberGenerator.new()
onready var _sprite = $Sprite
onready var _collision = $CollisionShape2D

var texture_asset = ""

func _ready():
	rng.randomize()
	_sprite.texture = load(texture_asset)
