extends Node3D
class_name ReceptorObject

@export var note_object_scene:PackedScene
@export var receptor_index = 0

@onready var animation_player = $AnimationPlayer
@onready var notes = $Notes

var receptor: Receptor

func init_notes() -> void:
	notes.rotation = -rotation
	for note in receptor.notes:
		var note_object: NoteObject = note_object_scene.instantiate()
		note_object.note_direction = rotation_degrees.z
		note_object.note = note
		notes.add_child(note_object)
	update_notes()

func _process(_delta: float) -> void:
	update_receptor()
	update_notes()

func update_receptor():
	if receptor == null or receptor.last_press == null: 
		return
	
	var time = SongAudioPlayer.instance.song_position_seconds
	var input_time = receptor.last_press.input_time
	var time_since_input = time - input_time
	animation_player.stop()
	if receptor.last_press.note == null:
		if receptor.last_press.ignore_draw:
			play_animation_at("idle", 0.0)
		else:
			play_animation_at("dummy", time_since_input)
	elif receptor.last_press.note.length_taken == 0:
		play_animation_at("hit", time_since_input)
	else:
		if receptor.last_press.note.note_state == Note.NoteState.NOTE_COMPLETE:
			var last_time = looped_animation_time("hit_hold", receptor.last_press.note.length_taken)
			play_animation_at("hit_hold", last_time + time_since_input, true)
		else:
			play_animation_at("hit_hold", receptor.last_press.note.length_taken)

func update_notes() -> void:
	for note_object:NoteObject in notes.get_children():
		var note: Note = note_object.note
		var note_y = SongAudioPlayer.instance.song_position_seconds - note.time
		note_object.position.y = note_y * 3
		if note.length > 0:
			note_object.hold_end.position.y = -note.length * 3
			note_object.hold_join.position.y = note.length * 3
			note_object.hold_join.scale.y = note_object.hold_join.position.y * 3.13
		else:
			note_object.hold_end.hide()
		if note.note_state == Note.NoteState.NOTE_COMPLETE:
			note_object.queue_free()

func play_animation_at(anim_name: String, at: float, force_disable_loop: bool = false):
	var processed_time = at
	if !force_disable_loop:
		processed_time = looped_animation_time(anim_name, processed_time)
	
	animation_player.play(anim_name)
	animation_player.stop(true)
	animation_player.seek(processed_time, true)

func looped_animation_time(anim_name: String, at: float):
	var processed_time = at
	var animation: Animation = animation_player.get_animation(anim_name)
	var has_loop_points = animation.get_marker_names().has("loop_start")
	if !has_loop_points:
		processed_time = min(processed_time, animation.length)
	else:
		var loop_start = animation.get_marker_time("loop_start")
		var loop_end = animation.get_marker_time("loop_end")
		if processed_time > loop_start:
			processed_time = fmod(processed_time - loop_start, loop_end - loop_start) + loop_start
	return processed_time
