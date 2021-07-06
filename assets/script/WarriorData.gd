extends Node
class_name WarriorData

const TYPE_UNKNOWN_INFANTRY = "TYPE_UNKNOWN_INFANTRY"
const TYPE_SWORD_INFANTRY = "TYPE_SWORD_INFANTRY"
const TYPE_SPEAR_INFANTRY = "TYPE_SPEAR_INFANTRY"
const TYPE_RANGE_INFANTRY = "TYPE_RANGE_INFANTRY"

static func getDefaultData() -> Dictionary:
	var _data = {
		
		# stats
		type = TYPE_SWORD_INFANTRY,
		move_speed = 90.0,
		range_attack = 80.0,
		max_armor = 5.0,
		armor = 5.0,
		max_hitpoint = 10.0,
		hitpoint = 10.0,
		melee_damage = 1.0,
		range_damage = 1.0,
		attack_accuracy = 0.5,
		
		# attribute
		owner_id = "",
		name = "warrior",
		html_color = Color.white.to_html(),
		
		# cosmetic
		heml_sprite = "res://assets/gear/helm/helm.png",
		armor_sprite = "res://assets/gear/armor/armor.png",
		uniform_sprite = "res://assets/gear/uniform/uniform.png",
			
		# weapon
		weapon = {
			sprite = "res://assets/gear/weapon/two_handed_sword.png",
			idle_animation = ["nothing"],
			attack_animation = ["swing"],
		}
	}
	return _data.duplicate(true)
