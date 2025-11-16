extends Node

var selected_car: String = "Suv" # default car if none is selected
var selected_track
var player_name

#stores the scene of the car
var car_scenes = {
	"Suv": preload("res://scenes/vehicle_3.tscn"),
	"Race_future" : preload("res://scenes/Vehicle2.tscn"),
	"Sedan" : preload("res://scenes/Vehicle.tscn"),
	"hatchback_sports" : preload("res://scenes/Vehicle4.tscn"),
	"Race_formula" : preload("res://scenes/vehicle_5.tscn")
}
