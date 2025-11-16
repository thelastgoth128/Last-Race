class_name RacerComparator
extends Object

var lap_counts
var checkpoint_progress
var next_checkpoint_map

func _init(_lap_counts, _checkpoint_progress, _next_checkpoint_map):
	lap_counts = _lap_counts
	checkpoint_progress = _checkpoint_progress
	next_checkpoint_map = _next_checkpoint_map

func less_than(a, b):
	var lap_a = lap_counts.get(a, 0)
	var lap_b = lap_counts.get(b, 0)
	if lap_a != lap_b:
		return lap_a < lap_b  # higher lap ranks first

	var cp_a = checkpoint_progress.get(a, []).size()
	var cp_b = checkpoint_progress.get(b, []).size()
	if cp_a != cp_b:
		return cp_a < cp_b  # more checkpoints ranks first

	var dist_a = a.global_transform.origin.distance_to(next_checkpoint_map.get(a, a.global_transform.origin))
	var dist_b = b.global_transform.origin.distance_to(next_checkpoint_map.get(b, b.global_transform.origin))
	return dist_a > dist_b  # shorter distance ranks first
