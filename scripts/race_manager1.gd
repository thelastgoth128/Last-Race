extends Node3D

@onready var race_positions_label = get_node("/root/Main/GameInterface/RacePositions")
@onready var laps_label = get_node("/root/Main/GameInterface/Panel2/Laps")
@onready var time_panel = get_node("/root/Main/GameInterface/Panel")
@onready var time_elapsed_label = get_node("/root/Main/GameInterface/Gameover/TimeElapsed")
@onready var game_over_label = get_node("/root/Main/GameInterface/Gameover/Gameover")
@onready var position_label = get_node("/root/Main/GameInterface/Gameover/Position")


var player_car : CharacterBody3D
var race_position = []
var checkpoint_progress := {}  # car → [checkpoint indices passed]
var lap_counts := {}  # car → lap number
var total_checkpoints := 7
var total_laps := 3
var next_checkpoint_map := {}


func set_player(car_instance: CharacterBody3D):
	player_car = car_instance
	lap_counts[player_car] = 0
	checkpoint_progress[player_car] = []

func add_ai_car(car: CharacterBody3D):
	lap_counts[car] = 0
	checkpoint_progress[car] = []


func _ready():
	SignalBus.connect("Race_finished", Callable(self, "_on_race_finished"))
	SignalBus.connect("checkpoint_crossed", Callable(self, "_on_checkpoint_crossed"))
	SignalBus.connect("race_position_updated", Callable(self,"_on_race_position_updated"))
	
	SignalBus.connect("lap_crossed", Callable(self, "_on_finish_line_crossed"))
	# Initialize cars
	for car in get_tree().get_nodes_in_group("AI"):
		lap_counts[car] = 0
		checkpoint_progress[car] = []
	
	if player_car:
		lap_counts[player_car] = 0
		checkpoint_progress[player_car] = []

func _on_checkpoint_crossed(body: Node, current: Area3D, next: Area3D):
	# Don't disable monitoring - we need checkpoints active for all laps!
	# current.monitoring stays true
	
	var index = current.checkpoint_index
	
	if current.name == "FinishLine":
		next_checkpoint_map[body] = next
		return
		
	# Initialize progress tracking for this car if needed
	if not checkpoint_progress.has(body):
		checkpoint_progress[body] = []
	
	var progress = checkpoint_progress[body]
	
	# Only add checkpoint if not already in progress (prevent double-counting)
	if index not in progress:
		progress.append(index)
		checkpoint_progress[body] = progress
		#print(body.name, " crossed checkpoint ", index, " (", progress.size(), "/", total_checkpoints, ")")
		#print(body.name, " crossed checkpoint ", index, " (", progress.size(), "/", total_checkpoints, ")")
	else:
		pass
		#print(body.name, " already passed checkpoint ", index)
	
	next_checkpoint_map[body] = next
	
	update_race_positions()
	
	
func _on_finish_line_crossed(body: Node, _lap: int):
	#print(body.name, " crossed finish line!")
	# Check if car has passed all checkpoints
	if not checkpoint_progress.has(body):
		checkpoint_progress[body] = []
	
	var progress = checkpoint_progress[body]
	#print("   Progress array contents: ", progress)  # ← See what's in it
	#print("   Progress size: ", progress.size(), "/", total_checkpoints)
	
	# Only count lap if all checkpoints were passed
	if progress.size() >= total_checkpoints:
		# Increment lap
		lap_counts[body] = lap_counts.get(body, 0) + 1
		var current_lap = lap_counts[body]
		#print("current_lap", current_lap)
		#print(body.name, " completed lap ", current_lap)
		
		# Reset checkpoint progress for next lap
		checkpoint_progress[body] = []
		
		# Emit lap completed signal
		#SignalBus.emit_signal("lap_completed", body, current_lap)
		#
		# Update UI if it's the player
		if body == player_car:
			#print("Player completed lap:", current_lap) debug
			if current_lap <= total_laps:
				laps_label.text = "Lap: %d/%d" % [current_lap, total_laps]
		
		# Check if race is finished
		if current_lap > total_laps:
			if body == player_car:
				SignalBus.emit_signal("Race_finished",body)
			_on_race_finished(body)
	else:
		pass
		#print(body.name, " crossed finish line but only passed ", progress.size(), "/", total_checkpoints, " checkpoints")debug

func _on_race_finished(car: Node):
	#print("Race finished for:", car.name) debug
	
	# Add to race position if not already there
	if not race_position.has(car):
		race_position.append(car)
		#print(car.name, " finished in position ", race_position.size()) debug
	
	# Show results if it's the player
	if car == player_car:
		show_results()

func get_distance_to_next_checkpoint(car: Node):
	var next_checkpoint = next_checkpoint_map.get(car)
	if next_checkpoint == null:
		return INF
	return car.global_transform.origin.distance_to(next_checkpoint.global_transform.origin)
	

func update_race_positions():
	var racers = lap_counts.keys()

	racers.sort_custom(func(a, b):
		var lap_a = lap_counts.get(a, 0)
		var lap_b = lap_counts.get(b, 0)
		if lap_a != lap_b:
			return lap_a > lap_b  # higher lap ranks first

		var cp_a = checkpoint_progress.get(a, []).size()
		var cp_b = checkpoint_progress.get(b, []).size()
		if cp_a != cp_b:
			return cp_a > cp_b  # more checkpoints ranks first

		var next_cp = next_checkpoint_map.get(a)
		var dist_a = INF
		
		if next_cp != null:
			dist_a = a.global_transform.origin.distance_to(next_cp.global_transform.origin)
			
		var next_cp_b = next_checkpoint_map.get(b)
		var dist_b = INF

		if next_cp_b != null:
			dist_b = b.global_transform.origin.distance_to(next_cp_b.global_transform.origin)

		return dist_a < dist_b  # shorter distance ranks higher
	)

	race_position = racers
	SignalBus.emit_signal("race_position_updated", race_position)


func _on_race_position_updated(position_list: Array):
	#print("🏁 Race position updated:", position_list)
	var display := ""
	for i in range (position_list.size()):
		var car = position_list[i]
		display += "%d. %s\n" % [i + 1, car.name]
	#print("RacePositions node:", race_positions_label) debug

	race_positions_label.text = display
	#print(display) debug
	
	
func show_results():
	#print("Showing results") debug
	var car_position = race_position.find(player_car) + 1
	var total_time = time_panel.get_time()
	#print("Player time:", total_time) debug
	position_label.text = "Position: %s" % car_position
	time_elapsed_label.text = "Time Elapsed: %s" % total_time
	game_over_label.visible = true  # Make sure to show the game over screen
