class_name RestockPoint
extends StaticBody3D

var fruit: String = "banana"
var session: GameSessionManager

func _ready() -> void:
	collision_layer = 3
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 1.45, 1.1)
	collider.shape = box
	collider.position.y = 0.72
	add_child(collider)

func interaction_prompt() -> String:
	return "[E] Repor 6 %s • %s" % [FruitCatalog.ITEMS[fruit]["plural"], FruitCatalog.money(FruitCatalog.ITEMS[fruit]["cost"])]

func interact() -> void:
	session.restock(fruit)
