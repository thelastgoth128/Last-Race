extends Button
#navigation button
func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map_selection.tscn")
