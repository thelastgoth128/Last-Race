extends Node

# handles AI scenee loading the spawn position and racemanger add
func spawn_ai_car():
	var ai_car = preload("res://scenes/ai_car.tscn").instantiate()
	var sedan = preload("res://scenes/sedan1.tscn").instantiate()
	var police = preload("res://scenes/policeAI.tscn").instantiate()
	
	ai_car.global_transform = $Truck1Spot.global_transform
	sedan.global_transform = $Sedan1.global_transform
	police.global_transform = $policeAI.global_transform
	
	add_child(ai_car)
	add_child(sedan)
	add_child(police)
	
	ai_car.add_to_group("AI")
	sedan.add_to_group("AI")
	police.add_to_group("AI")
	
	$"../RaceManager".add_ai_car(ai_car)
	$"../RaceManager".add_ai_car(sedan)
	$"../RaceManager".add_ai_car(police)
	

func _ready():
	spawn_ai_car()
