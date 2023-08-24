extends Resource
class_name ChartSong
@export var raw:Dictionary
@export var sub_charts:Array[String]
@export_category("Data/Meta")
@export var meta_source_folder:String
@export var meta_source_chart:String
@export var meta_global_events:Array[ChartTrackEvent] = []
@export var meta_chart_tempo_events:Array[ChartTrackEventSyncTempos] = []
@export var meta_sub_charts:Dictionary
func get_sub_chart_list()->Array:
	return meta_sub_charts.keys()
func get_sub_chart(sub_chart_name:String)->Array:
	return meta_sub_charts[sub_chart_name]
@export var meta_chart_events_loaded:bool = false

@export_category("Song")
@export var name:String
@export var artist:String
@export var album:String
@export var genre:String
@export var year:String
@export var charter:String
@export var resolution:int
@export var difficulty:String
@export var offset:String
@export var version:String
@export var album_track:int
@export var track:int
@export var playlist_track:int
@export var song_length:int
@export var previewstart:int
@export var previewend:int
@export var loading_phrase:String

@export_category("Streams")
@export var musicstream:AudioStream
@export var guitarstream:AudioStream
@export var bassstream:AudioStream

@export_category("Images and Other Resources")
## Album art
@export var icon:Texture2D
## Background image
@export var background:Texture2D
## Path to the video, could use https://github.com/EIRTeam/EIRTeam.FFmpeg to load it?
@export var video:String
@export var video_loop:bool = false


enum GH_ERR{UNKNOWN_EVENT_TYPE, UNEXPECTED_DATA, BAD_EVENT, FILE_NOT_FOUND, NOT_FULLY_LOADED}

func gh_error(error:GH_ERR, details:String):
	printerr("🎸⚡ " + str(error) + " - " + details)

func get_last_tick()->int:
	# Returns the last tick in this chart, searching all events
	# Returns 0 if full_load has not been called
	if not meta_chart_events_loaded:
		gh_error(GH_ERR.NOT_FULLY_LOADED, "Can't determine final tick as chart is not fully loaded")
		return 0
	var max_tick = 0
	for event in meta_global_events:
		if event.position > max_tick:
			max_tick = event.position
	for chart in meta_sub_charts:
		for event in meta_sub_charts[chart]:
			if event.position > max_tick:
				max_tick = event.position
	return max_tick
			

static func create_from_chart_file(chart_file_path)-> ChartSong:
	var cs = ChartSong.new()
	if not FileAccess.file_exists(chart_file_path):
		cs.gh_error(GH_ERR.FILE_NOT_FOUND, "Chart file not found at " + chart_file_path)
		return null
	cs.meta_source_folder = chart_file_path.get_base_dir()
	cs.meta_source_chart = chart_file_path
	# Load, but not the events
	cs.load_chart(FileAccess.open(chart_file_path,FileAccess.READ), false)
	return cs
	
	
func full_load()->bool:
	if not FileAccess.file_exists(meta_source_chart):
		gh_error(GH_ERR.FILE_NOT_FOUND, "Can't full load, original chart file missing " + meta_source_chart)
		return false
	load_chart(FileAccess.open(meta_source_chart,FileAccess.READ), true)
	meta_chart_events_loaded = true
	return true
	
	

	
func get_file(contains:String):
	if meta_source_folder:
		for file in DirAccess.get_files_at(meta_source_folder):
			if contains in file:
				return FileAccess.open(meta_source_folder+"/"+file,FileAccess.READ)
	return false
	
# Returns file name or false
func file_exists(contains:String):
	if get_file:
		return true
	return false
	
	
func load_chart(file:FileAccess, load_chart_events:bool = false):
	var sections:Dictionary
	var in_section = false
	var section_name:String = ""
	while not file.eof_reached():
	
		var line:String = file.get_line()
		
		if not in_section and line.begins_with('['):
			# This must be a new section, get the name and set in_section to true
			section_name = line.rstrip(']').lstrip('[')
			sections[section_name] = {}
			in_section = true
			
		elif in_section:
			if line.begins_with('{'):
				# Sections start with an opening bracket
				pass
				
			elif line.begins_with('}'):
				in_section = false
				section_name = ""
			
			else:
				line = line.strip_edges()
				var data = line.split("=",true,0)
				if len(data) > 1:
					if section_name == 'Song':
						clean_and_set_chart_property(data, load_chart_events)
						
					elif section_name == 'Events' and load_chart_events:
						# Events are stuff that happens on every difficulty/instrument(sub-track). Eg lyrics
						handle_load_event(data)
						
					elif section_name == 'SyncTrack' and load_chart_events:
						handle_load_event(data)
						
					elif load_chart_events:
						# This this must be a sub chart, eg HardDrums
						handle_chart_data(data, section_name)
				else:
					gh_error(GH_ERR.UNEXPECTED_DATA, "Expected a <key> = <value> pair, found " + str(line))
				
	raw = sections	
	after_loaded()	
	
	
