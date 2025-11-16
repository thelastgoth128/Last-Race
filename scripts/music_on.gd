extends Button

func _ready():
	visible = false

func _on_pressed() -> void:
	visible = false
	Music.play()


func _on_music_off_pressed() -> void:
	visible = true
