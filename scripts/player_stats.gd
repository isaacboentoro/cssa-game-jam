extends Node

signal hp_changed(player_id: String, hp: float)
signal drain_rate_changed(rate: float)
signal match_lost(player_id: String)

const STARTING_HP := 100.0
const PLAYER_IDS := ["p1", "p2"]
const BASE_DRAIN_RATE := 1.0 # hp/sec
const DRAIN_RAMP_INTERVAL := 30.0 # seconds between ramps
const DRAIN_RAMP_AMOUNT := 1.0 # hp/sec added per ramp
const LOSS_SCENE := "res://scenes/loss_screen.tscn"

var _hp: Dictionary = {}
var drain_rate := BASE_DRAIN_RATE
var last_loser_id := ""

var _drain_accumulator := 0.0
var _ramp_accumulator := 0.0
var _match_over := false

func _process(delta: float) -> void:
	if _match_over:
		return

	_ramp_accumulator += delta
	while _ramp_accumulator >= DRAIN_RAMP_INTERVAL:
		_ramp_accumulator -= DRAIN_RAMP_INTERVAL
		drain_rate += DRAIN_RAMP_AMOUNT
		drain_rate_changed.emit(drain_rate)

	_drain_accumulator += delta
	while _drain_accumulator >= 1.0:
		_drain_accumulator -= 1.0
		_apply_drain_tick()

func _apply_drain_tick() -> void:
	for player_id in PLAYER_IDS:
		add_hp(player_id, -drain_rate)
	for player_id in PLAYER_IDS:
		if get_hp(player_id) <= 0.0:
			_end_match(player_id)
			return

func _end_match(loser_id: String) -> void:
	_match_over = true
	last_loser_id = loser_id
	match_lost.emit(loser_id)
	get_tree().change_scene_to_file(LOSS_SCENE)

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

## Resets HP, drain rate, and match state for a fresh match.
func reset() -> void:
	_hp.clear()
	drain_rate = BASE_DRAIN_RATE
	last_loser_id = ""
	_drain_accumulator = 0.0
	_ramp_accumulator = 0.0
	_match_over = false
	drain_rate_changed.emit(drain_rate)
