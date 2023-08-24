extends ChartTrackEvent
class_name ChartTrackEventNote



@export var fret:int
@export var length:int = 0


func _to_string() -> String:
	return super() + " " + "fret: %d length:%d" % [fret,length]
