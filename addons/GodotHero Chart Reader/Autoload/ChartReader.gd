extends Node


func load_chart(chart_file_path) -> ChartSong:
	## Loads a .chart file located at chart_file_path.
	## This will only load the metadata, song info, instruments/difficulties ect...
	## The event data will be null, this is good for quickly loading a bunch of charts
	## to present in a list
	## Once a chart is selected, call full_load() or load_sub_chart() to populate the event data
	## A chart loaded with full_load() can actually be saved as a godot resource and can the be used
	## without any of the original files, if you want?
	var new_chart = ChartSong.create_from_chart_file(chart_file_path)
	return new_chart



func load_mp3(path) -> AudioStreamMP3:
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound
