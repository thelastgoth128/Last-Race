extends Label

func _ready():
	visible = false
	SignalBus.connect("Race_finished", Callable(self, "_show_game_over"))
	
func _show_game_over(car: Node):
	visible =  true
	
