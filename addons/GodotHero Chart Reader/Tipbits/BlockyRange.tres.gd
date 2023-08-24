@tool
extends Range
class_name BlockyRange

@export var active_modulate:Color = Color.WHITE
@export var idle_modulate:Color = Color.GRAY
@export var fill_color:bool = false

@export var alignment = BoxContainer.ALIGNMENT_BEGIN:
	set(newval):
		alignment = newval
		on_changed()
		
@export var vertical:bool = false:
	set(newval):
		vertical = newval
		if %box_container:
			%box_container.vertical = vertical

@export var spacing:int = 1:
	set(newval):
		if %box_container:
			%box_container.set("theme_override_constants/separation", newval)
		spacing = newval

@export var gradient:Gradient = Gradient.new():
	set(newval):
		gradient = newval
		gradient.changed.connect(apply_gradient)		

var total_range:int:
	get:
		return min_value - max_value

func _ready():
	self.changed.connect(on_changed)
	on_changed()
	_on_value_changed(value)
	

	
func apply_gradient():
	for child in %box_container.get_children():
		var color = float(child.get_index()) / float(abs(total_range))
		child.color = gradient.sample(color)

func on_changed():
	
	var recursion_limit = 500
	total_range = min_value - max_value
	%box_container.alignment = alignment
	var deviation = %box_container.get_child_count() - abs(total_range-1)
	printt(total_range, deviation)
	while deviation != 0:
		#print(deviation)
		recursion_limit -= 1
		if recursion_limit < 0:
			#print("Excedded recusion limit")
			deviation = 0
			
			break
			
		if deviation > 0:
			#print("Removing box")
			for child in %box_container.get_children():
				if !child.is_queued_for_deletion():
					child.queue_free()
					deviation -= 1
			
			
		if deviation < 0:
			#print("Adding box")
			var b = ColorRect.new()
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.size_flags_vertical = Control.SIZE_EXPAND_FILL
			b.modulate = idle_modulate
			%box_container.add_child(b)
			b.owner = self
			deviation += 1
	
	await get_tree().process_frame
	
	apply_gradient()
	


func _on_value_changed(value: int) -> void:
	if total_range <= value:
		for child in %box_container.get_children():
			child.modulate = idle_modulate
			var index = value - min_value
			var root = 0 - min_value
			if fill_color:
				if value < 0:
					if child.get_index() >= index and child.get_index() <= root:
						child.modulate = active_modulate
				if value > 0:
					if child.get_index() <= index and child.get_index() >= root:
						child.modulate = active_modulate
						
			if not fill_color:
				if child.get_index() == value - min_value:
					child.modulate = active_modulate
				
