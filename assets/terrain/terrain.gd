extends TileMap

onready var rng = RandomNumberGenerator.new()

var biom = Biom.GRASS_LAND
var tile_size = Vector2(100.0,100.0)
var simplex_seed = 0.0
var enviroments = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func create_simplex():
	rng.randomize()
	simplex_seed = rng.randi()
	
func generate_battlefield():
	var simplex = OpenSimplexNoise.new()
	simplex.seed = simplex_seed
	
	simplex.octaves = 4
	simplex.period = 15
	simplex.lacunarity = 1.5
	simplex.persistence = 0.75
	
	for x in tile_size.x:
		for y in tile_size.y:
			var pos = Vector2(x - tile_size.x / 2,y - tile_size.y / 2)
			set_cellv(pos,_get_tile_index(biom, simplex.get_noise_2d(float(x),float(y))))
			
	for x in [0, tile_size.x - 1]:
		for y in range(tile_size.y):
			set_cellv(Vector2(x - tile_size.x / 2,y - tile_size.y / 2), Biom.TILE_ID.wall)
	for x in range(1, tile_size.x - 1):
		for y in [0, tile_size.y - 1]:
			set_cellv(Vector2(x - tile_size.x / 2,y - tile_size.y / 2), Biom.TILE_ID.wall)
	
	update_bitmask_region()
	
	
func _get_tile_index(_biom, _noice_sample):
	if _biom == Biom.GRASS_LAND:
			if _noice_sample < 0.0:
				return Biom.TILE_ID.grass
			elif _noice_sample > 1.0 and _noice_sample < 0.2:
				return Biom.TILE_ID.sand
			elif _noice_sample > 0.2 and _noice_sample < 0.3:
				return Biom.TILE_ID.grass
			elif _noice_sample > 0.3 and _noice_sample < 0.6:
				return Biom.TILE_ID.mud
				
	elif _biom == Biom.WET_LAND:
			if _noice_sample < 0.0:
				return Biom.TILE_ID.water
			elif _noice_sample > 1.0 and _noice_sample < 0.2:
				return Biom.TILE_ID.grass
			elif _noice_sample > 0.2 and _noice_sample < 0.3:
				return Biom.TILE_ID.sand
			elif _noice_sample > 0.3 and _noice_sample < 0.6:
				return Biom.TILE_ID.mud
				
	elif _biom == Biom.MUD_LAND:
			if _noice_sample < 0.0:
				return Biom.TILE_ID.mud
			elif _noice_sample > 1.0 and _noice_sample < 0.2:
				return Biom.TILE_ID.grass
			elif _noice_sample > 0.2 and _noice_sample < 0.3:
				return Biom.TILE_ID.sand
			elif _noice_sample > 0.3 and _noice_sample < 0.6:
				return Biom.TILE_ID.grass

	elif _biom == Biom.URBAN_LAND:
			if _noice_sample < 0.0:
				return Biom.TILE_ID.grass
			elif _noice_sample > 1.0 and _noice_sample < 0.2:
				return Biom.TILE_ID.grass
			elif _noice_sample > 0.2 and _noice_sample < 0.3:
				return Biom.TILE_ID.sand
			elif _noice_sample > 0.3 and _noice_sample < 0.6:
				return Biom.TILE_ID.dirt
				
	elif _biom == Biom.SAND_LAND:
			if _noice_sample < 0.0:
				return Biom.TILE_ID.sand
			elif _noice_sample > 1.0 and _noice_sample < 0.2:
				return Biom.TILE_ID.grass
			elif _noice_sample > 0.2 and _noice_sample < 0.3:
				return Biom.TILE_ID.sand
			elif _noice_sample > 0.3 and _noice_sample < 0.6:
				return Biom.TILE_ID.sand
				
	return Biom.TILE_ID.grass

func spawn_tree(parent,texture_asset, pos):
	var tree = preload("res://assets/terrain/tree/tree.tscn").instance()
	tree.position = pos
	tree.texture_asset = texture_asset
	parent.add_child(tree)
	
func spawn_bush(parent,texture_asset, pos):
	var tree = preload("res://assets/terrain/bush/bush.tscn").instance()
	tree.position = pos
	tree.texture_asset = texture_asset
	parent.add_child(tree)


const TREE_SPRITE_PATH = [
	"res://assets/terrain/tree/tree1.png",
	"res://assets/terrain/tree/tree2.png",
	"res://assets/terrain/tree/tree3.png",
	"res://assets/terrain/tree/tree4.png",
	"res://assets/terrain/tree/tree5.png"
]

const BUSH_SPRITE_PATH = [
	"res://assets/terrain/bush/bush1.png",
	"res://assets/terrain/bush/bush2.png",
	"res://assets/terrain/bush/bush3.png",
	"res://assets/terrain/bush/bush4.png",
]


func setup_enviroment():
	enviroments.clear()
	for _x in range(-10,10):
		for _y in range(-10,10):
			rng.randomize()
			if rng.randf() < 0.11:
				var x = _x *150
				var y = _y *150
				enviroments.append({
					type = "bush",
					position = Vector2(x,y),
					texture_asset = BUSH_SPRITE_PATH[rng.randf_range(0,BUSH_SPRITE_PATH.size())]
				})
				
	for _x in range(-10,10):
		for _y in range(-10,10):
			rng.randomize()
			if rng.randf() < 0.15:
				var x = _x *150
				var y = _y *150
				enviroments.append({
					type = "tree",
					position = Vector2(x,y),
					texture_asset = TREE_SPRITE_PATH[rng.randf_range(0,TREE_SPRITE_PATH.size())]
				})
				
	



