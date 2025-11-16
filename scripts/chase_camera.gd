extends Camera3D

# interpolation speed
@export var lerp_speed = 6.0

var target = null

# main physics loops interpolates to  from chase camera to car child
func _physics_process(delta):
	if !target:
		return
	global_transform = global_transform.interpolate_with(target.global_transform, lerp_speed * delta)

# connects to car's car child
func _on_change_camera(t) -> void:
	#print("ChaseCamera now following:", t) debug
	target = t

# debug for the AI car
#func _on_ai_car_change_camera(target: CharacterBody3D) -> void:
	#target = target
