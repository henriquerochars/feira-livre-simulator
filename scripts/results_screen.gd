class_name ResultsScreen
extends CanvasLayer

signal restart_requested
signal menu_requested
var root: Control
var rating_label: Label
var stats_label: Label
var retry_button: Button

func _ready() -> void:
	layer = 3
	root = UIStyle.full_screen(self)
	var shade := ColorRect.new()
	shade.color = Color("142f30dd")
	root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(570, 0)
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 17)
	panel.add_child(column)
	column.add_child(UIStyle.label("FIM DE FEIRA", 17, UIStyle.MINT))
	rating_label = UIStyle.label("", 35)
	column.add_child(rating_label)
	stats_label = UIStyle.label("", 23)
	stats_label.add_theme_constant_override("line_spacing", 10)
	column.add_child(stats_label)
	column.add_child(UIStyle.label("Lucro = vendas − reposição. Caixa inicial: R$ 50,00.\nPedidos pendentes ao fechar contam como perdidos.", 16, UIStyle.MINT))
	retry_button = UIStyle.button("Mais uma feira!")
	retry_button.pressed.connect(func(): restart_requested.emit())
	column.add_child(retry_button)
	var menu := UIStyle.button("Voltar ao início", false)
	menu.pressed.connect(func(): menu_requested.emit())
	column.add_child(menu)
	root.hide()

func show_results(results: Dictionary) -> void:
	rating_label.text = results["rating"]
	stats_label.text = "Receita de vendas       %s\nGastos com reposição   %s\nLucro líquido                %s\nCaixa final                     %s\n\nClientes atendidos         %d\nClientes perdidos           %d" % [FruitCatalog.money(results["revenue"]), FruitCatalog.money(results["expenses"]), FruitCatalog.money(results["profit"]), FruitCatalog.money(results["cash"]), results["served"], results["missed"]]
	root.show()
	retry_button.grab_focus()
