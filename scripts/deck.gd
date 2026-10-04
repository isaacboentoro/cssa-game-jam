class_name Deck
extends RefCounted
const SUITS := ["Y_", "B_",]
const RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var cards: Array[Dictionary] = []
var num_decks := 1

func _init(decks: int = 1) -> void:
	num_decks = decks
	rebuild()
	

func rebuild() -> void:
	cards.clear()
	for d in num_decks:
		for suit in SUITS:
			for rank in RANKS:
				cards.append({"rank": rank, "suit": suit})
	cards.shuffle()
	
func draw() -> Dictionary:
	if cards.size() < 15:
		rebuild()
	return cards.pop_back()
	
	
static func card_value(card:Dictionary) -> int:
	match card.rank:
		"A": return 11
		"J", "Q", "K": return 10
		_: return int(card.rank)
		

static func hand_value(hand: Array) -> int:
	var total := 0
	var aces := 0
	for card in hand:
		total += card_value(card)
		if card.rank == "A":
			aces += 1
		
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
		
	return total
	
func is_blackjack(hand) -> bool: #Special case (instant win)
	return hand.size() == 2 and hand_value(hand) == 21
		
