extends Node

signal hp_changed(player_id: String, hp: float)
signal drain_rate_changed(rate: float)
signal bet_percent_changed(percent: float)
signal match_lost(player_id: String)

const STARTING_HP := 99.0
const PLAYER_IDS := ["p1", "p2"]
const BASE_DRAIN_RATE := 1.0 # hp/sec
const DRAIN_RAMP_INTERVAL := 30.0 # seconds between ramps
const DRAIN_RAMP_AMOUNT := 1.0 # hp/sec added per ramp
const BASE_BET_PERCENT := 0.1 # fraction of current hp wagered per minigame round
const BET_RAMP_AMOUNT := 0.01 # added to bet_percent per ramp
const MAX_BET_PERCENT := 1.0
const LOSS_SCENE := "res://scenes/loss_screen.tscn"

var _hp: Dictionary = {}
var drain_rate := BASE_DRAIN_RATE
var bet_percent := BASE_BET_PERCENT
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
		bet_percent = min(bet_percent + BET_RAMP_AMOUNT, MAX_BET_PERCENT)
		bet_percent_changed.emit(bet_percent)

	_apply_drain_tick(delta)

func _apply_drain_tick(amount: float) -> void:
	amount *= drain_rate
	for player_id in PLAYER_IDS:
		add_hp(player_id, -amount)
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
	add_hp(player_id, percent)
	return percent

## Resets HP, drain rate, and match state for a fresh match.
func reset() -> void:
	_hp.clear()
	drain_rate = BASE_DRAIN_RATE
	bet_percent = BASE_BET_PERCENT
	last_loser_id = ""
	_drain_accumulator = 0.0
	_ramp_accumulator = 0.0
	_match_over = false
	drain_rate_changed.emit(drain_rate)
	bet_percent_changed.emit(bet_percent)
