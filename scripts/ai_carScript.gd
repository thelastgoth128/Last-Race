extends "res://scripts/car_base.gd"


func get_input():
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg_to_rad(steering_limit)
	$"truck/wheel-front-right".rotation.y = steer_angle * 2
	$"truck/wheel-front-left".rotation.y = steer_angle * 2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking
