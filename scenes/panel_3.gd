extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("Race_finished",Callable(self, "_on_race_finished"))

func _on_race_finished(_car: Node):
	$".".visible = false
	
