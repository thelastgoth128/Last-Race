extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	SignalBus.connect("start_race", Callable(self, "_on_start_race_pressed"))
	SignalBus.connect("Race_finished", Callable(self, "_on_race_finished"))

func _on_race_finished(_car: Node):
	visible = false
# shows icon when the race starts
func _on_start_race_pressed() -> void:
	visible = true
