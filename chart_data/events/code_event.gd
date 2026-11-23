# TODO: kathinee
class_name EventCodeEvent extends Event

@export var event_name: String = ""
@export var parameters: String = ""
@export var add_speed: bool = false
@export var call_in_editor: bool = true

var event_player: EventPlayer
func init():
	event_player = EventPlayer.instance

func play(speed: float = 1.0):
	if ChartPlayer.instance.editor_active and call_in_editor == false:
		return
	
	var split_parameters = Array(parameters.split(",", false))
	if event_player == null:
		printerr("Emit Signal: EventPlayer does not exist")
		return
	
	if add_speed:
		split_parameters.insert(0, speed)
	
	EventPlayer.instance.call_code_event(event_name, split_parameters)
