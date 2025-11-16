extends Node

#Global signal for the game
signal Go
signal Race_finished(car: Node)
signal Speed(speed: float)
signal lap_crossed(body: Node, lap: int)
signal checkpoint_crossed(body: Node, current: Area3D, next: Area3D)
signal lap_completed(body: Node, lap: int)
signal race_position_updated(position_list: Array)
signal steering_changed(angle: float)
signal start_race
signal joystick_moved(direction: Vector2)
signal branch_entry_triggered(car)
signal branch_exit_triggered(car)
