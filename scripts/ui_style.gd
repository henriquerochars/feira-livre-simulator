class_name UIStyle
extends RefCounted

const CREAM := Color("fff0cd")
const MINT := Color("9ee0b9")
const INK := Color("173d3b")

static func panel_style(color: Color = Color("193e3bee"), radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

static func label(text: String, size: int = 20, color: Color = CREAM) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

static func button(text: String, primary: bool = true) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0, 54)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 22)
	node.add_theme_color_override("font_color", INK if primary else CREAM)
	node.add_theme_color_override("font_hover_color", INK)
	node.add_theme_color_override("font_pressed_color", INK)
	node.add_theme_stylebox_override("normal", panel_style(Color("f3ca71") if primary else Color("315b55"), 10))
	node.add_theme_stylebox_override("hover", panel_style(Color("ffe3a0"), 10))
	node.add_theme_stylebox_override("pressed", panel_style(MINT, 10))
	node.add_theme_stylebox_override("focus", panel_style(Color("638e71"), 10))
	return node

static func panel(parent: Control, rect: Rect2) -> VBoxContainer:
	var panel_node := PanelContainer.new()
	panel_node.position = rect.position
	panel_node.size = rect.size
	panel_node.add_theme_stylebox_override("panel", panel_style())
	parent.add_child(panel_node)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel_node.add_child(column)
	return column

static func full_screen(parent: Node) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	return root
