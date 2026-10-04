extends Node

signal state_changed(new_state)
signal hands_updated
signal round_ended(result:String, payout:float)
signal table_toggled(opened_by: String)

const BET_PERCENT := 0.1 # fraction of current hp wagered each round
const RESULT_DISPLAY_SECONDS := 1.5

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
	elif opened_by == player_id:
		opened_by = ""
	else:
		return
	table_toggled.emit(opened_by)

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
	bet = PlayerStats.consume_percent(opened_by, BET_PERCENT)
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

	if player_value > 21:
		result = "bust"
	elif dealer_blackjack and player_blackjack:
		result = "push"
		payout = bet #(draw)
	elif player_blackjack:
		result = "blackjack"
		payout = bet + bet * 1.5
	elif dealer_blackjack:
		result = "dealer blackjack"
	elif dealer_value > 21 or player_value > dealer_value:
		result = "you win"
		payout = bet * 2
	elif player_value == dealer_value:
		result = "push"
		payout = bet #(draw)
	else:
		result = "dealer wins"

	PlayerStats.add_hp(opened_by, payout)
	round_ended.emit(result, payout)
	_schedule_auto_leave()

func _schedule_auto_leave() -> void:
	var closing_for := opened_by
	await get_tree().create_timer(RESULT_DISPLAY_SECONDS).timeout
	if opened_by == closing_for and state == State.ROUND_OVER:
		opened_by = ""
		table_toggled.emit("")
