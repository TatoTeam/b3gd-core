extends Node

@export var set_frame_on: Array[Node] = []
@export_enum("Set Frame", "Set Frame X", "Set Frame Y") var frame_direction = 0
@onready var note_object:NoteObject = get_parent()
@export var quant_frame_list: Array[int] = []


func _on_note_note_updated() -> void:
	update_note_quant()

func update_note_quant() -> void:
	var note_root_position = note_object.note.time - note_object.note.length_taken
	var quant_frame = quant_frame_list[Note.get_quant_id(note_root_position)]
	for node in set_frame_on:
		match frame_direction:
			0:
				node.frame = quant_frame
			1:
				node.frame_coords.x = quant_frame
			2:
				node.frame_coords.y = quant_frame
