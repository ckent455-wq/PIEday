extends RefCounted
## Shared bottom-of-screen dialogue presentation, inspired by the user's reference.
const WHITE := Color("eeeeee")

static func font() -> FontFile:
	var result: FontFile = preload("res://assets/ui/PressStart2P-Regular.ttf").duplicate()
	result.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	result.multichannel_signed_distance_field = false
	return result

static func style(padding := 16) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = Color.BLACK
	result.border_color = WHITE
	result.set_border_width_all(2)
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = padding
	result.content_margin_bottom = padding
	result.shadow_color = Color("555555")
	result.shadow_size = 2
	return result

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = font()
	result.default_font_size = 16
	result.set_color("font_color","Label",WHITE)
	result.set_color("font_shadow_color","Label",Color.BLACK)
	result.set_constant("line_spacing","Label",6)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box := style(10)
		box.bg_color = Color("292929") if state in ["hover","focus"] else Color.BLACK
		box.border_color = Color("666666") if state == "disabled" else WHITE
		box.shadow_size = 0
		result.set_stylebox(state,"Button",box)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		result.set_color(state,"Button",WHITE)
	result.set_font_size("font_size","Button",12)
	return result

static func panel(parent: Control) -> PanelContainer:
	var result := PanelContainer.new()
	parent.add_child(result)
	result.anchor_left = .5
	result.anchor_right = .5
	result.anchor_top = 1
	result.anchor_bottom = 1
	result.offset_top = -24
	result.offset_bottom = -24
	result.grow_vertical = Control.GROW_DIRECTION_BEGIN
	result.resized.connect(func():
		# Moving a control preserves its size. Editing individual offsets here
		# resizes it again and recursively emits this same signal.
		result.position = Vector2((parent.size.x-result.size.x)/2,parent.size.y-result.size.y-24)
	)
	result.add_theme_stylebox_override("panel",style())
	return result

static func fit_text(target: Label) -> void:
	var panel: Node = target.get_parent()
	while panel != null and not panel is PanelContainer: panel = panel.get_parent()
	if panel == null: return
	var viewport_width := target.get_viewport_rect().size.x
	var maximum := minf(840,viewport_width-48)
	var text_width := 0.0
	for line in target.text.split("\n"):
		text_width = maxf(text_width,target.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,target.get_theme_font_size("font_size")).x)
	var minimum := minf(440,maximum)
	var column = panel.get_child(0)
	for child in column.get_children():
		if child == target or child is ScrollContainer: continue
		minimum = maxf(minimum,child.get_combined_minimum_size().x+32)
	var width := clampf(text_width+32,minimum,maximum)
	# Give wrapping a real width before the hidden panel is measured. Otherwise
	# a newly opened label can wrap to one character per line and cache a huge
	# minimum height until the typewriter finishes.
	target.custom_minimum_size.x = width-32
	target.size.x = width-32
	panel.custom_minimum_size.x = width
	if target.get_parent() is ScrollContainer:
		var text_size := target.get_theme_font("font").get_multiline_string_size(target.text,HORIZONTAL_ALIGNMENT_LEFT,width-48,target.get_theme_font_size("font_size"))
		target.get_parent().custom_minimum_size.y = clampf(text_size.y,24,240)
	# Reserve only the height of this page's actual wrapped text. Typing never
	# changes the layout; the next page can shrink or expand the panel again.
	panel.reset_size()
	panel.position = Vector2((panel.get_parent().size.x-panel.size.x)/2,panel.get_parent().size.y-panel.size.y-24)

static func label(text := "", size := 16) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size",size)
	result.add_theme_color_override("font_color",WHITE)
	return result

static func arrow(parent: Node) -> Label:
	var result := label("▼",14)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(result)
	return result
