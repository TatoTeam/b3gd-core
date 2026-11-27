extends Node3D

@export var strum_line_idx = 0

@onready var receptors = $Receptors

var strum_line: StrumLine

func _ready() -> void:
	ChartLoader.instance.notes_loaded.connect(load_notes)
	

func load_notes():
	strum_line = ChartPlayer.instance.chart.strum_lines[strum_line_idx]
	for child in receptors.get_children():
		if child is not ReceptorObject:
			continue
		child.receptor = strum_line.receptors[child.receptor_index]
		child.init_notes()
