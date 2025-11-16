extends Control

@onready var music_toggle = $CheckBox
@onready var back_button = $Button
@onready var music_player = Music

# toogle to turn the music off

func _ready():
	music_toggle.connect("toggled", Callable(self, "_on_music_toggled"))
	back_button.connect("pressed", Callable(self, "_on_back_pressed"))
	music_toggle.button_pressed = music_player.playing

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/home.tscn")
	
func _on_music_toggled(button_pressed: bool):
	if button_pressed:
		music_player.play()
	else:
		music_player.stop()
