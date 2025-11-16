extends Area3D

#signal to make AI follow normal path on the track
func _on_body_entered(body):
	if body.is_in_group("AI"):
		SignalBus.emit_signal("branch_exit_triggered", body)
		#print("Junction: BRanch Point")
