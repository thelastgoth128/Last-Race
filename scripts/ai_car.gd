extends CharacterBody3D

# Godot Steering AI Framework components
var agent  # The GSAI agent that represents this car
var acceleration := GSAITargetAcceleration.new()  # Stores linear and angular acceleration
var priority: GSAIPriority  # Priority-based steering behavior combiner
var follow_behavior: GSAIFollowPath  # Behavior for following the racing path

# Physics and movement parameters
@export var speed_max := 20.0  # Maximum speed the car can reach
@export var acceleration_max := 10.0  # How fast the car can accelerate
@export var angular_speed_max := 10.0  # Max rotation speed (degrees/sec)
@export var angular_acceleration_max := 10.0  # How fast rotation can change
@export var steering_limit = 5.0  # Maximum steering angle (degrees)
@export var slip_speed := 9.0  # Speed at which drifting begins
@export var traction_slow := 0.75  # Traction when not drifting (higher = more grip)
@export var traction_fast := 0.02  # Traction when drifting (lower = more slip)
@export var gravity := -20.0  # Gravity force applied to the car

# Car state tracking
var drifting := false  # Whether the car is currently drifting
var current_path_index := 0  # Index of the nearest waypoint on the path
var look_ahead_distance := 5.0  # How far ahead to look for path points
var overtaking_target: Node = null  # Reference to the car being overtaken

# Track and path references
var track_scene: PackedScene = Global.selected_track  # The selected race track
var track_instance: Node = track_scene.instantiate()  # Instantiated track scene
@onready var path_node : Path3D = track_instance.get_node("AIPath")  # Main racing path
@onready var branch_a_path: Path3D = track_instance.get_node("AIPath/BranchA")  # Branch A path
@onready var branch_b_path: Path3D = track_instance.get_node("AIPath/BranchB")  # Branch B path

# Branching system variables
var main_path : Path3D = null  # Reference to the main path
var current_active_path: Path3D = null  # Currently active path (main or branch)
var is_on_branch := false  # Whether the car is currently on a branch
var chosen_branch : String = ""  # Which branch was chosen ("A" or "B")

# AI State machine - defines what the car is doing
enum AIState { IDLE,FOLLOW,RECOVER,OVERTAKE, CORNER,BRANCH }

var current_state: AIState = AIState.IDLE  # Current AI state
var race_started := false  # Whether the race has begun
var steer_angle := 0.0  # Current steering angle (for visual wheel rotation)
var stuck_timer := 0.0  # How long the car has been stuck
var stuck_threshold = 2.0  # Seconds of being stuck before recovery
var last_checkpoint: Area3D  # Last checkpoint crossed (for respawn)
var next_checkpoint: Area3D

# Timing and speed control
var avoid_cooldown := 0.0  # Cooldown timer for avoiding state
var avoid_cooldown_time := 0.3  # How long to stay in avoid state minimum
var speed_ramp_time := 3.0  # Time to ramp from slow start to full speed
var current_speed_multiplier := 0.3  # Current speed multiplier (0.3 = 30%)
var speed_ramp_timer := 0.0  # Tracks progress of speed ramp-up


func _ready():
	# Add this car to the AI group for detection by other cars
	add_to_group("AI")
	
	# Connect to global signals
	SignalBus.connect("Go", Callable(self, "_on_go_signal"))  # Race start signal
	SignalBus.connect("branch_entry_triggered", Callable(self,"_on_branch_entry_triggered"))  # Branch entry
	SignalBus.connect("branch_exit_triggered", Callable(self, "_on_branch_exit_triggered"))  # Branch exit
	SignalBus.connect("checkpoint_crossed", Callable(self, "_on_checkpoint_crossed"))

	# Initialize race state
	race_started = true  # Set to true for testing without countdown
	current_state = AIState.FOLLOW
	set_physics_process(false)  # Disabled until race starts
	
	# Store reference to main path
	main_path = path_node
	current_active_path = main_path
	
	# Create the GSAI steering agent (async operation)
	agent = await GSAICharacterBody3DAgent.new(self)
	
	# Configure agent properties
	agent.linear_speed_max = speed_max * 0.1  # Start slow (overwritten below)
	agent.linear_speed_max = speed_max  # Set to max speed
	agent.linear_acceleration_max = acceleration_max
	agent.angular_speed_max = deg_to_rad(angular_speed_max)  # Convert degrees to radians
	agent.angular_acceleration_max = deg_to_rad(angular_acceleration_max)
	agent.bounding_radius = 0.5  # Collision radius for avoidance
	
	# Setup steering behaviors for the main path
	setup_path_following(path_node)

