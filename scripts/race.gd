extends "res://scripts/car_base.gd"


func get_input():
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg_to_rad(steering_limit)
	$"race/wheel-front-right".rotation.y = steer_angle * 2
	$"race/wheel-front-left".rotation.y = steer_angle * 2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate") or is_touching_accelerating:
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake") or is_touching_braking:
		acceleration = -transform.basis.z * braking


func _on_area_3d_body_entered(body: Node3D) -> void:
	var checkpoint_count = -1
	var checkpoint_pos = self.global_position
	if body == $Vehicle4:
		checkpoint_count += 1
		print(checkpoint_count)
