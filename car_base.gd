extends CharacterBody3D
signal change_camera

#Car behavior parameters, adjust as needed
@export var gravity = -20.0
@export var wheel_base = 0.6 # distance betweeen front/rear axies
@export var steering_limit = 10.0 # front wheel max turning angle(deg)
@export var engine_power = 20.0
@export var braking = -9.0
@export var friction = -2.0
@export var drag = -2.0
@export var max_speed_reverse = 3.0
@export var slip_speed = 9.0
@export var traction_slow =0.75
@export var traction_fast = 0.02

var drifting = false
# Car state properties
var acceleration = Vector3.ZERO # current acceleration
#var velocity = Vector3.ZERO #current velocity already in the characterBody3D
var steer_angle = 0.0 # current wheel angle

func _physics_process(delta):
	if is_on_floor():
		get_input()
		apply_friction(delta)
		calculate_steering(delta)
	acceleration.y = gravity
	velocity += acceleration * delta
	move_and_slide()
	
	#if either wheel is in the air, align to slope
	if $FrontRay.is_colliding() or $RearRay.is_colliding():
		#if one wheel is in air, move it down
		var nf = $FrontRay.get_collision_normal() if $FrontRay.is_colliding() else Vector3.UP
		var nr = $RearRay.get_collision_normal() if $RearRay.is_colliding() else Vector3.UP
		var n = ((nr + nf) / 2.0).normalized()
		var xform = align_with_y(global_transform, n)
		global_transform = global_transform.interpolate_with(xform, 0.1) 

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var fricition_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + fricition_force
	
func calculate_steering(delta):
	var rear_wheel = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel = transform.origin - transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(transform.basis.y, steer_angle) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)
	
	#traction
	if not drifting and velocity.length() > slip_speed:
		drifting = true
	if drifting and velocity.length() < slip_speed and steer_angle == 0:
		drifting = false
	var traction = traction_fast if drifting else traction_slow
	
	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = lerp(velocity, new_heading * velocity.length(), traction)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	look_at(transform.origin + new_heading, transform.basis.y)
	
func get_input():
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg_to_rad(steering_limit)
	$"sedan-sports/wheel-front-right".rotation.y = steer_angle * 2
	$"sedan-sports/wheel-front-left".rotation.y = steer_angle * 2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking
		
#Cars camera position
var current_camera = 0
@onready var num_cameras = $CameraPositions.get_child_count()

func _ready():
	emit_signal("change_camera",$CameraPositions.get_child((current_camera)))
	
func _input(event):
	if event.is_action_pressed("change_camera"):
		current_camera = wrapi(current_camera + 1, 0, num_cameras)
		emit_signal("change_camera",$CameraPositions.get_child(current_camera))

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
