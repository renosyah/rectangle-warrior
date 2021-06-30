extends RigidBody2D

onready var rng = RandomNumberGenerator.new()
onready var _sprite = $Sprite
onready var _collision = $CollisionShape2D

var texture_asset = ""

func _ready():
	_show_tree()
	#_collision.scale = Vector2(1.7,1.7)
	
func _show_tree():
	rng.randomize()
	_sprite.texture = load(texture_asset)


func _on_Timer_timeout():
	mode = RigidBody2D.MODE_STATIC
	_collision.scale = Vector2(1,1)
	#_collision.disabled = true
	
