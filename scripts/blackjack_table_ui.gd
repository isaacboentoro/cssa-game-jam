extends VBoxContainer

@onready var blackjack: Node = $Blackjack
@onready var dealer_cards: HBoxContainer = $Table/DealerArea/DealerCards
@onready var dealer_value: Label = $Table/DealerArea/DealerCards/DealerValue

@onready var player_cards: HBoxContainer = $Table/PlayerArea/PlayerCards
@onready var player_value: Label = $Table/PlayerArea/PlayerCards/PlayerValue

@onready var chips_label: Label = $Table/InfoArea/ChipsLabel
@onready var bet_label: Label = $Table/InfoArea/BetLabel
@onready var result_label: Label = $Table/InfoArea/ResultLabel

@onready var bet_input: SpinBox = $Table/Controls/BetInput
@onready var hit_button: Button = $Table/Controls/HitButton
@onready var stand_button: Button = $Table/Controls/StandButton

const SUIT_SYMBOL := {"hearts": "♥", "diamonds" :"♦", "clubs":"♣", "spades": "♠"}

func _ready() -> void:
	blackjack.state_changed(_on_state_changed)
	

func _refresh_hands() -> void:
	_fill_hand(player_cards, blackjack.player_hand)
	_fill_hand(dealer_cards, blackjack.dealer_hand)
	player_value.text = "Value: %d" % Deck.hand_value(blackjack.player_hand)
	dealer_value.text = "Value: %d" % Deck.hand_value(blackjack.dealer_hand)
	_refresh_chips()

func _refresh_chips() -> void:
	chips_label.text = "Chips: %d" % blackjack.chips
	bet_label.text = "Bet: %d" % blackjack.bet
	
func _card_text(card:Dictionary) -> String:
	return "%s%s" % [card.rank, SUIT_SYMBOL.get(card.suit, "?")]

func _fill_hand(container:HBoxContainer, hand:Array) -> void:
	for child in container.get_children():
		child.queue_free()
		for card in hand:
			var l := Label.new()
			l.text = _card_text(card)
			l.add_theme_font_size_override("font_size", 24)
			container.add_child(l)
			

func _on_state_changed(state) -> void:
	var betting :bool =  state == blackjack.State.BETTING
	var player_turn :bool  =  state == blackjack.State.PLAYER_TURN
	bet_input.editable = betting
	hit_button.disabled = not player_turn
	stand_button.disabled = not player_turn
	if betting:
		result_label.text = ""
		
func _on_round_ended(result: String, payout: int) -> void:
	result_label.text = "%s (payout %d)" % [result, payout]
	_refresh_chips()
