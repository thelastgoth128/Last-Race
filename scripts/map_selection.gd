extends Control

func _on_button_pressed() -> void:
	Global.selected_track = preload("res://scenes/racing_road.tscn")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_button_2_pressed() -> void:
	Global.selected_track = preload("res://scenes/track_2.tscn")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
