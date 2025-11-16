extends Label

func _ready():
	visible = false
	SignalBus.connect("start_race", Callable(self, "_on_start_race_pressed"))

func _on_start_race_pressed() -> void:
	visible = true
	
