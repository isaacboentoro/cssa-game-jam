extends Node

signal state_changed(new_state)
signal bets_updated
signal spin_result(number: int, color: String)
signal round_ended(result: String, payout: float)
signal table_toggled(opened_by: String)

const RED_NUMBERS := [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
const RESULT_DISPLAY_SECONDS := 1.5

enum State { BETTING, SPINNING, ROUND_OVER }
enum BetType { RED, BLACK, ODD, EVEN, LOW, HIGH, STRAIGHT }

var opened_by := ""
var state := State.BETTING

var bet := 0.0
var bet_type: BetType = BetType.RED
var bet_number := -1

var last_number := -1
var last_color := ""

func toggle_table(player_id: String) -> void:
	if opened_by == "":
		opened_by = player_id
		_reset_round()
	elif opened_by == player_id:
		opened_by = ""
	else:
		return
	table_toggled.emit(opened_by)

func _reset_round() -> void:
	bet = 0.0
	last_number = -1
	last_color = ""
	_set_state(State.BETTING)
	bets_updated.emit()

func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)

static func number_color(number: int) -> String:
	if number == 0:
		return "green"
	return "red" if RED_NUMBERS.has(number) else "black"

## Places a wager and immediately spins. `number` is only used for BetType.STRAIGHT.
func place_bet(type: BetType, number: int = -1) -> void:
	if state != State.BETTING or opened_by == "":
		return
	bet_type = type
	bet_number = number
	bet = PlayerStats.consume_percent(opened_by, PlayerStats.bet_percent)
	bets_updated.emit()
	_spin()

func _spin() -> void:
	_set_state(State.SPINNING)
	last_number = randi() % 37
	last_color = number_color(last_number)
	# The outcome is decided now so the UI can animate towards it, but nothing
	# is paid out until the UI calls finish_spin() once its animation lands.
	spin_result.emit(last_number, last_color)

## Call this once the spin animation has finished landing on the result.
func finish_spin() -> void:
	if state != State.SPINNING:
		return
	var payout := _calculate_payout()
	PlayerStats.add_hp(opened_by, payout)
	_set_state(State.ROUND_OVER)
	var outcome := "win" if payout > 0 else "lose"
	round_ended.emit("%s (%d %s)" % [outcome, last_number, last_color], payout)
	_schedule_auto_leave()

func _schedule_auto_leave() -> void:
	var closing_for := opened_by
	await get_tree().create_timer(RESULT_DISPLAY_SECONDS).timeout
	if opened_by == closing_for and state == State.ROUND_OVER:
		opened_by = ""
		table_toggled.emit("")

func _calculate_payout() -> float:
	var win := false
	var multiplier := 1.0
	match bet_type:
		BetType.RED:
			win = last_color == "red"
		BetType.BLACK:
			win = last_color == "black"
		BetType.ODD:
			win = last_number != 0 and last_number % 2 == 1
		BetType.EVEN:
			win = last_number != 0 and last_number % 2 == 0
		BetType.LOW:
			win = last_number >= 1 and last_number <= 18
		BetType.HIGH:
			win = last_number >= 19 and last_number <= 36
		BetType.STRAIGHT:
			win = last_number == bet_number
			multiplier = 35.0

	if not win:
		return 0.0
	return bet + bet * multiplier
