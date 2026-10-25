class_name CustomerSpawner
extends Node3D

const CUSTOMER_SCENE: PackedScene = preload("res://scenes/customer.tscn")
var session: GameSessionManager
var customers: Array[CustomerController] = []
var spawn_countdown: float = 1.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func reset() -> void:
	for customer in customers:
		if is_instance_valid(customer):
			customer.queue_free()
	customers.clear()
	spawn_countdown = 0.7

func _process(delta: float) -> void:
	if not session.active:
		return
	spawn_countdown -= delta
	if spawn_countdown <= 0:
		spawn_customer()
		spawn_countdown = rng.randf_range(4.5, 6.5)

func spawn_customer() -> CustomerController:
	if not session.active:
		return null
	var available: Array[int] = [0, 1, 2]
	for customer in customers:
		if is_instance_valid(customer) and customer.state != CustomerController.State.LEAVING:
			available.erase(customer.slot)
	if available.is_empty():
		return null
	var customer := CUSTOMER_SCENE.instantiate() as CustomerController
	customer.session = session
	customer.slot = available[rng.randi_range(0, available.size() - 1)]
	customer.fruit = FruitCatalog.IDS[rng.randi_range(0, 2)]
	customer.quantity = rng.randi_range(1, 3)
	customer.patience = rng.randf_range(27, 36)
	customer.max_patience = customer.patience
	customer.position = Vector3((customer.slot - 1) * 2.0, 0, -17)
	customer.departed.connect(_remove_customer)
	add_child(customer)
	customers.append(customer)
	return customer

func _remove_customer(customer: CustomerController) -> void:
	customers.erase(customer)

func pending_count() -> int:
	var count: int = 0
	for customer in customers:
		if is_instance_valid(customer) and customer.state != CustomerController.State.LEAVING:
			count += 1
	return count

func close_market() -> void:
	# Count outstanding orders before the results snapshot is created.
	for customer in customers:
		if is_instance_valid(customer) and customer.state != CustomerController.State.LEAVING:
			session.missed += 1

func orders_text() -> String:
	var lines: Array[String] = []
	for customer in customers:
		if not is_instance_valid(customer) or customer.state == CustomerController.State.LEAVING:
			continue
		var status: String = "%ds" % ceili(customer.patience) if customer.state == CustomerController.State.WAITING else "a caminho"
		lines.append("%s  •  %s" % [FruitCatalog.order_text(customer.fruit, customer.quantity), status])
	return "\n".join(lines) if not lines.is_empty() else "O próximo freguês já vem!"
