class_name CustomerController
extends CharacterBody3D

signal departed(customer: CustomerController)
enum State { ARRIVING, WAITING, LEAVING }
var state: State = State.ARRIVING
var session: GameSessionManager
var fruit: String = "banana"
var quantity: int = 1
var slot: int = 0
var destination: Vector3
var patience: float = 30.0
var max_patience: float = 30.0
var visual: Node3D
var order_label: Label3D
var age: float = 0.0
var exit_stage: int = 0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.9
	collider.shape = shape
	collider.position.y = 0.95
	add_child(collider)
	var shirts: Array[Color] = [Color("e46b58"), Color("4d9cad"), Color("9c78b1"), Color("ecbd54"), Color("5b9b73")]
	var skins: Array[Color] = [Color("b98159"), Color("e1b18a"), Color("83563e"), Color("c89570")]
	visual = MarketArt.humanoid(self, shirts[randi() % shirts.size()], skins[randi() % skins.size()])
	if randi() % 3 == 0:
		MarketArt.cylinder(visual, Vector3(0, 1.98, 0), 0.35, 0.08, Color("e8ce91"))
		MarketArt.cylinder(visual, Vector3(0, 2.06, 0), 0.23, 0.17, Color("d8b879"))
	order_label = MarketArt.label(self, "Chegando...", Vector3(0, 2.55, 0), 37, Color("fff0c8"))
	order_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	order_label.pixel_size = 0.0045
	order_label.no_depth_test = false
	order_label.outline_size = 10
	destination = Vector3((slot - 1) * 2.0, 0, -1.65)
	_update_label()

func _physics_process(delta: float) -> void:
	if not session.active:
		return
	age += delta
	if state == State.WAITING:
		patience = maxf(0.0, patience - delta)
		_update_label()
		if patience <= 0:
			session.record_missed()
			leave(false)
		return
	var offset := destination - position
	offset.y = 0
	if offset.length() < 0.12:
		if state == State.ARRIVING:
			state = State.WAITING
			visual.rotation.y = 0
			visual.get_node("LegL").rotation.x = 0
			visual.get_node("LegR").rotation.x = 0
			_update_label()
		elif exit_stage == 0:
			exit_stage = 1
			destination = Vector3(4.8, 0, -29)
		else:
			departed.emit(self)
			queue_free()
		return
	var direction := offset.normalized()
	position += direction * minf(offset.length(), 2.2 * delta)
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), delta * 10)
	visual.get_node("LegL").rotation.x = sin(age * 10) * 0.32
	visual.get_node("LegR").rotation.x = -sin(age * 10) * 0.32

func _update_label() -> void:
	if state == State.WAITING:
		order_label.text = "%s\n%s • %ds\n[E] Atender" % [FruitCatalog.order_text(fruit, quantity), FruitCatalog.money(quantity * int(FruitCatalog.ITEMS[fruit]["price"])), ceili(patience)]
		order_label.modulate = Color("ff9f83") if patience < 9 else Color("fff4ce")
	elif state == State.ARRIVING:
		order_label.text = "Vou querer\n%s!" % FruitCatalog.order_text(fruit, quantity)

func interaction_prompt() -> String:
	if state != State.WAITING:
		return ""
	if not session.inventory.has_stock(fruit, quantity):
		return "Faltam %s! Reponha atrás da banca." % FruitCatalog.ITEMS[fruit]["plural"]
	return "[E] Vender %s • %s" % [FruitCatalog.order_text(fruit, quantity), FruitCatalog.money(quantity * int(FruitCatalog.ITEMS[fruit]["price"]))]

func interact() -> void:
	if state == State.WAITING and session.sell(fruit, quantity):
		leave(true)

func leave(was_served: bool) -> void:
	state = State.LEAVING
	destination = Vector3(4.8, 0, -4.8 - slot * 0.7)
	exit_stage = 0
	order_label.text = "Valeu, freguês!" if was_served else "Fica pra próxima..."
	order_label.modulate = Color("a4efce") if was_served else Color("ffb6a0")