func setup_path_following(target_path: Path3D):
	# Extract all waypoints from the path curve
	var waypoints := []
	for i in target_path.curve.get_point_count():
		waypoints.append(target_path.curve.get_point_position(i))

	# Create GSAI path from waypoints
	var path := GSAIPath.new(waypoints)
	
	# Create path following behavior
	follow_behavior = GSAIFollowPath.new(agent, path, 1.5, 0.5)

	# Build list of other AI agents for collision avoidance
	var agent_list := []
	for node in get_tree().get_nodes_in_group("AI"):
		if node != self and node.has_method("get_steering_agent"):
			agent_list.append(node.get_steering_agent())

	# Create proximity system for detecting nearby cars
	var proximity := GSAIRadiusProximity.new(agent, agent_list, 4.0)
	
	# Create collision avoidance behavior
	var avoid := GSAIAvoidCollisions.new(agent, proximity)
	avoid.proximity = GSAIRadiusProximity.new(agent, agent_list, 3.0)
	
	# Combine all behaviors in priority order
	priority = GSAIPriority.new(agent)
	priority.add(avoid) 
	priority.add(follow_behavior)  

# Called when car enters a branch entry zone
func _on_branch_entry_triggered(car:Node):
	if car != self:
		return  # Ignore if signal is for another car
	
	# Randomly choose which branch to take
	var choice = choose_branch()
	
	# Switch to the chosen branch path
	if choice == "A" and branch_a_path:
		switch_to_path(branch_a_path)
		chosen_branch = "A"
	elif choice == "B" and branch_b_path:
		switch_to_path(branch_b_path)
		chosen_branch = "B"
	else:
		return  # Branch doesn't exist, stay on current path
	
	# Update state
	is_on_branch = true
	current_state = AIState.BRANCH

# Called when car exits a branch and rejoins main path
func _on_branch_exit_triggered(car: Node):
	if car != self:
		return  # Ignore if signal is for another car
	
	# Return to main path
	switch_to_path(main_path)
	is_on_branch = false
	chosen_branch = ""
	current_state = AIState.FOLLOW

# Randomly choose between branch A and B
func choose_branch() -> String:
	if randf() > 0.5:
		return "A"
	else:
		return "B"

# Switch the car to follow a different path
func switch_to_path(new_path: Path3D):
	if not is_inside_tree() or not new_path.is_inside_tree():
		return

	current_active_path = new_path
	path_node = new_path

	var nearest_index = 0
	var min_dist = INF

	for i in range(new_path.curve.get_point_count()):
		var point = new_path.curve.get_point_position(i)
		var point_global = new_path.to_global(point)
		var dist = global_position.distance_to(point_global)

		if dist < min_dist:
			min_dist = dist
			nearest_index = i

	current_path_index = nearest_index
	setup_path_following(new_path)


# Called when this car crosses a checkpoint
func _on_checkpoint_crossed(body:Node, current:Area3D, _next: Area3D):
	if body == self:
		# Store the last checkpoint for respawning
		last_checkpoint = current

# Called when the race starts (Go signal)
func _on_go_signal():
	race_started = true
	current_state = AIState.FOLLOW
	set_physics_process(true)  # Enable physics processing
	
	# Reset speed ramp 
	speed_ramp_timer = 0.0
	current_speed_multiplier = 0.3

