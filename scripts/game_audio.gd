extends Node

const TRACKS := {"main_menu":"menu", "laboratory_intro":"intro", "micro_arena":"tutorial",
	"tabletop_stage":"tabletop", "lower_lab_stage":"lower_lab", "shaft_descent":"shaft", "hive_stage":"hive"}
const MUSIC_DIR := "res://assets/third_party/juhani_junkala_action/"
const SOUND_DIR := "res://assets/third_party/science_audio/"
const LEVELS := {"brush":-7, "bubble":-6, "hit":-3, "hurt":-2, "dodge":-8, "jump":-10,
	"confirm":-7, "lever":-4, "bounce":-6, "jar":-2, "jet":-2, "spit":-4, "warn":-7,
	"roar":-2, "laugh":-4, "slam":-2, "nova":-3, "solar":-3}
var decks: Array[AudioStreamPlayer] = []
var voices: Array[AudioStreamPlayer] = []
var clips := {}
var last_played := {}
var current := ""
var active_deck := 0
var crossfade: Tween
var water: AudioStreamPlayer
var settings := ConfigFile.new()
var clock := 0.0
var has_output := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	has_output = AudioServer.get_driver_name() != "Dummy" or not Engine.get_write_movie_path().is_empty()
	settings.load("user://sound.cfg")
	for channel in ["Music", "Effects"]:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, channel)
		AudioServer.set_bus_volume_db(index, linear_to_db(level(channel)))
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -2.0
	AudioServer.add_bus_effect(0, limiter)
	for i in 2: decks.append(_voice("Music"))
	for i in 8: voices.append(_voice("Effects"))
	water = _voice("Effects")
	var bed := load(SOUND_DIR + "drain.ogg") as AudioStreamOggVorbis
	bed.loop = true
	water.stream = bed
	water.volume_db = -18
	for cue in LEVELS: clips[cue] = load(SOUND_DIR + cue + ".ogg")
	get_tree().scene_changed.connect(_scene_changed)
	get_tree().node_added.connect(_listen_button)
	_start_initial_scene.call_deferred()

func _start_initial_scene() -> void:
	if current.is_empty() and get_tree().current_scene != null: _scene_changed()

func _voice(channel: String) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.bus = channel
	add_child(voice)
	return voice

func level(channel: String) -> float:
	return float(settings.get_value("mix", channel, 0.80 if channel == "Music" else 0.90))

func set_level(channel: String, value: float) -> void:
	settings.set_value("mix", channel, value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(channel), linear_to_db(value))
	settings.save("user://sound.cfg")

func _listen_button(node: Node) -> void:
	if node is BaseButton: node.pressed.connect(effect.bind("confirm"))

func _scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	var track: String = TRACKS.get(scene.scene_file_path.get_file().get_basename(), "")
	for voice in voices: voice.stop()
	last_played.clear()
	if track == "hive":
		if has_output: water.play()
		if scene.beat == scene.Beat.KING: track = "king"
	else: water.stop()
	if track != "": music(track)

func music(track: String, repeat := true) -> void:
	if current == track: return
	current = track
	if not has_output: return
	if crossfade: crossfade.kill()
	var old := decks[active_deck]
	active_deck = 1 - active_deck
	var next := decks[active_deck]
	var song := load(MUSIC_DIR + track + ".ogg") as AudioStreamOggVorbis
	song.loop = repeat
	next.stream = song
	next.volume_db = -54
	next.play()
	crossfade = create_tween().set_parallel()
	crossfade.tween_property(next, "volume_db", 0.0, 0.42)
	crossfade.tween_property(old, "volume_db", -54.0, 0.32)
	crossfade.chain().tween_callback(old.stop)
	if track == "ending": water.stop()

func _process(dt: float) -> void:
	clock += dt

func effect(cue: String, point := Vector2.INF) -> void:
	if not has_output or not clips.has(cue): return
	var distance_db := 0.0
	var cam := get_viewport().get_camera_2d()
	if point != Vector2.INF and cam != null:
		var dx := absf(point.x - cam.get_screen_center_position().x)
		if dx > 440.0: return
		distance_db = -clampf((dx - 195.0) / 28.0, 0.0, 8.0)
	if clock - float(last_played.get(cue, -1.0)) < (0.12 if cue == "hit" else 0.075): return
	var prominent := cue in ["roar", "laugh", "slam", "jet", "warn", "jar", "nova", "solar"]
	for i in range(voices.size() if prominent else voices.size() - 2):
		var voice := voices[voices.size()-1-i if prominent else i]
		if voice.playing: continue
		last_played[cue] = clock
		voice.stream = clips[cue]
		voice.volume_db = float(LEVELS[cue]) + distance_db
		voice.pitch_scale = randf_range(0.96, 1.04) if cue in ["hit","brush","bubble","bounce"] else 1.0
		voice.play()
		return

func _exit_tree() -> void:
	if crossfade: crossfade.kill()
	for voice in decks + voices + [water]:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	clips.clear()
