extends Node

signal state_changed(new_state)
signal hands_updated
signal round_ended(result:String, payout:int)

enum State { BETTING, PLAYER_TURN, DEALER_TURN, ROUND_OVER }

var state := State.BETTING
var deck := Deck.new(6)
var player_hand: Array = []
var dealer_hand: Array = []
var chips := 1000
var bet := 0

func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)
	
func place_bet(amount:int) -> void:
	if state != State.BETTING or amount <= 0 or amount > chips:
		return
	bet = amount
	amount -= chips
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
	var payout := 0
	
	if player_value > 21:
		result = "bust"
	if dealer_blackjack and player_blackjack:
		result = "push"
		payout = bet #(draw)
	elif player_blackjack:
		result = "blackjack"
		payout = bet + int(bet * 1.5)
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
		
	chips += payout
	round_ended.emit(result, payout)
	

	
	

	
