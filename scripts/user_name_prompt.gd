extends Control

@onready var name_input = $LineEdit
@onready var confirm_button = $Button
#Gets the user's desired Name for the game
func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed():
	var username = name_input.text.strip_edges()
	if username != "":
		var config = ConfigFile.new()
		config.set_value("player", "username", username)
		config.save("user://player.cfg")
		get_tree().change_scene_to_file("res://scenes/home.tscn")
