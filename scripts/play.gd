extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

func _on_pause_pressed() -> void:
	visible = true


func _on_pressed() -> void:
	visible = false
	
