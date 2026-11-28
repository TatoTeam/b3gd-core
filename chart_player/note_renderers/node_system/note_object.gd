class_name NoteObject extends Node3D

var note: Note
var note_direction = 0.0

@onready var note_sprite = $Note
@onready var hold_join = $Node3D/HoldEnd2
@onready var hold_end = $Node3D

signal note_updated

func _ready() -> void:
	note_sprite.rotation_degrees.z = note_direction

func update_note() -> void:
	var note_y = SongAudioPlayer.instance.song_position_seconds - note.time
	position.y = note_y * ChartPlayer.instance.chart.scroll_speed
	
	if note.length > 0:
		hold_end.position.y = -note.length * ChartPlayer.instance.chart.scroll_speed
		hold_join.position.y = note.length * ChartPlayer.instance.chart.scroll_speed
		hold_join.scale.y = hold_join.position.y * 3.13
	else:
		hold_end.hide()
	note_updated.emit()
