extends Camera3D

@export var focus_position = Vector3.ZERO
@export var camera_height = 4.5

func _process(delta: float) -> void:
	size = (1.0 / position.z) * camera_height
