class_name SoundManager
extends Node

var player: AudioStreamPlayer
var positive: AudioStreamWAV
var negative: AudioStreamWAV

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -18
	add_child(player)
	positive = _tone([523.25, 659.25, 783.99])
	negative = _tone([220.0, 174.61])

func play_feedback(_message: String, success: bool) -> void:
	# Dummy audio has no audible output and queues playbacks during fast simulations.
	if DisplayServer.get_name() == "headless":
		return
	player.stop()
	player.stream = positive if success else negative
	player.play()

func _tone(notes: Array) -> AudioStreamWAV:
	var rate: int = 22050
	var note_length: int = int(rate * 0.1)
	var data := PackedByteArray()
	data.resize(note_length * notes.size() * 2)
	for n in range(notes.size()):
		for i in range(note_length):
			var t: float = float(i) / rate
			var envelope: float = sin(PI * float(i) / note_length) * 0.4
			var sample: int = int(sin(TAU * float(notes[n]) * t) * envelope * 32767)
			data.encode_s16((n * note_length + i) * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
