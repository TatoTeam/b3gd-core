class_name StrumLine extends Resource

## The list of Receptors (Also called.. Strums. does the name make sense now?)
@export var receptors: Array[Receptor]:
	set(value):
		receptors = value
		for receptor in receptors:
			if receptor != null:
				receptor.parent = self

## If this is true, Input on this strumline is automatic
@export var cpu: bool

var function: Callable
