extends Node
class_name ChartLoader

static var instance: ChartLoader

signal tracks_loaded()
signal notes_loaded()
signal events_loaded()

@export_group("Node References")
@export var chart_player: ChartPlayer
@export var song_audio_player: SongAudioPlayer
@export var note_manager: NoteManager
@export var event_player: Node

func _init():
	instance = self

func _ready() -> void:
	load_chart()

func load_chart():
	load_tracks()
	load_notes(false)
	load_events()

var vocal_layers: Array[int] = []

func load_tracks():
	var old_pos = song_audio_player.song_position_seconds
	
	var chart = chart_player.chart
	var tracks: Array[AudioStream] = [
		chart.tracks.instrumental, 
		chart.tracks.mixed_vocals
	]
	
	tracks.append_array(chart.tracks.vocal_layers)
	
	var track_indices: Array[int] = []
	var present_tracks: Array[AudioStream] = []
	
	for track in tracks:
		track_indices.append(present_tracks.size() if track != null else -1)
		if track != null:
			present_tracks.append(track)
	
	vocal_layers.clear()
	
	for i in chart.strum_lines.size():
		var vocal_layer := -1
		
		if i < chart.tracks.vocal_layers.size():
			vocal_layer = track_indices[i + 2]
		
		if vocal_layer < 0:
			vocal_layer = track_indices[1]
		
		vocal_layers.append(vocal_layer)
	
	tracks = present_tracks

	var audio_stream = AudioStreamSynchronized.new()
	audio_stream.stream_count = tracks.size()
	
	for i in range(tracks.size()):
		audio_stream.set_sync_stream(i, tracks[i])
	
	song_audio_player.stream = audio_stream
	song_audio_player.track_seek(old_pos)
	tracks_loaded.emit()

func load_notes(ignore_past_notes: bool = false):
	for strum_line in chart_player.chart.strum_lines:
		for receptor in strum_line.receptors:
			receptor.parent = strum_line
			receptor.active_note_id = 0
			receptor.last_press = Receptor.ReceptorInput.new()
			receptor.sort_notes()
			for note in receptor.notes:
				note.time -= note.length_taken
				note.length += note.length_taken
				note.length_taken = 0
				
				note.note_state = Note.NoteState.NOTE_ACTIVE
	
	note_manager.strum_lines = chart_player.chart.strum_lines
	
	for strum_line in note_manager.strum_lines:
		strum_line.function = [note_manager.player_receptor_input, note_manager.cpu_receptor_input][int(strum_line.cpu)]
	
	if ignore_past_notes:
		ignore_past_notes()
	
	notes_loaded.emit()

func ignore_past_notes():
	for strum_line in note_manager.strum_lines:
		for receptor in strum_line.receptors:
			for note in receptor.notes:
				if note.time < song_audio_player.song_position_seconds:
					note.note_state = Note.NoteState.NOTE_ACTIVE
				else:
					receptor.active_note_id = receptor.notes.find(note)
					break

func load_events():
	chart_player.chart.sort_events()
	
	event_player.events = chart_player.chart.events
	event_player.init_events()
	
	events_loaded.emit()
