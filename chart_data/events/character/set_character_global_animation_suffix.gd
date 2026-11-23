# TODO: katherine make icon
class_name EventSetCharacterGlobalAnimationSuffix extends Event

@export var character_node_name: String:
	set(value):
		character_node_name = value
		if parent != null:
			init()

@export var suffix: String

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
			character.global_suffix = suffix
