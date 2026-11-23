@icon("uid://bsm27yjamvfmo") # TODO: katherine replace ythis
class_name EventPlayCharacterAnimation extends Event

@export var character_node_name: String:
	set(value):
		character_node_name = value
		if parent != null:
			init()

@export var animation_name: String
@export var can_interrupt: bool

var characters: Array[Character]

func init():
	characters.clear()
	var choices = parent.get_tree().get_nodes_in_group("Character")
	for choice in choices:
		if choice.name == character_node_name:
			characters.append(choice)

func play(speed: float = 1.0):
	for character in characters:
		if character != null && speed > 0:
			character.play_external_animation(animation_name, can_interrupt)
