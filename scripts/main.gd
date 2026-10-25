extends Node3D

var session: GameSessionManager
var market: MarketManager
var player: PlayerController
var interaction: InteractionSystem
var spawner: CustomerSpawner
var hud: GameHUD
var results_screen: ResultsScreen
var menu_camera: Camera3D
var menu: Control
var play_button: Button

func _ready() -> void:
	_setup_input()
	session = GameSessionManager.new()
	session.name = "GameSessionManager"
	add_child(session)
	market = MarketManager.new()
	market.name = "MarketManager"
	add_child(market)
	market.build(session)
	player = PlayerController.new()
	player.name = "PlayerController"
	add_child(player)
	player.reset_position()
	spawner = CustomerSpawner.new()
	spawner.session = session
	spawner.name = "CustomerSpawner"
	add_child(spawner)
	interaction = InteractionSystem.new()
	interaction.player = player
	interaction.session = session
	add_child(interaction)
	hud = GameHUD.new()
	hud.session = session
	hud.spawner = spawner
	hud.interaction = interaction
	add_child(hud)
	results_screen = ResultsScreen.new()
	add_child(results_screen)
	results_screen.restart_requested.connect(start_game)
	results_screen.menu_requested.connect(show_menu)
	session.closing.connect(spawner.close_market)
	session.finished.connect(_finish_game)
	var sound := SoundManager.new()
	add_child(sound)
	session.feedback.connect(sound.play_feedback)
	menu_camera = Camera3D.new()
	add_child(menu_camera)
	menu_camera.position = Vector3(10, 8.5, 10)
	menu_camera.look_at(Vector3(0, 1, -7))
	menu_camera.fov = 65
	_build_menu()
	show_menu()
	if "--smoke" in OS.get_cmdline_user_args():
		start_game()

func _setup_input() -> void:
	var bindings: Dictionary = {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "sprint": KEY_SHIFT, "jump": KEY_SPACE, "interact": KEY_E, "release_mouse": KEY_ESCAPE}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)

func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	menu = UIStyle.full_screen(layer)
	var margin := MarginContainer.new()
	menu.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 38)
	var row := HBoxContainer.new()
	margin.add_child(row)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(490, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style(Color("173d3bf5"), 22))
	row.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(UIStyle.label("DOMINGO • VILA ESPERANÇA", 17, UIStyle.MINT))
	var title := UIStyle.label("FEIRA\nLIVRE", 64)
	title.add_theme_constant_override("line_spacing", -15)
	column.add_child(title)
	column.add_child(UIStyle.label("S I M U L A T O R", 22, Color("f3ca71")))
	column.add_child(UIStyle.label("Fruta fresquinha. Troco na mão.\nTrês minutos pra fazer a feira render.", 20))
	var instructions := UIStyle.label("01  Mire no freguês e aperte E para vender.\n02  Compre reposição atrás da sua banca.\n03  Atenda antes que a paciência acabe!", 18, UIStyle.MINT)
	instructions.add_theme_constant_override("line_spacing", 7)
	column.add_child(instructions)
	play_button = UIStyle.button("Jogar  •  abrir a banca")
	play_button.pressed.connect(start_game)
	column.add_child(play_button)
	var quit := UIStyle.button("Sair", false)
	quit.pressed.connect(func(): get_tree().quit())
	column.add_child(quit)
	column.add_child(UIStyle.label("WASD + mouse  •  E interagir  •  ESC liberar cursor", 15))

func start_game() -> void:
	spawner.reset()
	results_screen.root.hide()
	menu.hide()
	player.reset_position()
	player.enabled = true
	player.camera.make_current()
	session.start_session()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_feedback("Bora fazer a feira! Seus fregueses estão chegando.", true)

func show_menu() -> void:
	session.active = false
	player.enabled = false
	spawner.reset()
	results_screen.root.hide()
	menu.show()
	menu_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.grab_focus()

func _finish_game(results: Dictionary) -> void:
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	results_screen.show_results(results)

func _unhandled_input(event: InputEvent) -> void:
	if session.active and event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(session) and session.active:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
