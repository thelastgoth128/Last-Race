extends Panel

## code is from the link: https://www.youtube.com/watch?v=M-0UNa8M5bE

var time: float = 0.0
var minutes: int = 0
var seconds: int = 0
var msec: int = 0

func _ready() -> void:
	visible = false
	set_process(false)
	SignalBus.connect("Race_finished", Callable(self, "race_finished_time")) # signal to stop tie when the race is finished
	
func _process(delta) -> void:
	time += delta 
	msec = int(fmod(time, 1) * 100)
	seconds = int(fmod(time, 60))
	minutes = int(fmod(time, 3600) / 60)
	$Minutes.text = "%02d:" % minutes
	$Seconds.text = "%02d." % seconds
	$Msecs.text = "%03d" % msec
	
func get_time_formatted() -> String:
	return "%02d:%02d.%03d" % [minutes, seconds, msec]

var finished_time

func race_finished_time(_car: Node):
	set_process(false)
	finished_time = "%02d:%02d.%03d" % [minutes, seconds, msec]
	
func get_time():
	return finished_time


func _on_start_race_pressed() -> void:
	visible = true
