extends Area3D

signal lap_crossed(body: Node, lap: int)

@export var checkpoint_index: int  = -1
@export var next_checkpoint: Area3D

var lap_counts := {}

func _ready():
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	add_to_group("Checkpoints") # add checpoint to group 

# chech the car  that passed and emits signal lap crossed with the body all handled in the race manager
func _on_body_entered(body):
	if body.is_in_group("AI") or body.is_in_group("Player"):
		SignalBus.emit_signal("checkpoint_crossed",body,self,next_checkpoint)
		# Increment lap count for tracking (internal to finish line)
		var current_lap = lap_counts.get(body, 0) + 1
		lap_counts[body] = current_lap
		
		# Emit signal - RaceManager will validate if lap should count
		lap_crossed.emit(body, current_lap)
		SignalBus.emit_signal("lap_crossed", body, current_lap)
		
		#print(body.name, " crossed finish line (attempt ", current_lap, ")")
