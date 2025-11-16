extends Node

#scene variables
@onready var pause_button = $GameInterface/Pause
@onready var resume_button = $GamePaused/OnPause/Resume
@onready var restart_button = $GamePaused/OnPause/Restart
@onready var quit_button = $GamePaused/OnPause/Quit
@onready var sound = $GamePaused/OnPause/Click2Sound
@onready var on_pause_panel = $GamePaused
@onready var gameinterface = $GameInterface

#roat scene initialization and instantiation
var road_scene = Global.selected_track
var road_instance = road_scene.instantiate()

# initialization of varibales
func _ready():
	#print("Main scene ready")
	pause_button.connect("pressed", Callable(self, "_on_pause_pressed"))
	resume_button.connect("pressed", Callable(self,"_on_resume_pressed"))
	restart_button.connect("pressed", Callable(self, "_on_restart_pressed"))
	quit_button.connect("pressed", Callable(self,"_on_quit_pressed"))
	gameinterface.start_countdown()
	spawn_selected_track()
	spawn_selected_car()

	
func _on_pause_pressed():
	get_tree().paused = true
	
func _on_resume_pressed():
	sound.play()
	get_tree().paused = false
	on_pause_panel.visible = false
	
func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/home.tscn")
	
func _on_restart_pressed():
	sound.play()
	get_tree().paused = false
	get_tree().reload_current_scene()
	on_pause_panel.visible = false

# spawn the selected track on the main scene
func spawn_selected_track():
	add_child(road_instance) #add child to scene

#spawn the selected car into the main scene
func spawn_selected_car():
	var car_key = Global.selected_car
	var car_scene = Global.car_scenes.get(car_key, null)
	
	if car_scene and car_scene is PackedScene:
		var car_instance = car_scene.instantiate() # instantiate the car
		
		var spawn_pos =  road_instance.get_node("SpawnPos") # position the car on the race track
		car_instance.global_transform = spawn_pos.global_transform
		#print("spawn position",car_instance.global_transform) debug
		Music.stop()
		add_child(car_instance) # add child to scene
		
		# add player to group
		car_instance.add_to_group("Player")
		car_instance.name = Global.player_name #give the player name entered from the prompts screen
		#print(car_instance) debug
		
		#pass the body of the player to the race manager for checpoint management
		var race_manager = road_instance.get_node("RaceManager")
		race_manager.set_player(car_instance)
		
		# Connect the signal to the camera
		car_instance.connect("change_camera",Callable($ChaseCamera, "_on_change_camera"))
		car_instance.call_deferred("_emit_camera_signal")
		
	else:
		push_error("Car scene not found for key:" + str(car_key))
