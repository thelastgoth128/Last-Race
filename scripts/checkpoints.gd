extends Area3D

signal checkpoint_crossed(body: Node, current: Area3D, next: Area3D)

@export var checkpoint_index: int = 0  
@export var next_checkpoint: Area3D


func _ready():
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered")) 
	add_to_group("Checkpoints") # add all checkpoints to group

#emits signal checkpoint crossed handled by the racemanger by the car that passed
func _on_body_entered(body):
	if body.is_in_group("AI") or body.is_in_group("Player"):
		checkpoint_crossed.emit(body, self, next_checkpoint)
		# Always emit - let RaceManager handle duplicate detection
		SignalBus.emit_signal("checkpoint_crossed", body, self, next_checkpoint)
		#print(body.name, " entered checkpoint ", checkpoint_index) debug
