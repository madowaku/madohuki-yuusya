class_name SoundBank
extends Node

const STREAMS: Dictionary = {
	"place": preload("res://assets/audio/place.ogg"),
	"retrieve": preload("res://assets/audio/retrieve.ogg"),
	"wipe": preload("res://assets/audio/wipe.wav"),
	"shine": preload("res://assets/audio/shine.wav"),
	"clear": preload("res://assets/audio/clear.wav"),
	"step": preload("res://assets/audio/step.wav"),
}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var next_player: int = 0
var muted: bool = false
var wipe_cooldown: float = 0.0

func _ready() -> void:
	for index: int in 6:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -9
		add_child(player)
		players.append(player)
	music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/audio/garden.wav")
	music.volume_db = -22
	add_child(music)
	music.finished.connect(func() -> void:
		if not muted:
			music.play()
	)

func _process(delta: float) -> void:
	wipe_cooldown = maxf(0.0, wipe_cooldown - delta)

func _exit_tree() -> void:
	music.stop()
	music.stream = null
	for player: AudioStreamPlayer in players:
		player.stop()
		player.stream = null

func begin() -> void:
	if not muted and not music.playing:
		music.play()

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		music.stop()
		for player: AudioStreamPlayer in players:
			player.stop()
	else:
		begin()

func play(effect: String) -> void:
	if muted or not STREAMS.has(effect):
		return
	if effect == "wipe":
		if wipe_cooldown > 0:
			return
		wipe_cooldown = 0.13
	var player: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = STREAMS[effect]
	player.volume_db = -17 if effect == "wipe" else -9
	player.play()
