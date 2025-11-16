extends Control

func _on_left_pressed() -> void:
	$"../ClickSound".play()
	get_parent()._left()


func _on_right_pressed() -> void:
	$"../ClickSound".play()
	get_parent()._right()

func _on_start_race_pressed() -> void:
	$"../Click2Sound".play()
	var carousel = get_parent()
	var selected_index = carousel.selected_index
	var selected_entry = carousel.position_offset_node.get_child(selected_index)
	Global.selected_car = selected_entry.get_node("Label").text
	carousel.visible = false
	get_parent().get_node("left").visible = false
	get_parent().get_node("right").visible = false
	get_parent().get_node("start_race").visible = false
	
	#call spawn from main
	get_tree().change_scene_to_file("res://scenes/map_selection.tscn")
