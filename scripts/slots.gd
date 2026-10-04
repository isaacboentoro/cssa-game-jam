extends Node

# Unlike Blackjack/Roulette (one shared table), slots keep one session per
# player so both players can spin at different machines at the same time.
# Which machine a player is using is tracked by slots_area.gd, not here.

signal table_toggled(player_id: String, is_open: bool)
signal state_changed(player_id: String, new_state)
signal spin_result(player_id: String, reels: Array)
signal round_ended(player_id: String, result: String, payout: float)

const RESULT_DISPLAY_SECONDS := 1.5
const REEL_COUNT := 3

# Total hp returned as a multiple of the bet (bet was already deducted).
# Tuned to roughly +9% expected value per spin.
const SAME_SUIT_RETURN := 3.75 # ~25% chance (only 2 suits)
const SAME_RANK_RETURN := 20.0 # ~0.4% chance
const IDENTICAL_RETURN := 50.0 # same rank and suit, ~0.15% chance

enum State { BETTING, SPINNING, ROUND_OVER }

# player_id -> {"state": State, "bet": float, "reels": Array[Dictionary]}
var _sessions: Dictionary = {}

func is_open(player_id: String) -> bool:
	return _sessions.has(player_id)

func get_state(player_id: String) -> State:
	return _sessions[player_id].state if is_open(player_id) else State.BETTING

func get_bet(player_id: String) -> float:
	return _sessions[player_id].bet if is_open(player_id) else 0.0

func open(player_id: String) -> void:
	if is_open(player_id):
		return
	_sessions[player_id] = {"state": State.BETTING, "bet": 0.0, "reels": []}
	table_toggled.emit(player_id, true)
	state_changed.emit(player_id, State.BETTING)

func close(player_id: String) -> void:
	if not is_open(player_id):
		return
	_sessions.erase(player_id)
	table_toggled.emit(player_id, false)

func _set_state(player_id: String, s: State) -> void:
	_sessions[player_id].state = s
	state_changed.emit(player_id, s)

func place_bet(player_id: String) -> void:
	if get_state(player_id) != State.BETTING or not is_open(player_id):
		return
	var session: Dictionary = _sessions[player_id]
	session.bet = PlayerStats.consume_percent(player_id, PlayerStats.bet_percent)
	session.reels = []
	for i in REEL_COUNT:
		session.reels.append(random_card())
	_set_state(player_id, State.SPINNING)
	# Outcome is decided now so the UI can animate towards it; payout waits for finish_spin().
	spin_result.emit(player_id, session.reels)

static func random_card() -> Dictionary:
	return {"suit": Deck.SUITS.pick_random(), "rank": Deck.RANKS.pick_random()}

static func card_texture_path(card: Dictionary) -> String:
	return "res://assets/Cards/Card_" + str(card.suit) + str(card.rank) + ".png"

## Call this once the reel animation has finished landing on the result.
func finish_spin(player_id: String) -> void:
	if not is_open(player_id) or get_state(player_id) != State.SPINNING:
		return
	var session: Dictionary = _sessions[player_id]
	var reels: Array = session.reels
	var same_suit := _all_match(reels, "suit")
	var same_rank := _all_match(reels, "rank")

	var result := "lose"
	var payout := 0.0
	if same_suit and same_rank:
		result = "jackpot!"
		payout = session.bet * IDENTICAL_RETURN
	elif same_rank:
		result = "same number!"
		payout = session.bet * SAME_RANK_RETURN
	elif same_suit:
		result = "same suit!"
		payout = session.bet * SAME_SUIT_RETURN

	PlayerStats.add_hp(player_id, payout)
	_set_state(player_id, State.ROUND_OVER)
	round_ended.emit(player_id, result, payout)
	_schedule_auto_leave(player_id)

static func _all_match(reels: Array, key: String) -> bool:
	for card in reels:
		if card[key] != reels[0][key]:
			return false
	return true

func _schedule_auto_leave(player_id: String) -> void:
	await get_tree().create_timer(RESULT_DISPLAY_SECONDS).timeout
	if is_open(player_id) and get_state(player_id) == State.ROUND_OVER:
		close(player_id)
