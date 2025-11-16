extends "res://scripts/car_base.gd"


func get_input():
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg_to_rad(steering_limit)
	$"hatchback-sports/wheel-front-right".rotation.y = steer_angle * 2
	$"hatchback-sports/wheel-front-left".rotation.y = steer_angle * 2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate") or is_touching_accelerating:
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake") or is_touching_braking:
		acceleration = -transform.basis.z * braking
