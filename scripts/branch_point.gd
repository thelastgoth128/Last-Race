extends Area3D

# signal to enable AI make decision on branch
func _on_body_entered(body):
	if body.is_in_group("AI") :
		SignalBus.emit_signal("branch_entry_triggered", body)
