extends Control

@export var player_id := "p1"
@export var action1_icon: Texture2D
@export var action2_icon: Texture2D

const SPIN_DURATION := 1.2
const SPIN_TICK := 0.08

@onready var felt: ColorRect = $Felt
@onready var wheel_sprite: AnimatedSprite2D = $RouletteBox/WheelSprite
@onready var spin_label: Label = $RouletteBox/SpinLabel
@onready var hp_label: Label = $RouletteBox/InfoArea/HpLabel
@onready var bet_label: Label = $RouletteBox/InfoArea/BetLabel
@onready var result_label: Label = $RouletteBox/InfoArea/ResultLabel
@onready var action_hint_1: HBoxContainer = $RouletteBox/InfoArea/ActionHint1
@onready var action_hint_2: HBoxContainer = $RouletteBox/InfoArea/ActionHint2

@onready var red_button: Button = $RouletteBox/Controls/OutsideBets/RedButton
@onready var black_button: Button = $RouletteBox/Controls/OutsideBets/BlackButton

var _bet_buttons: Array[Button] = []
var _action1 := ""
var _action2 := ""

func _ready() -> void:
	visible = false
	felt.visible = false
	_action1 = player_id + "_action1"
	_action2 = player_id + "_action2"
	#if action1_icon: action_hint_1.icon = action1_icon
	#if action2_icon: action_hint_2.icon = action2_icon

	_bet_buttons = [red_button, black_button]

	Roulette.table_toggled.connect(_on_table_toggled)
	Roulette.state_changed.connect(_on_state_changed)
	Roulette.spin_result.connect(_on_spin_result)
	Roulette.round_ended.connect(_on_round_ended)
	PlayerStats.hp_changed.connect(_on_hp_changed)
	$JACKPOT.visible = false
	$LOSS.visible = false
	$PlusMinus.visible = false
	if player_id == "p1":
		$interactionables/ACTION1.play("QCircGrey")
		$interactionables/ACTION2.play("ECircGrey")
	else:
		$interactionables/ACTION1.play("UCircGrey")
		$interactionables/ACTION2.play("OCircGrey")

#	red_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.RED))
	#black_button.pressed.connect(func(): Roulette.place_bet(Roulette.BetType.BLACK))

	_on_state_changed(Roulette.state)
	_refresh_info()

func _unhandled_input(event: InputEvent) -> void:
	if Roulette.opened_by != player_id:
		return

	if Roulette.state != Roulette.State.BETTING:
		return

	if event.is_action_pressed(_action1):
		Roulette.place_bet(Roulette.BetType.RED)
	elif event.is_action_pressed(_action2):
		Roulette.place_bet(Roulette.BetType.BLACK)

func _on_table_toggled(opened_by: String) -> void:
	var show_table := opened_by == player_id
	visible = show_table
	felt.visible = show_table
	$JACKPOT.visible = false
	$LOSS.visible = false
	$PlusMinus.visible = false

func _on_state_changed(state) -> void:
	var betting: bool = state == Roulette.State.BETTING
	if betting:
		result_label.text = ""
		spin_label.text = "—"
#		action_hint_1.set_text("Bet Red")
#		action_hint_2.set_text("Bet Black")

#		action_hint_1.set_text("")
#		action_hint_2.set_text("")

func _on_spin_result(number: int, color: String) -> void:
	wheel_sprite.stop()
	var frame_count := wheel_sprite.sprite_frames.get_frame_count(wheel_sprite.animation)
	var tween := create_tween()
	tween.tween_method(_set_wheel_frame, 0.0, float(frame_count), SPIN_DURATION) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	while tween.is_running():
		spin_label.text = str(randi() % 37)
		await get_tree().create_timer(SPIN_TICK).timeout

	spin_label.text = "%d %s" % [number, color.capitalize()]
	Roulette.finish_spin()

func _set_wheel_frame(progress: float) -> void:
	var frame_count := wheel_sprite.sprite_frames.get_frame_count(wheel_sprite.animation)
	wheel_sprite.frame = posmod(int(progress), frame_count)

func _on_round_ended(result: String, payout: float) -> void:
	result_label.text = "%s (payout %d)" % [result, round(payout)]
	$PlusMinus.visible = true
	if result == "win":
		$JACKPOT.visible = true
		$JACKPOT.play("default")
		$PlusMinus.play("Plus")
		$PlusMinus/Lightning.play("flashinggreen")
	else:
		$LOSS.visible = true
		$LOSS.play("default")
		$PlusMinus.play("Minus")
		$PlusMinus/Lightning.play("explodelong")
	_refresh_info()

func _refresh_info() -> void:
	hp_label.text = "HP: %d" % round(PlayerStats.get_hp(player_id))
	bet_label.text = "Bet: %d" % round(Roulette.bet)

func _on_hp_changed(changed_player_id: String, _hp: float) -> void:
	if changed_player_id == player_id:
		_refresh_info()
