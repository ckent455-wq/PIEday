extends AudioStreamPlayer

const DAY_VOLUME_DB := -13.0
const NIGHT_VOLUME_DB := -13.0
var night := false
var fade: Tween
var night_track: AudioStreamPlayer

func _loop(source: AudioStreamWAV) -> AudioStreamWAV:
	var result: AudioStreamWAV = source.duplicate()
	result.loop_mode = AudioStreamWAV.LOOP_FORWARD
	result.loop_begin = 0
	result.loop_end = int(round(result.get_length() * result.mix_rate))
	return result

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "DinerMusic"
	stream = _loop(preload("res://assets/music/counter_service.wav"))
	night_track = AudioStreamPlayer.new()
	night_track.name = "AfterHoursMusic"
	night_track.stream = _loop(preload("res://assets/music/last_customer.wav"))
	night_track.volume_db = -60.0
	add_child(night_track)
	volume_db = -60.0
	play()
	fade = create_tween()
	fade.tween_property(self, "volume_db", DAY_VOLUME_DB, 1.3)

func set_music_paused(value: bool) -> void:
	stream_paused = value
	night_track.stream_paused = value

func set_night(value: bool) -> void:
	if night == value: return
	night = value
	if fade and fade.is_valid(): fade.kill()
	var incoming: AudioStreamPlayer = night_track if night else self
	var outgoing: AudioStreamPlayer = self if night else night_track
	if not incoming.playing:
		incoming.volume_db = -60.0
		incoming.play()
	fade = create_tween().set_parallel(true)
	fade.tween_property(incoming, "volume_db", NIGHT_VOLUME_DB if night else DAY_VOLUME_DB, 2.0)
	fade.tween_property(outgoing, "volume_db", -60.0, 2.0)
	fade.chain().tween_callback(outgoing.stop)
