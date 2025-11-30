extends Control

@onready var base = $JoystickBase
@onready var knob = $JoystickKnob

var dragging := false
var start_pos := Vector2.ZERO

func _ready():
	SignalBus.connect("Race_finished", Callable(self, "_on_race_finished"))

func _on_race_finished(_car: Node):
	visible = false


# handle sposition of the knob and base when clicked or dragged
func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
			start_pos = event.position 
		else:
			dragging = false
			knob.position = base.position + base.size * 0.7 - knob.size * 0.7
			SignalBus.emit_signal("joystick_moved", Vector2.ZERO)

	elif event is InputEventScreenDrag and dragging:
		var max_distance := 80.0
		var offset: Vector2 = event.position - start_pos

		if offset.length() > max_distance:
			offset = offset.normalized() * max_distance

		knob.position = base.position + base.size * 0.7 - knob.size * 0.7 + offset

		var direction := Vector2(offset.x / max_distance, 0.0)
		SignalBus.emit_signal("joystick_moved", direction)
