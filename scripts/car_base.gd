extends CharacterBody3D
signal change_camera(target: CharacterBody3D)

# Most of the code is from  https://kidscancode.org/godot_recipes/3.x/3d/kinematic_car/car_base/index.html 
#Made adjustment to meet my implementation

#Car behavior parameters
@export var gravity = -20.0
@export var wheel_base = 0.6 # distance betweeen front/rear axies
@export var steering_limit = 5.0 # front wheel max turning angle(deg)
@export var engine_power = 20.0
@export var braking = -9.0
@export var friction = -2.0
@export var drag = -2.0
@export var max_speed_reverse = 3.0
@export var slip_speed = 9.0
@export var traction_slow =0.75
@export var traction_fast = 0.02
@onready var accelerate_button = $"../GameInterface/Acceralation"
@onready var brake_button = $"../GameInterface/Brake"

#input variables for the joystic
var is_touching_accelerating := false
var is_touching_braking := false
var steering_input := 0.0
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
	var speed = velocity.length()
	var speed_kmh = speed * 3.6 
	SignalBus.emit_signal("Speed", speed_kmh)
	
	#if either wheel is in the air, align to slope
	if $FrontRay.is_colliding() or $RearRay.is_colliding():
		#if one wheel is in air, move it down
		var nf = $FrontRay.get_collision_normal() if $FrontRay.is_colliding() else Vector3.UP
		var nr = $RearRay.get_collision_normal() if $RearRay.is_colliding() else Vector3.UP
		var n = ((nr + nf) / 2.0).normalized()
		var xform = align_with_y(global_transform, n)
		global_transform = global_transform.interpolate_with(xform, 0.1) 
		
		var hit = $FrontRay.get_collider()
		if hit == null:
			hit = $RearRay.get_collider()
			
		var on_track = hit and hit.is_in_group("track")
		if on_track :
			return
		else:
			traction_fast * 0.2
			engine_power * 0.5

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var fricition_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + fricition_force
	
func calculate_steering(delta):
	#steer_angle = deg_to_rad(steering_input * steering_limit)
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
	if d > 0 and velocity.length() > 0.1:
		velocity = lerp(velocity, new_heading * velocity.length(), traction)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	look_at(transform.origin + new_heading, transform.basis.y)
	
func get_input():
	var turn = Input.get_action_strength("steer_left") 
	turn -= Input.get_action_strength("steer_right")
	var target_steer = turn * deg_to_rad(steering_limit) 
	steer_angle = lerp(steer_angle, target_steer,0.1) 
	$"sedan-sports/wheel-front-right".rotation.y = steer_angle * 2 
	$"sedan-sports/wheel-front-left".rotation.y = steer_angle * 2 
	acceleration = Vector3.ZERO 
	if Input.is_action_pressed("accelerate") or is_touching_accelerating:
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake") or is_touching_braking: 
		acceleration = -transform.basis.z * braking
		


#Cars camera position
var current_camera = 0
var last_checkpoint : Area3D
@onready var num_cameras = $CameraPositions.get_child_count()

func _ready():
	connect_checkpoints()
	set_physics_process(false)
	SignalBus.connect("Race_finished",Callable(self, "_on_race_finished")) # signal from race manager
	SignalBus.connect("steering_changed", Callable(self, "_on_steering_changed")) # signal from joystic
	SignalBus.connect("joystick_moved", Callable(self, "_on_joystick_moved")) # signal to change the car steer
	SignalBus.connect("Go",Callable(self, "_on_go")) # go signal to  enable physics
	accelerate_button.connect("button_down", Callable(self, "_on_accelerate_pressed")) #signal to accelerate the car 
	accelerate_button.connect("button_up", Callable(self, "_on_accelerate_released")) # signal releasing acceleration
	brake_button.connect("button_down", Callable(self,"_on_brake_pressed")) # button to brake the car
	brake_button.connect("button_up", Callable(self, "_on_brake_released")) # button brake released
	

# function that changes the car steering from the joystic input
func _on_steering_changed(value: float):
	steering_input = value
	
	# function that accelerates the car
func _on_accelerate_pressed():
	is_touching_accelerating = true
	#print("Accelerate button pressed") debug
	
	# slowing down
func _on_accelerate_released():
	is_touching_accelerating = false
	#print("Accelerate button released") debug
	
	#func to brake the car and starts to reverse
func _on_brake_pressed():
	is_touching_braking = true
	
	#stops reversing
func _on_brake_released():
	is_touching_braking = false
	
	#signal to stop the car physics
func _on_race_finished(car: Node):
	set_physics_process(false)
	
	#passing body to checkpoints
func connect_checkpoints():
	for checkpoint in get_tree().get_nodes_in_group("Checkpoints"):
		checkpoint.connect("checkpoint_crossed", Callable(self, "_on_checkpoint_crossed"))
	
func _on_checkpoint_crossed(body:Node, current:Area3D, next: Area3D):
	if body == self:
		last_checkpoint = current
		#print(name, " crossed checkpoint: ", current.name) debug
	
func _on_joystick_moved(direction: Vector2):
	steering_input = -direction.x

#starts the car physics
func _on_go():
	print("Go signal received")
	set_physics_process(true)
	
# connecting to chase camera in main
func _emit_camera_signal():
	emit_signal("change_camera", $CameraPositions.get_child(current_camera))
	
# passing the target camera for the car
func _input(event):
	if event.is_action_pressed("change_camera"):
		current_camera = wrapi(current_camera + 1, 0, num_cameras)
		emit_signal("change_camera",$CameraPositions.get_child(current_camera))

#align to ground
func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