func _physics_process(delta):
	# Apply gravity when not on ground
	if not is_on_floor():
		velocity.y += gravity
	
	# Decrease cooldown timers
	if avoid_cooldown > 0:
		avoid_cooldown -= delta
	
	# Gradually increase speed from 30% to 100% over 3 seconds
	if race_started and speed_ramp_timer < speed_ramp_time:
		speed_ramp_timer += delta
		var ramp_progress = clamp(speed_ramp_timer / speed_ramp_time, 0.0, 1.0)
		current_speed_multiplier = lerp(0.3, 1.0, ramp_progress)
	
	# Update which waypoint we're closest to
	update_path_index()
	# Check if car is stuck
	update_stuck_timer(delta)
	# Determine which state to be in
	check_transitions()
	
	# Execute behavior based on current state
	match current_state:
		AIState.IDLE:
			# Car is stopped, not racing
			acceleration.linear = Vector3.ZERO
			acceleration.angular = 0.0
			velocity = velocity.lerp(Vector3.ZERO, 0.1)
			
		AIState.FOLLOW:
			# Normal racing: follow the path
			priority.calculate_steering(acceleration)
			agent.linear_speed_max = speed_max * current_speed_multiplier
			
		AIState.BRANCH:
			# Following a branch path
			priority.calculate_steering(acceleration)
			agent.linear_speed_max = speed_max * current_speed_multiplier
		
		AIState.CORNER:
			# Approaching a corner: slow down
			priority.calculate_steering(acceleration)
			agent.linear_speed_max = speed_max * 0.3 * current_speed_multiplier
			
		AIState.RECOVER:
			# Car is stuck: respawn at next waypoint
			var next_index = wrapi(current_path_index + 1, 0, path_node.curve.get_point_count())
			var local_pos = path_node.curve.get_point_position(next_index)
			var global_pos = path_node.to_global(local_pos)
			# Teleport to next waypoint
			global_position = global_pos + Vector3.UP * 1.0
			velocity = Vector3.ZERO
			current_path_index = next_index
			# Return to normal racing
			current_state = AIState.FOLLOW
			speed_ramp_timer = 0.0
			current_speed_multiplier = 0.5  # Start at half speed after recovery
			
		AIState.OVERTAKE:
			# Passing another car: move to the side and speed up
			priority.calculate_steering(acceleration)
			
			# Apply lateral force to move sideways
			var side_direction = global_transform.basis.x  # Right direction
			var overtake_offset = side_direction * 10.0
			acceleration.linear += overtake_offset.normalized() * acceleration_max 
			
			# Speed boost for overtaking
			agent.linear_speed_max = speed_max * 1.5
			
	# Align car with ground slope
	if $FrontRay.is_colliding() or $RearRay.is_colliding():
		# Get ground normals from raycasts
		var nf = $FrontRay.get_collision_normal() if $FrontRay.is_colliding() else Vector3.UP
		var nr = $RearRay.get_collision_normal() if $RearRay.is_colliding() else Vector3.UP
		var n = ((nr + nf) / 2.0).normalized()  # Average normal
		
		# Align car's up vector with ground normal
		var xform = align_with_y(global_transform, n)
		global_transform = global_transform.interpolate_with(xform, 0.1)
		
		# Check if on track
		var hit = $FrontRay.get_collider()
		if hit == null:
			hit = $RearRay.get_collider()
		
		var on_track = hit and hit.is_in_group("track")
		if not on_track:
			# Off track: reduce acceleration
			agent.linear_acceleration_max = acceleration_max * 0.5
	
	# Apply the calculated steering (moves and rotates the car)
	agent._apply_steering(acceleration, delta)
	
	# Additional manual steering adjustments
	apply_steering_rotation()

