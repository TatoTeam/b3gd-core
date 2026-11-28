class_name Note extends TimelinePoint

# Needed for chart data
## The length of the note, if zero this is not a hold note. 
@export_range(0.0, 1.0, 0.0, "or_greater") var length:float = 0

var length_taken:float = 0

# Needed for runtime data
## Used to check if the hold has begun. Used for rendering and input.
## I'm fine with this being in chart data as it is a single bool

enum NoteState {
	NOTE_ACTIVE,
	NOTE_STARTED,
	NOTE_COMPLETE,
	NOTE_MISSED,
}

var note_state: NoteState = NoteState.NOTE_ACTIVE

var parent: Receptor:
	get():
		return _parent.get_ref() if _parent else null
	set(value):
		_parent = weakref(value) if value else null

var _parent: WeakRef

# If note functions return false, the default behaviour will be ignored.
func note_hit() -> bool:
	return true

# If note functions return false, the default behaviour will be ignored.
func note_miss() -> bool:
	return true

static func get_quant_id(note_time: float) -> int:
	return get_quant_id_from_beat(SongAudioPlayer.instance.get_beat_from_seconds(note_time))

const QUANT_LIST := [48, 24, 16, 12, 8, 6, 4, 3]

static func get_quant_id_from_beat(note_beat: float) -> int:
	var note_beat_quant_res: int = round(note_beat * QUANT_LIST[0])
	for i in QUANT_LIST.size():
		if note_beat_quant_res % QUANT_LIST[i] == 0:
			return i
	return QUANT_LIST.size()
