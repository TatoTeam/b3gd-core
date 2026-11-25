class_name NoteObject extends Node3D

var note: Note
var note_direction = 0.0

@onready var note_sprite = $Note

@onready var hold_join = $Node3D/HoldEnd2
@onready var hold_end = $Node3D

func _ready() -> void:
	note_sprite.rotation_degrees.z = note_direction
	note_sprite.rotation_degrees.z = note_direction
