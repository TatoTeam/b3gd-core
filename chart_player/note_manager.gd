extends Node
class_name NoteInputHandler
static var instance: NoteInputHandler

signal note_press(strum_line_id: int, receptor_id: int, note: Note, hold_delta: float)
signal note_miss(strum_line_id: int, receptor_id: int, note: Note)

## Hit window in seconds. Spans both sides. 
## (e.g. a hit window of 0.2 means 0.1 seconds before and after.)
@export var hit_window = 0.2
@export var hold_end_window = 0.12

@export_group("Node References")
@export var chart_loader: ChartLoader
@export var song_audio_player: AudioStreamPlayer

var strum_lines: Array[StrumLine] = []

func _init():
	instance = self

func _process(_delta: float) -> void:
	for strum_line_id in range(strum_lines.size()):
		for receptor_id in strum_lines[strum_line_id].receptors.size():
			strum_lines[strum_line_id].function.call(strum_line_id, receptor_id)

func cpu_receptor_input(strum_line_id, receptor_id):
	var receptor = strum_lines[strum_line_id].receptors[receptor_id]
	
	if receptor.notes.size() == 0:
		return
	
	if receptor.active_note_id >= receptor.notes.size():
		return
	
	while receptor.notes[receptor.active_note_id].time <= song_audio_player.song_position_seconds:
		hit_note(strum_line_id, receptor_id)
		receptor.last_press.ignore_draw = false
		if receptor.active_note_id >= receptor.notes.size():
			return
		if receptor.notes[receptor.active_note_id].note_state == Note.NoteState.NOTE_STARTED:
			return

func player_receptor_input(strum_line_id, receptor_id):
	var input_name = "strumline_" + str(receptor_id)
	# assert(InputMap.has_action(input_name), "Action " + input_name + " does not exist.")
	var is_pressed = Input.is_action_just_pressed(input_name)
	var is_held = Input.is_action_pressed(input_name)
	var receptor = strum_lines[strum_line_id].receptors[receptor_id]
	receptor.last_press.ignore_draw = !is_held
	
	var note_distance = 100000
	
	if receptor.active_note_id >= receptor.notes.size():
		return
	if receptor.notes.size() > 0:
		note_distance = receptor.notes[receptor.active_note_id].time - song_audio_player.song_position_seconds
	
	
	if note_distance > hit_window * 0.5:
		if is_pressed:
			hit_dummy(strum_line_id, receptor_id)
	elif note_distance < hit_window * -0.5:
		miss_note(strum_line_id, receptor_id)
	else:
		if !is_held and receptor.notes[receptor.active_note_id].note_state == Note.NoteState.NOTE_STARTED and receptor.notes[receptor.active_note_id].length < hold_end_window:
			hit_note(strum_line_id, receptor_id)
		if is_pressed or (is_held and receptor.notes[receptor.active_note_id].note_state == Note.NoteState.NOTE_STARTED):
			hit_note(strum_line_id, receptor_id)

func hit_dummy(strum_line_id, receptor_id):
	var receptor = strum_lines[strum_line_id].receptors[receptor_id]
	receptor.last_press.input_time = song_audio_player.song_position_seconds
	receptor.last_press.dummy = true
	receptor.last_press.note = null
	
	note_press.emit(strum_line_id, receptor_id, null, 1.0)

func hit_note(strum_line_id, receptor_id):
	var receptor = strum_lines[strum_line_id].receptors[receptor_id]
	receptor.last_press.input_time = song_audio_player.song_position_seconds
	receptor.last_press.dummy = false
	receptor.last_press.input_time = song_audio_player.song_position_seconds
	receptor.last_press.note = receptor.notes[receptor.active_note_id]
	var note = receptor.notes[receptor.active_note_id]
	
	var time_difference = song_audio_player.song_position_seconds - note.time
	
	if note.note_hit():
		note_press.emit(strum_line_id, receptor_id, note, time_difference)
		mute_strumline(strum_line_id, false)
	
	if note.length > 0:
		move_sustain(strum_line_id, receptor_id, time_difference)
	else:
		receptor.notes[receptor.active_note_id].note_state = Note.NoteState.NOTE_COMPLETE
		receptor.active_note_id += 1

func miss_note(strum_line_id, receptor_id):
	var receptor = strum_lines[strum_line_id].receptors[receptor_id]
	var note = receptor.notes[receptor.active_note_id]
	
	if note.note_miss():
		note_miss.emit(strum_line_id, receptor_id, note)
		mute_strumline(strum_line_id, true)
	
	if note.length > 0:
		move_sustain(strum_line_id, receptor_id, hit_window, true)
	else:
		receptor.notes[receptor.active_note_id].note_state = Note.NoteState.NOTE_MISSED
		receptor.active_note_id += 1

func move_sustain(strum_line_id, receptor_id, by: float, miss_on_negative: bool = false):
	var receptor = strum_lines[strum_line_id].receptors[receptor_id]
	var note: Note = receptor.notes[receptor.active_note_id]
	note.time += by
	note.length -= by
	note.length_taken += by
	note.note_state = Note.NoteState.NOTE_STARTED
	if note.length < 0 and miss_on_negative:
		miss_note(strum_line_id, receptor_id)

func mute_strumline(strum_line_id, mute):
	var vocal_layer = chart_loader.vocal_layers[strum_line_id]
	song_audio_player.stream.set_sync_stream_volume(vocal_layer, -50 if mute else 0)