# Check if there's space to overtake on either side
func can_overtake() -> bool:
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	
	# Get left and right directions relative to car
	var right_dir = -global_transform.basis.x
	var left_dir = global_transform.basis.x
	
	var check_distance = 2.0 
	
	# Cast ray to the right
	var right_check = from + right_dir * check_distance
	var right_query = PhysicsRayQueryParameters3D.create(from, right_check)
	right_query.exclude = [self]
	right_query.collision_mask = 1
	var right_result = space_state.intersect_ray(right_query)
	
	# Cast ray to the left
	var left_check = from + left_dir * check_distance
	var left_query = PhysicsRayQueryParameters3D.create(from, left_check)
	left_query.exclude = [self]
	left_query.collision_mask = 1
	var left_result = space_state.intersect_ray(left_query)
	
	# Determine if each side is clear
	var right_clear = not right_result or not right_result.has("collider")
	var left_clear = not left_result or not left_result.has("collider")
	
	# Can overtake if at least one side is clear
	return right_clear or left_clear

# Find the nearest waypoint to the car's current position
func update_path_index():
	var curve = path_node.curve
	var min_dist = INF
	var nearest_idx = current_path_index
	
	# Search nearby waypoints 
	var search_range = 5
	for offset in range(-search_range, search_range + 1):
		var idx = wrapi(current_path_index + offset, 0, curve.get_point_count())
		var point = curve.get_point_position(idx)
		var dist = global_position.distance_squared_to(point)
		
		if dist < min_dist:
			min_dist = dist
			nearest_idx = idx
	# Update current path position
	current_path_index = nearest_idx

# Determine which state the car should be in
func check_transitions():
	# Race start/stop handling
	if race_started and current_state == AIState.IDLE:
		current_state = AIState.FOLLOW
		return
	
	if not race_started and current_state != AIState.IDLE:
		current_state = AIState.IDLE
		return
	
	# Branch-specific transitions
	if current_state == AIState.BRANCH:
		if is_stuck():
			current_state = AIState.RECOVER
		if is_approaching_corner():
			current_state = AIState.CORNER
		return
	
	# Stuck handling
	if is_stuck() and current_state == AIState.IDLE:
		current_state = AIState.FOLLOW
		
	if is_stuck():
		current_state = AIState.RECOVER
		return
	
	# Overtaking logic: can trigger from FOLLOW, CORNER, or AVOID
	var slow_car = detect_slow_car_ahead()
	
	if current_state in [AIState.FOLLOW, AIState.CORNER] and slow_car:
		# Only overtake if there's space
		if can_overtake():
			current_state = AIState.OVERTAKE
			overtaking_target = slow_car
			#print(name, " Starting overtake of ", slow_car.name)
			return
	# Exit overtake when we've passed the car
	if current_state == AIState.OVERTAKE:
		if overtaking_target == null or global_position.distance_to(overtaking_target.global_position) > 8.0:
			current_state = AIState.FOLLOW
			overtaking_target = null
			#print(name, " Overtake complete!")
			return	
	# Corner detection
	if current_state == AIState.FOLLOW and is_approaching_corner():
		current_state = AIState.CORNER
		return
	if current_state == AIState.CORNER and not is_approaching_corner():
		current_state = AIState.FOLLOW
		return

# Track how long the car has been moving slowly
func update_stuck_timer(delta):
	# Don't check before race starts
	if not race_started:
		stuck_timer = 0.0
		return
	var speed = velocity.length()
	# Increment timer if moving slowly
	if speed < 2.0:
		stuck_timer += delta
	else:
		# Reset timer if moving normally
		stuck_timer = 0.0
		
# Check if car has been stuck long enough to trigger recovery
func is_stuck() -> bool:
	return stuck_timer >= stuck_threshold
	
