extends Node
signal finished
const CHARACTER_SECONDS := .026
var label: Label
var arrow: Label
var typing := false
var next_character := 0.0
var blink := 0.0

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start(target: Label, text: String) -> void:
	label = target
	label.text = text
	preload("res://retro_dialogue.gd").fit_text(label)
	preload("res://retro_dialogue.gd").fit_text.call_deferred(label)
	label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	label.visible_characters = 0
	typing = not text.is_empty()
	next_character = CHARACTER_SECONDS
	blink = 0
	if is_instance_valid(arrow): arrow.hide()
	if not typing: reveal()

func reveal_if_typing() -> bool:
	if not typing: return false
	reveal()
	return true

func reveal() -> void:
	typing = false
	if is_instance_valid(label): label.visible_characters = -1
	if is_instance_valid(arrow): arrow.show()
	blink = 0
	finished.emit()

func stop() -> void:
	typing = false
	label = null
	if is_instance_valid(arrow): arrow.hide()

func _process(delta: float) -> void:
	if not is_instance_valid(label): return
	if not typing:
		blink += delta
		if is_instance_valid(arrow): arrow.visible = fmod(blink,1.0) < .65
		return
	next_character -= delta
	while typing and next_character <= 0:
		var character := label.text.substr(label.visible_characters,1)
		label.visible_characters += 1
		next_character += CHARACTER_SECONDS
		if character in [".","!","?"]: next_character += .14
		elif character in [",",":",";"]: next_character += .07
		if label.visible_characters >= label.text.length(): reveal()
