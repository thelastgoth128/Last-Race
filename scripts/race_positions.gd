extends Label

func _ready():
	visible = false
	SignalBus.connect("start_race", Callable(self, "_on_start_race_pressed"))
	SignalBus.connect("Race_finished", Callable(self, "_on_race_finished"))

func _on_race_finished(car: Node):
	visible = false


func _on_start_race_pressed() -> void:
	visible = true