# Detect slower cars ahead that could be overtaken using rays infornt of the car mid left and right
func detect_slow_car_ahead() -> Node:
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var forward = -global_transform.basis.z.normalized()
	
	# Cast 3 forward-facing rays: center, right-diagonal, left-diagonal
	var ray_length = 15.0
	
	# Center forward ray
	var center_to = from + forward * ray_length
	
	# Right-forward diagonal (30 degrees right)
	var right = -global_transform.basis.x.normalized()
	var right_forward_to = from + (forward + right * 0.3).normalized() * ray_length
	
	# Left-forward diagonal (30 degrees left)
	var left = global_transform.basis.x.normalized()
	var left_forward_to = from + (forward + left * 0.3).normalized() * ray_length
	
	# Create ray queries
	var center_query = PhysicsRayQueryParameters3D.create(from, center_to)
	var right_query = PhysicsRayQueryParameters3D.create(from, right_forward_to)
	var left_query = PhysicsRayQueryParameters3D.create(from, left_forward_to)
	
	# Exclude self from detection
	center_query.exclude = [self]
	right_query.exclude = [self]
	left_query.exclude = [self]
	
	# Set collision masks
	center_query.collision_mask = 1
	right_query.collision_mask = 1
	left_query.collision_mask = 1
	# Cast all rays
	var results = [space_state.intersect_ray(center_query),space_state.intersect_ray(right_query),space_state.intersect_ray(left_query)]
	# Check each result for slower cars
	for result in results:
		if result and result.has("collider"):
			var collider = result["collider"]
			if collider.is_in_group("AI") or collider.is_in_group("Player"):
				if collider is CharacterBody3D:
					var my_speed = velocity.length()
					var their_speed = collider.velocity.length()
					
					# Return car if we're faster by at least 1.0 units
					if my_speed > their_speed + 1.0:
						return collider
	return null

# Additional rotation and traction handling (had a hard time using lookwhereyougo and face from the framework added manual)
func apply_steering_rotation():
	if agent == null or priority == null:
		return
		
	if velocity.length() > 0.1:
		# Rotate car to face velocity direction
		var target_dir = velocity.normalized()
		var current_dir = global_transform.basis.z.normalized()
		var angle = current_dir.signed_angle_to(target_dir, Vector3.UP)
		var rotation_step = clamp(angle, deg_to_rad(-steering_limit), deg_to_rad(steering_limit))
		rotate_y(rotation_step)
		# Apply traction (blend velocity towards forward direction)
		var traction = traction_fast if drifting else traction_slow
		var forward_velocity = -global_transform.basis.z * velocity.length()
		var blended_velocity = velocity.lerp(forward_velocity, traction)
		velocity = blended_velocity


# Check if the path ahead has a sharp turn represented as a corner
func is_approaching_corner(threshold_angle := deg_to_rad(5.0)) -> bool:
	var curve = path_node.curve
	var point_count = curve.get_point_count()
	
	if point_count < 3:
		return false  # Need at least 3 points to detect a corner
	
	var look_ahead_points = 3  # Check next 3 waypoints
	
	# Check each set of 3 consecutive waypoints
	for i in range(1, look_ahead_points):
		# Get indices of 3 consecutive waypoints ahead
		var idx1 = wrapi(current_path_index + i, 0, point_count)
		var idx2 = wrapi(current_path_index + i + 1, 0, point_count)
		var idx3 = wrapi(current_path_index + i + 2, 0, point_count)
		
		# Get waypoint positions
		var p1 = curve.get_point_position(idx1)
		var p2 = curve.get_point_position(idx2)
		var p3 = curve.get_point_position(idx3)
		
		# Calculate direction vectors
		var dir1 = (p2 - p1).normalized()
		var dir2 = (p3 - p2).normalized()
		
		# Calculate angle between directions
		var angle = dir1.angle_to(dir2)
		
		# If angle exceeds threshold, it's a corner
		if angle > threshold_angle:
			return true
	return false

# Align a transform's Y-axis with a given direction (for ground alignment) code from kidscancode
func align_with_y(xform, new_y):
	xform.basis.y = new_y  # Set up direction
	xform.basis.x = -xform.basis.z.cross(new_y)  # Recalculate right direction
	xform.basis = xform.basis.orthonormalized()  # Ensure orthonormal basis
	return xform
