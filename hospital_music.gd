extends AudioStreamPlayer

var fade: Tween

func _ready() -> void:
	name = "HospitalMusic"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var loop: AudioStreamWAV = preload("res://assets/music/still_here.wav").duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(round(loop.get_length() * loop.mix_rate))
	stream = loop
	volume_db = -60.0
	play()
	fade = create_tween()
	fade.tween_property(self, "volume_db", -17.0, 2.0)

func set_music_paused(value: bool) -> void:
	stream_paused = value

func fade_out(seconds: float) -> void:
	if fade and fade.is_valid(): fade.kill()
	fade = create_tween()
	fade.tween_property(self, "volume_db", -60.0, seconds)
