extends Control

@onready var countdown_label = $CountdownLabel
@onready var timer_panel = $Panel
@onready var on_pause = $"../GamePaused"
@onready var sound = $CountdownSound

var countdown_time = 3
var countdown_active = false


func _ready():
	on_pause.visible = false
	
func start_countdown() -> void:
	SignalBus.emit_signal("start_race")
	countdown_active = true
	countdown_label.text = "3"
	set_process(true)
	

func _process(delta):
	if countdown_active:
		countdown_time -= delta
		if countdown_time > 2:
			sound.play()
			countdown_label.text = "3"
		elif countdown_time > 1:
			sound.play()
			countdown_label.text = "2"
		elif countdown_time > 0:
			sound.play()
			countdown_label.text = "1"
		else:
			countdown_label.text = "GO!"
			countdown_active = false
			
			await get_tree().create_timer(1.0).timeout
			countdown_label.visible = false
			#print("emitting signal")
			SignalBus.emit_signal("Go")
			#print("siganl emitted")
			timer_panel.visible = true
			timer_panel.set_process(true)
			set_process(false)


func _on_pause_pressed() -> void:
	on_pause.visible = true
