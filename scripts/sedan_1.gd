extends "res://scripts/ai_car.gd"

func calculate_ai_steering():
	var target_dir = agent.linear_velocity.normalized()
	var forward_dir = -global_transform.basis.z.normalized()
	var angle = forward_dir.signed_angle_to(target_dir, Vector3.UP)
	
	steer_angle = lerp(steer_angle, clamp(angle, deg_to_rad(-steering_limit), deg_to_rad(steering_limit)), 0.1)
	
	if has_node("sedan/wheel-front-right"):
		$"sedan/wheel-front-right".rotation.y = steer_angle * 0.4
	if has_node("sedan/wheel-front-left"):
		$"sedan/wheel-front-left".rotation.y = steer_angle * 0.4

	var speed = agent.linear_velocity.length()
	if not drifting and speed > slip_speed and abs(steer_angle) > deg_to_rad(steering_limit * 0.6):
		drifting = true
	elif drifting and (speed < slip_speed or abs(steer_angle) < deg_to_rad(steering_limit * 0.2)):
		drifting = false
