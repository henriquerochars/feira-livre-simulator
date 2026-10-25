class_name GameHUD
extends CanvasLayer

var session: GameSessionManager
var spawner: CustomerSpawner
var interaction: InteractionSystem
var root: Control
var money_label: Label
var timer_label: Label
var served_label: Label
var inventory_label: Label
var orders_label: Label
var prompt_label: Label
var toast_label: Label
var toast_time: float = 0
var cursor_panel: PanelContainer

func _ready() -> void:
	root = UIStyle.full_screen(self)
	var top := PanelContainer.new()
	root.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 22
	top.offset_right = -22
	top.offset_top = 18
	top.offset_bottom = 98
	top.add_theme_stylebox_override("panel", UIStyle.panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	top.add_child(row)
	var brand := UIStyle.label("BANCA DO CAPRICHO", 21, UIStyle.MINT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	money_label = UIStyle.label("", 24)
	row.add_child(money_label)
	served_label = UIStyle.label("", 20)
	row.add_child(served_label)
	timer_label = UIStyle.label("", 30, Color("f3ca71"))
	row.add_child(timer_label)
	var inventory_column := UIStyle.panel(root, Rect2(22, 116, 290, 193))
	inventory_column.add_child(UIStyle.label("SUA BANCA", 15, UIStyle.MINT))
	inventory_label = UIStyle.label("", 21)
	inventory_column.add_child(inventory_label)
	inventory_column.add_child(UIStyle.label("Reposição: caixas atrás de você", 15))
	var orders_panel := PanelContainer.new()
	root.add_child(orders_panel)
	orders_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	orders_panel.offset_left = -345
	orders_panel.offset_right = -22
	orders_panel.offset_top = 116
	orders_panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	var orders_column := VBoxContainer.new()
	orders_column.add_theme_constant_override("separation", 12)
	orders_panel.add_child(orders_column)
	orders_column.add_child(UIStyle.label("FREGUESES", 15, UIStyle.MINT))
	orders_label = UIStyle.label("", 19)
	orders_column.add_child(orders_label)
	var crosshair := UIStyle.label("·", 38, Color.WHITE)
	root.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -8
	crosshair.offset_top = -27
	var bottom := VBoxContainer.new()
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -155
	bottom.offset_bottom = -16
	bottom.add_theme_constant_override("separation", 10)
	toast_label = UIStyle.label("", 21, UIStyle.MINT)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color", Color("173d3b"))
	toast_label.add_theme_constant_override("shadow_outline_size", 5)
	bottom.add_child(toast_label)
	prompt_label = UIStyle.label("", 22)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_stylebox_override("normal", UIStyle.panel_style(Color("173d3be8"), 8))
	bottom.add_child(prompt_label)
	var controls := UIStyle.label("WASD  andar     SHIFT  correr     ESPAÇO  pular     E  atender / repor     ESC  cursor", 15)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_shadow_color", Color("173d3b"))
	controls.add_theme_constant_override("shadow_outline_size", 5)
	bottom.add_child(controls)
	cursor_panel = PanelContainer.new()
	root.add_child(cursor_panel)
	cursor_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cursor_panel.offset_left = -210
	cursor_panel.offset_right = 210
	cursor_panel.offset_top = -90
	cursor_panel.offset_bottom = 90
	cursor_panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	var cursor_column := VBoxContainer.new()
	cursor_panel.add_child(cursor_column)
	var notice := UIStyle.label("Cursor livre • o tempo continua", 20)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cursor_column.add_child(notice)
	var resume := UIStyle.button("Voltar à feira  [ESC]")
	resume.pressed.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	cursor_column.add_child(resume)
	session.feedback.connect(show_feedback)
	root.hide()

func _process(delta: float) -> void:
	root.visible = session.active
	if not session.active:
		return
	money_label.text = "CAIXA  %s" % FruitCatalog.money(session.economy.cash)
	served_label.text = "%d atendidos" % session.served
	var seconds: int = ceili(session.remaining)
	timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	timer_label.modulate = Color("ff9b80") if seconds <= 30 else Color.WHITE
	var lines: Array[String] = []
	for id in FruitCatalog.IDS:
		lines.append("%s   %02d un.   •   R$ %d" % [FruitCatalog.ITEMS[id]["name"], session.inventory.count(id), FruitCatalog.ITEMS[id]["price"]])
	inventory_label.text = "\n".join(lines)
	orders_label.text = spawner.orders_text()
	prompt_label.text = interaction.prompt if not interaction.prompt.is_empty() else "Mire em um cliente e aperte E para vender"
	toast_time = maxf(0, toast_time - delta)
	toast_label.text = toast_label.text if toast_time > 0 else ""
	cursor_panel.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED

func show_feedback(message: String, success: bool) -> void:
	toast_label.text = message
	toast_label.modulate = UIStyle.MINT if success else Color("ffb395")
	toast_time = 3.5
