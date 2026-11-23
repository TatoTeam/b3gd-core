@icon("uid://bsm27yjamvfmo") # TODO: katherine replace ythis
class_name EventPlayCharacterAnimation extends Event

@export_range(0.0, 40.0, 1.0, "or_greater", "camera_targets") var target_idx: int = 0:
	set(value):
		target_idx = value
		if parent != null:
			init()

@export var animation_name: String
@export var can_interrupt: bool

var character: Character

func init():
	print(parent.get_tree(), " ", parent.get_tree().get_first_node_in_group("Characters"))
	if parent.get_tree().get_first_node_in_group("Characters") == null:
		return
	
	var choices = parent.get_tree().get_first_node_in_group("Characters").get_children()
	character = choices[clamp(target_idx, 0, choices.size() - 1)]

func play(_speed: float = 1.0):
	if character != null:
		character.play_external_animation(animation_name, can_interrupt)
