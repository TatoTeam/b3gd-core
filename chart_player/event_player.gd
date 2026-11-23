extends Node
class_name EventPlayer

static var instance: EventPlayer

signal pre_init_events()

var last_played_event: int = -1
var _events_initialized: bool = false
var events:Array[Event]

@export_group("Node References")
@export var song_audio_player: Node

var code_event_functions: Dictionary[String, Array] = {}

signal on_event_played(event: Event, speed: float)

func _init():
	instance = self

static func attach_to_code_event(event_name: String, func_to_run: Callable):
	if EventPlayer.instance == null:
		printerr("attach_to_code_event Can only be called when EventPlayer.instance exists.")
		return
	
	EventPlayer.instance._attach_to_code_event(event_name, func_to_run)

func _process(_delta: float) -> void:
	var i = 0
	while process_events():
		i += 1
		if i > 8000:
			printerr(">8000 Events just tried to play in one frame. What?")
			return

func init_events() -> void:
	pre_init_events.emit()
	for event in events:
		event.parent = self
		event.init()

	last_played_event = -1
	if _events_initialized:
		var position_seconds = song_audio_player.song_position_seconds
		for i in range(events.size()):
			if events[i].time > position_seconds:
				break
			last_played_event = i
	
	_events_initialized = true

func call_code_event(event_name: String, params: Array):
	if code_event_functions.get(event_name) == null:
		return
	
	for callable: Callable in code_event_functions[event_name]:
		callable.callv(params)

func _attach_to_code_event(event_name: String, func_to_run: Callable):
	if code_event_functions.get(event_name) == null:
		code_event_functions.set(event_name, [])
	
	code_event_functions[event_name].append(func_to_run)

func play_event(event: Event, speed: float):
	event.play(speed)
	on_event_played.emit(event, speed)

func process_events() -> bool:
	if events.is_empty():
		return false

	if last_played_event >= events.size():
		if events[-1].time <= song_audio_player.song_position_seconds:
			last_played_event = max(events.size() - 1, -1)
			play_event(events[last_played_event], song_audio_player.pitch_scale * -1)
		return false # Clamped to last event in array, play last event in reverse
	
	if last_played_event != -1 and events[last_played_event].time > song_audio_player.song_position_seconds:
		play_event(events[last_played_event], song_audio_player.pitch_scale * -1)
		last_played_event = max(last_played_event - 1, -1)
		return true
	
	if last_played_event >= events.size() - 1:
		return false
	
	if events[last_played_event + 1].time <= song_audio_player.song_position_seconds:
		last_played_event += 1
		play_event(events[last_played_event], song_audio_player.pitch_scale * 1)
		return true
	
	return false
