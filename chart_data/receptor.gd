class_name Receptor extends Resource

@export var notes: Array[Note]:
	set(value):
		notes = value
		for note in notes:
			if note != null:
				note.parent = self

var parent: StrumLine:
	get():
		return _parent.get_ref() if _parent else null
	set(value):
		_parent = weakref(value) if value else null

var _parent: WeakRef

class ReceptorInput extends RefCounted:
	## The time the input occured. Used for rendering
	@export var input_time: float = -1000.0
	## If drawing this press should be ignored. For when an input is released
	@export var ignore_draw: bool = true
	## This is "true" when the input didnt hit any notes.
	@export var dummy: bool = false

var last_press:ReceptorInput

func sort_notes():
	for note in notes:
		note.parent = self

	notes.sort_custom(func(a: Note, b: Note): return a.time < b.time)
