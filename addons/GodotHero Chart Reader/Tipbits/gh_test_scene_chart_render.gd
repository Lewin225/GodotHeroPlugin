extends Control


@export var colors = [Color.DARK_GREEN, Color.DARK_RED, Color.DARK_KHAKI, Color.DARK_BLUE, Color.DARK_ORANGE, Color.WHITE, Color.WHITE, Color.WHITE]



var note_block_lookup = {}

func render_chart(chart:ChartSong, sub_chart_id=0):
	
	
	for child in get_children():
		note_block_lookup = {}
		child.queue_free()
	
	
	self.size.y = chart.get_last_tick() * 1.5
	
	# Draw the chart with the first difficulty/instrument
	print("Chart renderer - fetching events")
	var events = chart.get_sub_chart(chart.get_sub_chart_list()[sub_chart_id])
	print("Chart renderer - fetching events finished")
	
	print("Chart renderer - rendering...")
	for event in events:
		await get_tree().process_frame
		if event is ChartTrackEventNote:
			var b = ColorRect.new()
			b.position.x = event.fret * 5
			b.position.y = event.position * 1
			b.size.x = 5
			b.size.y = 5 + (event.length*1)
			b.color = colors[event.fret]
			b.color.a = 0.75
			self.add_child(b)
			note_block_lookup[event] = b
	print("Chart renderer - rendering finished")
		
			
			
			
func hide_note(note:ChartTrackEventNote):
	if note in note_block_lookup:
		note_block_lookup[note].visible = false
