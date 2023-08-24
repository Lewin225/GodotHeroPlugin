extends HBoxContainer


var controller_touched = false

func _on_chart_song_player_note_event(event:ChartTrackEventNote) -> void:
	get_child(event.fret).modulate.a = 1.0
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("strum_up") or Input.is_action_just_pressed("strum_down"):
		controller_touched = true
		
	if controller_touched:
		get_child(0).modulate.a = int(Input.is_action_pressed("fret_1"))
		get_child(1).modulate.a = int(Input.is_action_pressed("fret_2"))
		get_child(2).modulate.a = int(Input.is_action_pressed("fret_3"))
		get_child(3).modulate.a = int(Input.is_action_pressed("fret_4"))
		get_child(4).modulate.a = int(Input.is_action_pressed("fret_5"))
	else:
		for child in get_children():
			child.modulate.a = lerp(child.modulate.a, 0.0, delta*1.0)
