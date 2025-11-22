extends Node

@warning_ignore_start("unused_signal")
signal game_started
signal game_won
signal player_killed

signal talisman_activated
signal talisman_picked_up

signal rice_thrown(pos: Vector3)
signal rice_picked_up

signal entered_danger_zone
signal entered_safe_zone

signal exited_safe_zone
signal exited_danger_zone

signal sensitivity_changed(value: float)
