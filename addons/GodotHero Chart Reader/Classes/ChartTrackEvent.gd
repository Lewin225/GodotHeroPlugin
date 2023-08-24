extends Resource
class_name ChartTrackEvent

## a number indicating which tick this event is located at
@export_category("Event")
@export var position:int
@export var type_code:String
@export var value:Array


const EVENT_TYPES:Dictionary = {
	'A':'TEMPO_POSITION',
	'B':'TEMPO_CHANGE', 
	'E':'TEXT_EVENT',
	'H':'HAND_POSITION' ,
	'N':'NOTE_EVENT',
	'S':'SPECIAL_PHRASE',
	'TS':'TIME_SIGNATURE_CHANGE',
	}

func _to_string() -> String:
	return EVENT_TYPES[type_code].capitalize() + " position:%d " % [position]


static func type_code_is_known(type_code:String):
	return type_code in EVENT_TYPES.values()
