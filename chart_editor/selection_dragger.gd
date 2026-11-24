extends Control

var COLUMN_WIDTH: float = ChartEditor.instance.settings.NOTE_SIZE

@onready var timeline: EditorTimeline = $".."

var dragging: bool = false

var drag_start_pos: Vector2
var drag_start_times: Dictionary[TimelinePoint, float] = {}
var drag_start_columns: Dictionary[TimelinePoint, int] = {}
var drag_receptors: Array[Receptor] = []
var drag_offset_time: float = 0.0
var drag_offset_column: int = 0

func _on_chart_editor_drag_started(_selectable: TimelinePoint):
	dragging = true
	drag_start_pos = timeline.get_local_mouse_position()
	drag_start_times.clear()
	drag_start_columns.clear()
	drag_receptors.clear()
	drag_offset_time = 0.0
	drag_offset_column = 0
	
	for strumline in ChartEditor.instance.chart.strum_lines:
		drag_receptors.append_array(strumline.receptors)

	for selectable in ChartEditor.selection:
		if selectable is Event:
			drag_start_columns[selectable] = selectable.lane
		elif selectable is Note:
			var receptor: Receptor = selectable.parent
			if receptor == null or receptor.parent == null:
				print("um? receptor or strumline is null on ", selectable)
				continue
			
			if !receptor.notes.has(selectable): continue
			var column = drag_receptors.find(receptor)
			if column < 0: continue
			drag_start_columns[selectable] = column
		
		drag_start_times[selectable] = selectable.time
	
	dragging = !drag_start_times.is_empty()

func _process(_delta):
	if !dragging: return
	
	var time_offset = timeline.y_to_time(timeline.get_local_mouse_position().y - drag_start_pos.y)
	drag_offset_time = ChartEditor.instance.settings.snap_time(time_offset)
	
	drag_offset_column = -roundi((timeline.get_local_mouse_position().x - drag_start_pos.x) / COLUMN_WIDTH)
	
	for selectable in drag_start_times:
		selectable.time = drag_start_times[selectable] + drag_offset_time
		
		if selectable is Event:
			selectable.lane = max(drag_start_columns[selectable] + drag_offset_column, 0)
		
		if selectable is Note:
			var receptor: Receptor = selectable.parent
			if receptor == null or receptor.parent == null: continue
			var new_lane = clampi(drag_start_columns[selectable] - drag_offset_column, 0, drag_receptors.size() - 1)
			var new_receptor: Receptor = drag_receptors[new_lane]
			
			if receptor != new_receptor:
				receptor.notes.erase(selectable)
				new_receptor.notes.append(selectable)
				selectable.parent = new_receptor
	
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		finish_drag()

func finish_drag():
	dragging = false
	if is_zero_approx(drag_offset_time) && drag_offset_column == 0:
		return
	
	ChartEditor.undo_redo.create_action("Drag Selection")
	for selectable in drag_start_times:
		ChartEditor.undo_redo.add_do_property(selectable, "time", selectable.time)
		ChartEditor.undo_redo.add_undo_property(selectable, "time", drag_start_times[selectable])
		
		if selectable is Event:
			ChartEditor.undo_redo.add_do_property(selectable, "lane", selectable.lane)
			ChartEditor.undo_redo.add_undo_property(selectable, "lane", drag_start_columns[selectable])
		
		if selectable is Note:
			var receptor: Receptor = selectable.parent
			var old_receptor: Receptor = drag_receptors[drag_start_columns[selectable]]
			if receptor == old_receptor: continue
			
			ChartEditor.undo_redo.add_do_method(func():
				old_receptor.notes.erase(selectable)
				if !receptor.notes.has(selectable):
					receptor.notes.append(selectable)
				
				selectable.parent = receptor
			)
			
			ChartEditor.undo_redo.add_undo_method(func():
				receptor.notes.erase(selectable)
				if !old_receptor.notes.has(selectable):
					old_receptor.notes.append(selectable)
				
				selectable.parent = old_receptor
			)
	
	ChartEditor.undo_redo.add_do_method(update_chart)
	ChartEditor.undo_redo.add_undo_method(update_chart)
	ChartEditor.undo_redo.commit_action()
	drag_start_times.clear()

func update_chart():
	for strum_line in ChartEditor.instance.chart.strum_lines:
		for receptor in strum_line.receptors:
			receptor.sort_notes()
	
	ChartLoader.instance.load_notes()
	ChartLoader.instance.load_events()
