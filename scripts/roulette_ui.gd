extends Control

@export var player_id := "p1"
@export var action_name := "p1_action2"

const SPIN_DURATION := 1.2
const SPIN_TICK := 0.08

@onready var felt: ColorRect = $Felt
@onready var spin_label: Label = $RouletteBox/Wheel/SpinLabel
@onready var hp_label: Label = $RouletteBox/InfoArea/HpLabel
@onready var bet_label: Label = $RouletteBox/InfoArea/BetLabel
@onready var result_label: Label = $RouletteBox/InfoArea/ResultLabel

@onready var red_button: Button = $RouletteBox/Controls/OutsideBets/RedButton
@onready var black_button: Button = $RouletteBox/Controls/OutsideBets/BlackButton
@onready var odd_button: Button = $RouletteBox/Controls/OutsideBets/OddButton
@onready var even_button: Button = $RouletteBox/Controls/OutsideBets/EvenButton
@onready var low_button: Button = $RouletteBox/Controls/OutsideBets/LowButton
@onready var high_button: Button = $RouletteBox/Controls/OutsideBets/HighButton

@onready var straight_number_input: SpinBox = $RouletteBox/Controls/StraightBets/StraightNumberInput
@onready var straight_button: Button = $RouletteBox/Controls/StraightBets/StraightButton

var _bet_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	felt.visible = false

	_bet_buttons = [red_button, black_button, odd_button, even_button, low_button, high_button, straight_button]

	Roulette.table_toggled.connect(_on_table_toggled)
	Roulette.state_changed.connect(_on_state_changed)
	Roulette.spin_result.connect(_on_spin_result)
	Roulette.round_ended.connect(_on_round_ended)
	PlayerStats.hp_changed.connect(_on_hp_changed)

	red_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.RED))
	black_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.BLACK))
	odd_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.ODD))
	even_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.EVEN))
	low_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.LOW))
	high_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.HIGH))
	straight_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.STRAIGHT, int(straight_number_input.value)))

	_on_state_changed(Roulette.state)
	_refresh_info()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(action_name):
		Roulette.toggle_table(player_id)

func _on_table_toggled(opened_by: String) -> void:
	var show_table := opened_by == player_id
	visible = show_table
	felt.visible = show_table

func _on_state_changed(state) -> void:
	var betting: bool = state == Roulette.State.BETTING
	for button in _bet_buttons:
		button.disabled = not betting
	if betting:
		result_label.text = ""
		spin_label.text = "—"

## Placeholder spin animation: cycles the label through random numbers until it
## lands on the predetermined result, then tells Roulette it's safe to pay out.
## Swap this for a real wheel/ball animation later — just call finish_spin()
## from whatever signal marks that animation as actually finished.
func _on_spin_result(number: int, color: String) -> void:
	var elapsed := 0.0
	while elapsed < SPIN_DURATION:
		spin_label.text = str(randi() % 37)
		await get_tree().create_timer(SPIN_TICK).timeout
		elapsed += SPIN_TICK
	spin_label.text = "%d %s" % [number, color.capitalize()]
	Roulette.finish_spin()

func _on_round_ended(result: String, payout: float) -> void:
	result_label.text = "%s (payout %d)" % [result, round(payout)]
	_refresh_info()

func _refresh_info() -> void:
	hp_label.text = "HP: %d" % round(PlayerStats.get_hp(player_id))
	bet_label.text = "Bet: %d" % round(Roulette.bet)

func _on_hp_changed(changed_player_id: String, _hp: float) -> void:
	if changed_player_id == player_id:
		_refresh_info()
