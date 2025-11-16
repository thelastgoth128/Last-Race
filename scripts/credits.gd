extends Node

#game credits with an auto scroll panel

@onready var scroll_container = $ScrollContainer
@onready var credits_text = $ScrollContainer/Label

var scroll_speed = 60.0 

func _process(delta):
	var max_scroll = scroll_container.get_v_scroll_bar().max_value
	var current_scroll = scroll_container.scroll_vertical
	var new_scroll = current_scroll + scroll_speed * delta
	
	if new_scroll <= max_scroll:
		scroll_container.scroll_vertical = new_scroll
