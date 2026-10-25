extends SceneTree

var checks: int = 0
var failures: int = 0
var visual: bool = "--visual" in OS.get_cmdline_user_args()

func capture(label_text: String) -> void:
	if visual:
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/%s.png" % label_text)

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
	else:
		print("PASS: " + description)

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.menu.visible and not game.session.active, "Main menu is the initial screen")
	await capture("menu")
	game.play_button.pressed.emit()
	var session: GameSessionManager = game.session
	session.set_process(false)
	game.spawner.set_process(false)
	check(session.active and not game.menu.visible, "Play starts the game")
	check(game.player.enabled and game.player.camera.current, "First-person controller and camera are enabled")
	check(session.remaining == 180, "Session starts with exactly three minutes")
	check(session.economy.cash == 50 and session.economy.profit() == 0, "Initial cash is not counted as profit")
	for fruit in FruitCatalog.IDS:
		check(session.inventory.count(fruit) == 6, "Initial inventory: " + fruit)
	check(not session.inventory.add("unknown", 1), "Unknown inventory item rejected")
	check(not session.inventory.remove("banana", -1), "Negative quantity rejected")
	check(not session.sell("banana", 0), "Zero sale rejected")
	check(not session.sell("unknown", 1), "Unknown sale rejected")
	check(session.sell("banana", 2), "Sale succeeds with available stock")
	check(session.inventory.count("banana") == 4, "Sale removes exact quantity")
	check(session.economy.cash == 60 and session.economy.revenue == 10 and session.served == 1, "Sale credits cash, revenue, and served count")
	check(not session.sell("banana", 5), "Overselling rejected")
	check(session.economy.cash == 60 and session.inventory.count("banana") == 4, "Failed sale is atomic")
	check(session.restock("banana"), "Restock succeeds")
	check(session.inventory.count("banana") == 10, "Restock adds six units")
	check(session.economy.cash == 48 and session.economy.expenses == 12 and session.economy.profit() == -2, "Restock and net profit accounting")
	check(not session.economy.spend(-1) and not session.economy.receive(0), "Invalid cash amounts rejected")
	session.economy.spend(48)
	var before: int = session.inventory.count("maca")
	check(not session.restock("maca") and session.inventory.count("maca") == before and session.economy.cash == 0, "Insufficient funds preserves inventory and cash")
	game.start_game()
	game.spawner.set_process(false)
	game.spawner.rng.seed = 42
	var customer: CustomerController = game.spawner.spawn_customer()
	customer.set_physics_process(false)
	check(FruitCatalog.IDS.has(customer.fruit) and customer.quantity >= 1 and customer.quantity <= 3, "Customer has a valid randomized order")
	check(customer.state == CustomerController.State.ARRIVING, "Customer begins by approaching")
	for i in range(90):
		customer._physics_process(0.1)
	check(customer.state == CustomerController.State.WAITING, "Customer walks to counter and waits")
	check(customer.order_label.text.contains("Atender"), "Waiting order is displayed above customer")
	# Validate the actual camera ray through the counter, then dispatch E.
	game.player.position = Vector3(customer.position.x, 0.02, 2.1)
	game.player.camera.look_at(customer.global_position + Vector3(0, 1.65, 0))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await physics_frame
	await physics_frame
	game.interaction._physics_process(0)
	check(game.interaction.target == customer, "Camera ray reaches customer over the counter")
	await capture("gameplay")
	var expected_price: int = customer.quantity * int(FruitCatalog.ITEMS[customer.fruit]["price"])
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	game.interaction._unhandled_input(key)
	check(customer.state == CustomerController.State.LEAVING and session.served == 1, "E serves targeted waiting customer")
	check(session.economy.revenue == expected_price, "Payment matches customer order")
	customer.interact()
	check(session.served == 1 and session.economy.revenue == expected_price, "Customer cannot pay twice")
	for i in range(200):
		if not customer.is_queued_for_deletion():
			customer._physics_process(0.1)
	check(customer.is_queued_for_deletion(), "Served customer walks out and despawns")
	# Aim at real restocking physics body and use the same interaction input.
	var point: RestockPoint
	for node in game.market.get_children():
		if node is RestockPoint and node.fruit == "maca":
			point = node
	game.player.position = Vector3(0, 0.02, 2.6)
	game.player.camera.look_at(point.global_position + Vector3(0, 1, 0))
	await physics_frame
	await physics_frame
	game.interaction._physics_process(0)
	check(game.interaction.target == point, "Camera ray detects restocking crate")
	await capture("restock")
	before = session.inventory.count("maca")
	game.interaction._unhandled_input(key)
	check(session.inventory.count("maca") == before + 6 and session.economy.expenses == 18, "E purchases the targeted restock pack")
	game.player.position = Vector3(0, 0.02, -2.3)
	game.player.camera.look_at(point.global_position + Vector3(0, 0.4, 0))
	await physics_frame
	await physics_frame
	game.interaction._physics_process(0)
	check(game.interaction.target == null, "Counter occludes interaction with distant restock crates")
	var impatient: CustomerController = game.spawner.spawn_customer()
	impatient.set_physics_process(false)
	impatient.position = impatient.destination
	impatient._physics_process(0.1)
	impatient.patience = 0.05
	impatient._physics_process(0.1)
	check(session.missed == 1 and impatient.state == CustomerController.State.LEAVING, "Patience timeout records one missed customer")
	impatient._physics_process(1)
	check(session.missed == 1, "Timeout cannot count the same customer twice")
	game.start_game()
	game.spawner.set_process(false)
	for i in range(3):
		game.spawner.spawn_customer().set_physics_process(false)
	check(game.spawner.spawn_customer() == null and game.spawner.pending_count() == 3, "Queue reserves at most three distinct counter slots")
	session.advance(179.9)
	check(session.active and session.remaining > 0, "Session stays active before deadline")
	session.advance(0.2)
	check(not session.active and session.remaining == 0, "Session completes at 180 seconds")
	check(session.missed == 3, "Unfulfilled orders counted at closing")
	check(game.results_screen.root.visible and not game.player.enabled, "Closing displays results and disables movement")
	var final_results: Dictionary = session.results()
	check(not session.sell("banana", 1) and not session.restock("maca"), "Transactions rejected after closing")
	session.finish_session()
	check(session.results() == final_results, "Repeated completion does not alter results")
	game.results_screen.restart_requested.emit()
	check(session.active and session.served == 0 and session.missed == 0 and session.economy.cash == 50 and game.spawner.customers.is_empty(), "Results restart resets all match state")
	# Exercise real CharacterBody physics and mapped movement input.
	game.player.reset_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.action_press("move_forward")
	for frame in range(60):
		await physics_frame
	Input.action_release("move_forward")
	check(game.player.position.z > 0.88 and game.player.position.z < 1.05, "Counter collision blocks forward movement")
	check(game.player.is_on_floor(), "Gravity settles player onto the street")
	game.player.reset_position()
	Input.action_press("move_right")
	for frame in range(20):
		await physics_frame
	Input.action_release("move_right")
	var walk_distance: float = game.player.position.x
	game.player.reset_position()
	Input.action_press("move_right")
	Input.action_press("sprint")
	for frame in range(20):
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("sprint")
	check(walk_distance > 1.0 and game.player.position.x > walk_distance * 1.3, "WASD moves player and Shift increases speed")
	for frame in range(10):
		await physics_frame
	Input.action_press("jump")
	for frame in range(10):
		await physics_frame
	Input.action_release("jump")
	check(game.player.position.y > 0.45, "Space makes grounded player jump")
	for frame in range(60):
		await physics_frame
	check(game.player.is_on_floor(), "Jump lands back on solid ground")
	# Simulate an entire 180-second match through production spawn, walk, sale and restock logic.
	game.spawner.set_process(false)
	game.spawner.rng.seed = 12345
	for second in range(180):
		game.spawner._process(1.0)
		for npc in game.spawner.customers.duplicate():
			if npc.is_queued_for_deletion():
				continue
			npc.set_physics_process(false)
			for tick in range(10):
				if not npc.is_queued_for_deletion():
					npc._physics_process(0.1)
			if npc.state == CustomerController.State.WAITING:
				if not session.inventory.has_stock(npc.fruit, npc.quantity):
					session.restock(npc.fruit)
				npc.interact()
		session.advance(1.0)
	check(not session.active and session.served >= 20, "Full simulated match serves at least twenty customers")
	check(session.economy.expenses > 0, "Full match exercises inventory replenishment")
	check(session.economy.cash == 50 + session.economy.revenue - session.economy.expenses, "Full match cash reconciles exactly")
	check(session.results()["profit"] == session.economy.revenue - session.economy.expenses, "Results report accurate net profit")
	check(not session.results()["rating"].is_empty(), "Results include performance rating")
	print("MATCH RESULTS: ", session.results())
	await capture("results")
	game.results_screen.menu_requested.emit()
	check(game.menu.visible and not session.active, "Results return to menu")
	game.queue_free()
	await process_frame
	await process_frame
	print("TEST SUMMARY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
