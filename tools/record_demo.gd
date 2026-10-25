extends SceneTree
## Real gameplay capture, using movement, mouse events and the interaction ray.
var game: Node3D
var recording: String = ""
var recorded_frame: int = 0
var sample_tick: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for tick in range(count):
		if is_instance_valid(game) and game.session.active:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await physics_frame
		await RenderingServer.frame_post_draw
		if not recording.is_empty():
			sample_tick += 1
			if sample_tick % 4 == 0:
				var path := "res://artifacts/recordings/%s/%04d.png" % [recording, recorded_frame]
				var error := root.get_texture().get_image().save_png(path)
				assert(error == OK, "Could not save demo frame")
				recorded_frame += 1

func begin_clip(clip: String) -> void:
	recording = clip
	recorded_frame = 0
	sample_tick = 0
	DirAccess.make_dir_recursive_absolute("res://artifacts/recordings/" + clip)

func end_clip() -> void:
	print("CAPTURE: %s — %d frames at 15 fps" % [recording, recorded_frame])
	recording = ""

func move(action: String, ticks: int) -> void:
	Input.action_press(action)
	await frames(ticks)
	Input.action_release(action)
	await frames(2)

func aim(point: Vector3, ticks: int = 50) -> void:
	var direction: Vector3 = point - game.player.camera.global_position
	var yaw: float = atan2(-direction.x, -direction.z)
	var pitch: float = atan2(direction.y, Vector2(direction.x, direction.z).length())
	var initial_yaw: float = game.player.rotation.y
	var initial_pitch: float = game.player.pitch
	for i in range(ticks):
		var weight: float = smoothstep(0, 1, float(i + 1) / ticks)
		var next_yaw: float = lerp_angle(initial_yaw, yaw, weight)
		var next_pitch: float = lerpf(initial_pitch, pitch, weight)
		var event := InputEventMouseMotion.new()
		event.relative = Vector2(-angle_difference(game.player.rotation.y, next_yaw), game.player.pitch - next_pitch) / PlayerController.SENSITIVITY
		game.player._unhandled_input(event)
		await frames(1)

func press_e() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game.interaction._physics_process(0)
	assert(is_instance_valid(game.interaction.target), "Demo must target a real interactable")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = false
	Input.parse_input_event(event)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Recording requires a graphical display.")
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(12)
	root.get_texture().get_image().save_png("res://docs/media/cover.png")
	game.play_button.pressed.emit()
	# Feed the normal mouse handler directly so unrelated desktop motion cannot
	# contaminate the scripted camera path. Movement and E still use Input.
	game.player.set_process_unhandled_input(false)
	game.spawner.rng.seed = 42
	await frames(70)
	var first: CustomerController = game.spawner.customers[0]
	await move("move_forward", 6)
	var x: float = first.position.x
	if absf(x) > 0.2:
		await move("move_right" if x > 0 else "move_left", roundi(absf(x) / PlayerController.WALK_SPEED * 60))
	await aim(Vector3(x, 1.65, -1.65), 24)
	begin_clip("atendimento")
	var waited: int = 0
	while first.state != CustomerController.State.WAITING and waited < 600:
		await frames(1)
		waited += 1
	assert(first.state == CustomerController.State.WAITING, "First customer did not arrive")
	await frames(60)
	await press_e()
	assert(game.session.served == 1, "First sale did not complete")
	await frames(100)
	var second: CustomerController
	for npc in game.spawner.customers:
		if npc.state != CustomerController.State.LEAVING:
			second = npc
			break
	assert(is_instance_valid(second), "Expected a second customer")
	await aim(game.player.camera.global_position + Vector3(0, -0.05, -5), 20)
	var distance: float = second.position.x - game.player.position.x
	await move("move_right" if distance > 0 else "move_left", roundi(absf(distance) / PlayerController.WALK_SPEED * 60))
	await aim(Vector3(second.position.x, 1.65, -1.65), 30)
	while second.state != CustomerController.State.WAITING:
		await frames(1)
	await frames(50)
	await press_e()
	assert(game.session.served == 2, "Second sale did not complete")
	await frames(110)
	end_clip()
	begin_clip("reposicao")
	await aim(Vector3(0, 1.0, 5.1), 100)
	await frames(70)
	var previous: int = game.session.inventory.count("maca")
	await press_e()
	assert(game.session.inventory.count("maca") == previous + 6, "Restock failed")
	await frames(150)
	await aim(Vector3(-2, 1.65, -1.65), 100)
	await frames(90)
	end_clip()
	print("DEMO VERIFIED: two sales and a paid restock through actual input events.")
	game.queue_free()
	await frames(5)
	quit()
