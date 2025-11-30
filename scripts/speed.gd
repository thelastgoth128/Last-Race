extends Label

func _ready():
	visible =  false
	SignalBus.connect("Speed", Callable(self, "_on_speed_updated"))
	SignalBus.connect("Go",Callable(self, "_on_go"))
	SignalBus.connect("Race_finished", Callable(self, "_on_race_finished"))

func _on_race_finished(_car: Node):
	visible = false

func _on_speed_updated(speed: float):
	$".".text = "Speed: %.1f km/h" % speed
	


func _on_go():
	visible = true
