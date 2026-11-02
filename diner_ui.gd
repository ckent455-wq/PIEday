extends RefCounted

const INK := Color("191a1beF")
const CREAM := Color("eee6d8")
const MUTED := Color("ada89d")
const GOLD := Color("d5af72")
const GREEN := Color("a9c6a0")

static func box(color: Color, padding := 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.set_color("font_color", "Label", CREAM)
	result.set_color("default_color", "RichTextLabel", CREAM)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := box(Color("292a2b") if state == "normal" else Color("39372f"), 12)
		if state in ["focus", "hover"]:
			style.set_border_width_all(1)
			style.border_color = GOLD
		result.set_stylebox(state, "Button", style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.set_color(state, "Button", CREAM)
	result.set_stylebox("panel", "AcceptDialog", box(INK, 24))
	return result

static func label(text: String, size := 18, color := CREAM) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

static func card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box(INK))
	return panel

static func passive(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): passive(child)
