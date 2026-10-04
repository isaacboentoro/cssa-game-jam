extends Control

@export var player_id := "p1"

@onready var felt: ColorRect = $Felt
@onready var dealer_cards: HBoxContainer = $TableBox/DealerArea/DealerCards
@onready var dealer_value: Label = $TableBox/DealerArea/DealerCards/DealerValue
@onready var player_cards: HBoxContainer = $TableBox/PlayerArea/PlayerCards
@onready var player_value: Label = $TableBox/PlayerArea/PlayerCards/PlayerValue
@onready var hp_label: Label = $TableBox/InfoArea/ChipsLabel
@onready var bet_label: Label = $TableBox/InfoArea/BetLabel
@onready var result_label: Label = $TableBox/InfoArea/ResultLabel
@onready var action_hint_1: HBoxContainer = $TableBox/InfoArea/ActionHint1
@onready var action_hint_2: HBoxContainer = $TableBox/InfoArea/ActionHint2
@onready var deal_button: Button = $TableBox/Controls/DealButton
@onready var hit_button: Button = $TableBox/Controls/HitButton
@onready var stand_button: Button = $TableBox/Controls/StandButton

@export var action1_icon: Texture2D
@export var action2_icon: Texture2D

var _action1 := ""
var _action2 := ""

const SUIT_SYMBOL := {"hearts": "♥", "diamonds": "♦", "clubs": "♣", "spades": "♠"}

func _ready() -> void:
	visible = false
	felt.visible = false
	$TableBox/ColorRect
	_action1 = player_id + "_action1"
	_action2 = player_id + "_action2"
	if action1_icon: action_hint_1.icon = action1_icon
	if action2_icon: action_hint_2.icon = action2_icon
	if player_id == "p1":
		$interactionables/ACTION1.play("QCircGrey")
		$interactionables/ACTION2.play("ECircGrey")
	else:
		$interactionables/ACTION1.play("UCircGrey")
		$interactionables/ACTION2.play("OCircGrey")
	
	Blackjack.table_toggled.connect(_on_table_toggled)
	Blackjack.state_changed.connect(_on_state_changed)
	Blackjack.hands_updated.connect(_refresh_hands)
	Blackjack.round_ended.connect(_on_round_ended)
	PlayerStats.hp_changed.connect(_on_hp_changed)

	deal_button.pressed.connect(Blackjack.place_bet)
	hit_button.pressed.connect(Blackjack.hit)
	stand_button.pressed.connect(Blackjack.stand)

	_on_state_changed(Blackjack.state)
	_refresh_chips()

	

func _unhandled_input(event: InputEvent) -> void:
	if Blackjack.opened_by != player_id:
		return

	match Blackjack.state:
		Blackjack.State.BETTING:
			if 1==1:
				Blackjack.place_bet()
		Blackjack.State.PLAYER_TURN:
			if event.is_action_pressed(_action1):
				Blackjack.hit()
				if player_id == "p1":
					$interactionables/ACTION1.play("QCircGreen")
				else:
					$interactionables/ACTION1.play("UCircGreen")
			elif event.is_action_pressed(_action2):
				Blackjack.stand()
				if player_id == "p1":
					$interactionables/ACTION2.play("ECircGreen")
				else:
					$interactionables/ACTION2.play("OCircGreen")
			if event.is_action_released(_action1):
				if player_id == "p1":
					$interactionables/ACTION1.play("QCircGrey")
				else:
					$interactionables/ACTION1.play("UCircGrey")

func _on_table_toggled(opened_by: String) -> void:
	var show_table := opened_by == player_id
	visible = show_table
	felt.visible = show_table
	$LOSS.visible = false
	$JACKPOT.visible = false
	$PlusMinus.visible = false
	if player_id == "p1":
		$interactionables/ACTION1.play("QCircGrey")
		$interactionables/ACTION2.play("ECircGrey")
	else:
		$interactionables/ACTION1.play("UCircGrey")
		$interactionables/ACTION2.play("OCircGrey")

func _card_text(card: Dictionary) -> String:
	return "%s%s" % [card.rank, SUIT_SYMBOL.get(card.suit, "?")]

func _fill_hand(container: HBoxContainer, value_label: Label, hand: Array) -> void:
	for child in container.get_children():
		if child != value_label:
			child.queue_free()
	var card_offset = 120
	for card in hand:
		#var l := Label.new()
		#l.text = _card_text(card)
		#l.add_theme_font_size_override("font_size", 24)
		#container.add_child(l)
		#container.move_child(l, 0)
		var card_sprite = "res://assets/Cards/Card_" + str(card.suit) + str(card.rank)+ ".png" 
		var new_node = Sprite2D.new()
		new_node.texture = load(card_sprite)
		new_node.scale.x = 3
		new_node.scale.y = 3
		new_node.position.x = card_offset
		new_node.position.y = 20
		container.add_child(new_node)
		card_offset += 40



func _refresh_hands() -> void:
	_fill_hand(player_cards, player_value, Blackjack.player_hand)
	_fill_hand(dealer_cards, dealer_value, Blackjack.dealer_hand)
	player_value.text = "Player: %d" % Deck.hand_value(Blackjack.player_hand)
	dealer_value.text = "Dealer: %d" % Deck.hand_value(Blackjack.dealer_hand)
	_refresh_chips()

func _refresh_chips() -> void:
	hp_label.text = "HP: %d" % round(PlayerStats.get_hp(player_id))
	bet_label.text = "Bet: %d" % round(Blackjack.bet)

func _on_hp_changed(changed_player_id: String, _hp: float) -> void:
	if changed_player_id == player_id:
		_refresh_chips()

func _on_state_changed(state) -> void:
	var betting: bool = state == Blackjack.State.BETTING
	var player_turn: bool = state == Blackjack.State.PLAYER_TURN
	deal_button.disabled = not betting
	hit_button.disabled = not player_turn
	stand_button.disabled = not player_turn


func _on_round_ended(result: String, payout: float) -> void:
	result_label.text = "%s (payout %d)" % [result, round(payout)]
	$PlusMinus.visible = true
	if payout <= 0.0:
		$LOSS.visible = true
		$LOSS.play("default")
		$PlusMinus.play("Minus")
		$PlusMinus/Lightning.play("explodelong")
	else:
		$JACKPOT.visible = true
		$JACKPOT.play("default")
		$JACKPOT/JACKPOT.play("default")
		$PlusMinus.play("Plus")
		$PlusMinus/Lightning.play("flashinggreen")
	_refresh_chips()
