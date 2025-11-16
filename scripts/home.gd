extends Control

@onready var options = $TextureRect3/Options
@onready var credits = $TextureRect3/Credits

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Music.play()
	var config = ConfigFile.new()
	var err = config.load("user://player.cfg")
	if err != OK or not config.has_section_key("player", "username"):
		get_tree().change_scene_to_file("res://scenes/user_name_prompt.tscn")
	else:
		var username = config.get_value("player", "username")
		$Label.text = username
		Global.player_name = username
		
	options.connect("pressed", Callable(self, "_on_options_clicked"))
	credits.connect("pressed", Callable(self,"_on_credit_clicked"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_options_clicked():
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_credit_clicked():
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
	
func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/car_selection.tscn")