func clean_and_set_chart_property(data, import_media=false):
	# Used to handle the data in the [Song] section
	var key = data[0].strip_edges().to_lower()
	var value = data[1].strip_edges().trim_prefix('"').trim_suffix('"')
	# Handle any special field cases here
	if key == 'year':
		# Year is stored as ", 2014". Not sure why
		value = value.replace(",","").strip_edges()
		year = value
		
	elif key in ['musicstream', 'guitarstream', 'bassstream']:
		# Some chart files store this as an absolute path, so we just take the file, eg bass.ogg
		value = value.get_file()
		if file_exists(value):
			match value.get_extension():
				'mp3':
					var m:AudioStreamMP3 = ChartReader.load_mp3(meta_source_folder +"/"+value)
					set(key, m)
				'ogg':
					gh_error(GH_ERR.UNEXPECTED_DATA, "Can't load audio format OGG - Runtime OGG loading will arrive in godot 4.2")
				_:
					gh_error(GH_ERR.UNEXPECTED_DATA, "Can't load audio format - Unknown audio format - " + value)
	else:		
		set(key, value)
	
	
func _to_string() -> String:
	return "ChartSong - %s - %s" % [artist, name]


func handle_load_event(data):
	var positon = data[0].strip_edges()
	var __ = data[1].strip_edges().split(" ",true,1)
	var type_code = __[0]
	var value = __[-1].replace('"', "")
	if not positon.is_valid_int():
		gh_error(GH_ERR.BAD_EVENT, "Event position is not numeric? Skipping " + str(data))
		return
	if type_code not in ChartTrackEvent.EVENT_TYPES:
		gh_error(GH_ERR.UNKNOWN_EVENT_TYPE, "Event not recogniseed, Skipping  " + str(data))
		return
	
	var event:ChartTrackEvent
	match type_code:
		'E':
			event = ChartTrackEventText.new()
			event.type_code = type_code
			event.phrase_start = (value == 'phrase_start')
			event.phrase_end = (value == 'phrase_end')
			event.position = positon
			if value.begins_with("lyric "):
				event.lyric = value.replace("lyric ", "")
				if not value.ends_with('-'):
					event.is_last_syllable = true
				#printt(data, value)
			meta_global_events.append(event)
			
		'B':
			event = ChartTrackEventSyncTempos.new()
			event.chart_tempo = int(value)
			event.position = positon
			event.type_code = type_code
			event.parent_chart_resolution = resolution
			meta_chart_tempo_events.append(event)
		
		_:
			gh_error(GH_ERR.UNKNOWN_EVENT_TYPE, "This event is part of the spec, but cannot be loaded yet, skipping  " + str(data))
			return
	
	
func after_loaded():
	## It is very helpful during implementation that tempo events have
	## The position of the next tempo event stored in them
	## Allowing calulation of the length in ticks and sections without having to
	## Read ahead to the next event
	for i in range(0, len(meta_chart_tempo_events)-1):
		if i + 1 <= len(meta_chart_tempo_events)-1:
			meta_chart_tempo_events[i].next_event_position = meta_chart_tempo_events[i+1].position
		else:
			# Probbaly should just have and extra bool of "is_last_event", but works for now
			meta_chart_tempo_events[i].next_event_position = 999999999999


func handle_chart_data(data, subchart_name):
	## Handles loading the data of a sub-chart, functionally the same as handle_load_event, 
	## but only supports N events (note). and puts the events in the appropriate sub chart
	## this functions should be merged
	## they are only seperate for now as they insert the created event into different places
	
	if subchart_name not in meta_sub_charts:
		meta_sub_charts[subchart_name] = []
	var positon = data[0].strip_edges()
	var __ = data[1].strip_edges().split(" ",true,1)
	var type_code = __[0]
	var value = __[-1].replace('"', "")
	
	match type_code:
		
		'N':
			var note = ChartTrackEventNote.new()
			note.position = positon
			note.type_code = type_code
			value = value.split(" ")
			note.fret = value[0]
			note.length = value[1]
			meta_sub_charts[subchart_name].append(note)


func get_lyrics()->String:
	if !meta_chart_events_loaded:
		gh_error(GH_ERR.NOT_FULLY_LOADED, "Lyrics are stored in events so must be fully loaded to read them")
		return ""
	var str = ""
	for event in meta_global_events:
		if event is ChartTrackEventText:
			str += event.as_plain_text()
			if event.is_last_syllable:
				str += " "
			if event.phrase_end or event.phrase_start:
				str += "\n"

	return str
