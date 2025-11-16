extends Button




func _on_pressed() -> void:
	visible = false
	Music.stop()
	


func _on_music_on_pressed() -> void:
	visible = true
