extends Node

signal hp_changed(player_id: String, hp: float)

const STARTING_HP := 100.0

var _hp: Dictionary = {}

func get_hp(player_id: String) -> float:
	return _hp.get(player_id, STARTING_HP)

func add_hp(player_id: String, amount: float) -> void:
	var hp: float = max(0.0, get_hp(player_id) + amount)
	_hp[player_id] = hp
	hp_changed.emit(player_id, hp)

## Deducts `percent` (0-1) of the player's current hp and returns the amount deducted.
func consume_percent(player_id: String, percent: float) -> float:
	var amount := get_hp(player_id) * percent
	add_hp(player_id, -amount)
	return amount
