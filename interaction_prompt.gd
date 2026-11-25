extends PanelContainer
## A compact, game-styled interaction card. Keeps the shared text/show/hide API.
var text := "":
 set(value):
  if text == value: return
  text = value
  if is_instance_valid(title): _refresh()
var title: Label
var detail: Label
var keycap: Label
var key_panel: PanelContainer

func _init() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var card := preload("res://diner_ui.gd").game_card_style()
 add_theme_stylebox_override("panel",card)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",14)
 add_child(row)
 key_panel = PanelContainer.new()
 key_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 var key_style := StyleBoxFlat.new()
 key_style.bg_color = Color("e4d6b7")
 key_style.border_color = Color("8f352e")
 key_style.border_width_bottom = 4
 key_style.set_content_margin_all(8)
 key_panel.add_theme_stylebox_override("panel",key_style)
 row.add_child(key_panel)
 keycap = Label.new()
 keycap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 keycap.add_theme_font_override("font",preload("res://retro_dialogue.gd").font())
 keycap.add_theme_font_size_override("font_size",12)
 keycap.add_theme_color_override("font_color",Color("24242a"))
 key_panel.add_child(keycap)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",7)
 row.add_child(column)
 title = Label.new()
 title.custom_minimum_size.x = 350
 title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 title.add_theme_font_override("font",preload("res://retro_dialogue.gd").font())
 title.add_theme_font_size_override("font_size",11)
 title.add_theme_color_override("font_color",Color("f5e5c2"))
 title.add_theme_constant_override("line_spacing",5)
 column.add_child(title)
 detail = Label.new()
 detail.custom_minimum_size.x = 350
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail.add_theme_font_size_override("font_size",15)
 detail.add_theme_color_override("font_color",Color("b8bec4"))
 column.add_child(detail)
 preload("res://diner_ui.gd").passive(self)
 _refresh()

func _refresh() -> void:
 var message := text.strip_edges()
 var key := ""
 if message.begins_with("[") and message.contains("]"):
  var end := message.find("]")
  key = message.substr(1,end-1)
  message = message.substr(end+1).strip_edges()
 keycap.text = key.replace("Click / E","E / LMB") if not key.is_empty() else "!"
 var separator := message.find(" — ")
 if separator < 0: separator = message.find(" · ")
 if separator >= 0:
  title.text = message.left(separator).to_upper()
  detail.text = message.substr(separator+3)
 else:
  title.text = message.to_upper()
  detail.text = ""
 detail.visible = not detail.text.is_empty()
