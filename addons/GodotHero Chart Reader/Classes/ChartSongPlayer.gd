extends AudioStreamPlayer
class_name ChartSongPlayer

signal lyric_event(event:ChartTrackEventText)
signal section_event(event:ChartTrackEvent)
signal note_event(event:ChartTrackEventNote)
## A Modified audiostreamplayer that uses it's playback position to read chart files
## Handles converting the playback position(seconds) into ticks, takes into account tempo changes
## Emits signals for lyrics, tempo changes and sections. 
## Use test_hit(fret) to test for notes at the current tick
## You can set hit_offset and hit_hitbox size to change the testing behavour, these are set in ticks
## hit_hitbox defaults to the chart resolution, eg 1/4th a beat

@export var chart:ChartSong:
	set(new_chart):
		playing = false
		if new_chart.meta_chart_events_loaded:
			chart = new_chart
			print(chart)
			_rebuild_event_cache()
			_rebuild_tempo_cache()
			_hit_notes_cache = []
			print("Loading finished, event cache size ", len(_event_cache))
			if chart.musicstream:
				stream = chart.musicstream
			
var _hit_notes_cache:Array[ChartTrackEventNote] = []
# Memory hungry, but simple implementation for quickly finding any events for a given tick
# Array is the length of the chart in ticks, elements are null or an array of ChartEvents
var _event_cache:Array = []
func _rebuild_event_cache():
	print("ChartSongPlayer - Rebuilding Event Cache")
	_event_cache = []
	_event_cache.resize(chart.get_last_tick() * 2)
	print("Building event cache for ", chart.name, " subchart ", chart.get_sub_chart_list()[0])
	print(chart.get_last_tick(), " events to build")
	for event in chart.meta_global_events + chart.get_sub_chart(chart.get_sub_chart_list()[0]):
		var st = event.position
		var nd = 3
		if 'length' in event:
			nd += event.length
			
		for i in range(st, st+nd):
			if _event_cache[i] == null:
				_event_cache[i] = Array()
			_event_cache[i].append(event)
	
	print("Filling in blank events in cache")
	for i in range(0, len(_event_cache)-1):
		if _event_cache[i] == null:
			_event_cache[i] = Array()
			
			
			
	print("Finished building event cache")

			
## These events are kept seperate as we need to read and sum all the tempo changes 
## to work out what tick we should be on every frame
var _tempo_cache:Dictionary
func _rebuild_tempo_cache():
	_tempo_cache = {}
	var sum_length = 0.0
	for event in chart.meta_chart_tempo_events:
		_tempo_cache[event] = Vector2(sum_length, sum_length + event.length_seconds)
		sum_length += event.length_seconds 
		
func get_events_at_tick(tick:int):
	return _event_cache[tick]

func on_chart_changed():
	if chart.meta_chart_events_loaded:
		_rebuild_event_cache()
	else:
		printerr("ChartSongPlayer - Can't play this chart as it's not fully loaded, call full_load on it first!")

func test_hit(fret_num, tick:int, margin:int = 50)->Array:
	tick = clamp(tick,0, 9999999999999)
	var hit_distance:int = margin
	var real_hit_distance:int = 0
	var hit_found = false
	var found_event:ChartTrackEventNote = null
	for i in range(tick-margin, tick+margin):
		for event in get_events_at_tick(i):
			if event is ChartTrackEventNote and event.fret == fret_num:
				if not _hit_notes_cache.has(event):
					if abs(event.position - tick) < hit_distance:
						hit_distance = abs(event.position - tick)
						hit_found = true
						found_event = event
						real_hit_distance = tick - event.position
	if hit_found:
		#printt(tick, found_event.position, tick - found_event.position)
		return [found_event, real_hit_distance]
	return [null, 0]
	
func mark_note_unhittable(note:ChartTrackEventNote):
	_hit_notes_cache.append(note)
	


func get_playback_position_ticks(seconds):
	var current_event = null
	var current_section = null
	for section in _tempo_cache.values():
		if seconds >= section.x and seconds <= section.y:
			current_section = section
			
	# Handle the last tempo change having no Y axis
	if current_event == null:
		for section in _tempo_cache.values():
			if seconds >= section.x:
				current_section = section
	
	current_event = _tempo_cache.find_key(current_section)
	var section_elapsed = seconds - current_section.x
	var beats_elapsed_this_section = section_elapsed * (current_event.bpm / 60.0)
	var ticks_elapsed_this_section = beats_elapsed_this_section * chart.resolution
	return(current_event.position +  ticks_elapsed_this_section)

func get_current_tick():
	return get_playback_position_ticks(get_playback_position() + AudioServer.get_time_since_last_mix())

var _cur_events:Array[ChartTrackEvent] = []
var _last_tick:int
var emitted_lyrics:Array = []
var tps = 0
func _process(delta: float) -> void:
	if chart and playing:
		var tick = int(get_current_tick())
		var events_now = []
		tps = tick - _last_tick
		for x in range(_last_tick, tick):
			for ev in get_events_at_tick(x):
				if ev not in events_now:
					events_now.append(ev)
		
		for event in _cur_events:
			if event not in events_now:
				_cur_events.erase(event)
				
		for event in events_now:
			if event not in _cur_events:
				_cur_events.append(event)
				
				if event is ChartTrackEventText and event not in emitted_lyrics:
					lyric_event.emit(event)
					emitted_lyrics.append(event)
				if event is ChartTrackEventNote:
					if event not in _hit_notes_cache:
						note_event.emit(event)
					
		_last_tick = tick
				
func get_section_length(section_start_tick, section_end_tick, section_bpm, section_time_sig):
	var section_length:int = section_end_tick - section_start_tick
	var section_beat_length_in_seconds:float = 60.0 / section_bpm
	var section_length_in_beats:float = float(section_length) / chart.resoluton
	var final:float = section_length_in_beats * section_beat_length_in_seconds
	return final
	
