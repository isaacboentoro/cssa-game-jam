extends Node

signal state_changed(new_state)
signal hands_updated
signal round_ended(result:String, payout:float)
signal table_toggled(opened_by: String)

const RESULT_DISPLAY_SECONDS := 1.5

# House rules tilted toward the player.
const PLAYER_WINS_TIES := true # standard casino: ties push
const FIVE_CARD_CHARLIE := true # 5 cards without busting wins outright

# Payouts are total hp returned as a multiple of the bet (bet was already deducted).
const WIN_RETURN := 2 # standard casino: 2.0
const BLACKJACK_RETURN := 3.0 # standard casino: 2.5
const PUSH_RETURN := 1.0
const LOSS_RETURN := -1.0 # refund on bust/loss; standard casino: 0.0

var opened_by := ""

enum State { BETTING, PLAYER_TURN, DEALER_TURN, ROUND_OVER }

var state := State.BETTING
var deck := Deck.new(6)
var player_hand: Array = []
var dealer_hand: Array = []
var bet := 0.0

func toggle_table(player_id: String) -> void:
	if opened_by == "":
		opened_by = player_id
		_reset_round()
		table_toggled.emit(opened_by)
	elif opened_by == player_id:
		_leave_table()
	# else: table occupied by other player, ignore

func _leave_table() -> void:
	opened_by = ""
	table_toggled.emit("")

func _reset_round() -> void:
	player_hand = []
	dealer_hand = []
	bet = 0.0
	_set_state(State.BETTING)
	hands_updated.emit()


func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)

func place_bet() -> void:
	if state != State.BETTING or opened_by == "":
		return
	bet = 10
	_deal_initial()
	
func _deal_initial() -> void:
	player_hand = [deck.draw(), deck.draw()]
	dealer_hand = [deck.draw(), deck.draw()]
	
	hands_updated.emit()
	_set_state(State.PLAYER_TURN)
	
	var player_blackjack := deck.is_blackjack(player_hand)
	var dealer_blackjack := deck.is_blackjack(dealer_hand)

	if player_blackjack or dealer_blackjack:
		_resolve()


func hit() -> void:
	if state != State.PLAYER_TURN:
		return

	player_hand.append(deck.draw())
	hands_updated.emit()
	var v := Deck.hand_value(player_hand)

	if v > 21:
		_resolve() #cooked
	elif FIVE_CARD_CHARLIE and player_hand.size() >= 5:
		_resolve()
	elif v == 21:
		stand()


func stand() -> void:
	if state != State.PLAYER_TURN:
		return
	_set_state(State.DEALER_TURN)
	_dealer_play()
	
func _dealer_play() -> void:
	while Deck.hand_value(dealer_hand) < 17:
		dealer_hand.append(deck.draw())
		hands_updated.emit()
		
	_resolve()
	

		
	
func _resolve() -> void:
	_set_state(State.ROUND_OVER)
	var player_value := Deck.hand_value(player_hand)
	var dealer_value := Deck.hand_value(dealer_hand)
	var player_blackjack := deck.is_blackjack(player_hand)
	var dealer_blackjack := deck.is_blackjack(dealer_hand)
	
	var result := ""
	var payout := 0.0

	var tie_return: float = 0 #WIN_RETURN if PLAYER_WINS_TIES else PUSH_RETURN
	var tie_result: String = "tie - you win" if PLAYER_WINS_TIES else "push"

	if player_value > 21:
		result = "bust"
		payout = bet * LOSS_RETURN
	elif FIVE_CARD_CHARLIE and player_hand.size() >= 5:
		result = "five card charlie"
		payout = bet * WIN_RETURN
	elif dealer_blackjack and player_blackjack:
		result = tie_result
		payout = bet * tie_return
	elif player_blackjack:
		result = "blackjack"
		payout = bet * BLACKJACK_RETURN
	elif dealer_blackjack:
		result = "dealer blackjack"
		payout = bet * LOSS_RETURN
	elif dealer_value > 21 or player_value > dealer_value:
		result = "you win"
		payout = bet * WIN_RETURN
	elif player_value == dealer_value:
		result = tie_result
		payout = bet * tie_return
	else:
		result = "dealer wins"
		payout = bet * LOSS_RETURN

	PlayerStats.add_hp(opened_by, payout)
	round_ended.emit(result, payout)
	_schedule_auto_leave()

func _schedule_auto_leave() -> void:
	var closing_for := opened_by
	await get_tree().create_timer(RESULT_DISPLAY_SECONDS).timeout
	if opened_by == closing_for and state == State.ROUND_OVER:
		_leave_table()
