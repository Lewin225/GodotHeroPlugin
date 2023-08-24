@tool
extends EditorPlugin
func _enter_tree() -> void:
	add_autoload_singleton('ChartReader', "res://addons/GodotHero Chart Reader/Autoload/ChartReader.gd")
	print("GodotHero is ready to rock!")
	
func _exit_tree() -> void:
	remove_autoload_singleton('ChartReader')



