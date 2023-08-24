extends ChartTrackEvent
class_name ChartTrackEventSyncTempos

# Part of the .chart spec, tempo for this section
@export var chart_tempo:int:
	set(new_value):
		chart_tempo = new_value
		bpm = chart_tempo / 1000.0

## Not part of the spec, but are calculated during load to ease
## implementation for plugin users
@export var bpm:float = 0.0
@export var parent_chart_resolution:int = 192

## Set during load as the loader in ChartSong reads the event after this one
@export var next_event_position:int = 0:
	set(new_val):
		next_event_position = new_val
		length = next_event_position - position
		length_seconds = get_length(parent_chart_resolution)

@export var length:int = 0
@export var length_seconds:float = 0.0

func _to_string() -> String:
	return "%s bpm: %s next_pos: %s" % [super(), bpm, next_event_position]

func get_length(resoluton:int)->float:
	## Compute the length of this section in seconds at a given resolution
	var length:int = self.next_event_position - self.position
	var section_beat_length_in_seconds:float = 60.0 / bpm
	var length_in_beats:float = float(length) / resoluton
	return length_in_beats * section_beat_length_in_seconds

