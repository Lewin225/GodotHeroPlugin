extends ChartTrackEvent
class_name ChartTrackEventText

@export var phrase_start:bool = false
@export var phrase_end:bool = false
@export var lyric:String
@export var is_last_syllable:bool = false

func as_plain_text():
	return (
		lyric.replace("-", "")
		.replace("+", "")
		.replace("+", "")
		.replace("=","-")
		.replace("^","")
		.replace("*","")
		.replace("%","")
		.replace("§","‿")
		.replace("$","")
		.replace("/","")
		.replace("_"," ")
		)


func _to_string() -> String:
	return "%s - %s" % [super(), lyric]
