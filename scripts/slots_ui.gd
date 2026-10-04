extends Control

@export var player_id := "p1"
@export var action1_icon: Texture2D
@export var action2_icon: Texture2D

const SPIN_TICK := 0.06
const FIRST_REEL_STOP := 0.8 # seconds before the first reel stops
const REEL_STOP_GAP := 0.4 # extra seconds before each following reel stops
const CARD_SCALE := 3.0
const CARD_SPACING := 56.0 # 16px card * 3 scale = 48px, plus a gap
const CARD_START_X := 40.0
const CARD_Y := 40.0

@onready var felt: ColorRect = $Felt
@onready var reels_container: Control = $SlotsBox/Reels
var reel_sprites: Array[Sprite2D] = []
@onready var hp_label: Label = $SlotsBox/InfoArea/HpLabel
@onready var bet_label: Label = $SlotsBox/InfoArea/BetLabel
@onready var result_label: Label = $SlotsBox/InfoArea/ResultLabel
@onready var action_hint_1: HBoxContainer = $SlotsBox/InfoArea/ActionHint1
@onready var action_hint_2: HBoxContainer = $SlotsBox/InfoArea/ActionHint2
@onready var spin_button: Button = $SlotsBox/Controls/SpinButton
@onready var action1_sprite: AnimatedSprite2D = $interactionables/ACTION1
@onready var action2_sprite: AnimatedSprite2D = $interactionables/ACTION2

var _action1 := ""
var _action2 := ""

func _ready() -> void:
	visible = false
	felt.visible = false
	_action1 = player_id + "_action1"
	_action2 = player_id + "_action2"
	if action1_icon: action_hint_1.icon = action1_icon
	if action2_icon: action_hint_2.icon = action2_icon
	_reset_key_hints()

	var card_offset := CARD_START_X
	for i in Slots.REEL_COUNT:
		var new_node := Sprite2D.new()
		new_node.scale = Vector2(CARD_SCALE, CARD_SCALE)
		new_node.position = Vector2(card_offset, CARD_Y)
		reels_container.add_child(new_node)
		reel_sprites.append(new_node)
		card_offset += CARD_SPACING

	Slots.table_toggled.connect(_on_table_toggled)
	Slots.state_changed.connect(_on_state_changed)
	Slots.spin_result.connect(_on_spin_result)
	Slots.round_ended.connect(_on_round_ended)
	PlayerStats.hp_changed.connect(_on_hp_changed)

	spin_button.pressed.connect(func(): Slots.place_bet(player_id))

	_on_state_changed(player_id, Slots.get_state(player_id))
	_refresh_info()

func _unhandled_input(event: InputEvent) -> void:
	if not Slots.is_open(player_id):
		return

	if event.is_action_pressed(_action1):
		_set_key_hint(action1_sprite, 0, true)
	elif event.is_action_released(_action1):
		_set_key_hint(action1_sprite, 0, false)
	if event.is_action_pressed(_action2):
		_set_key_hint(action2_sprite, 1, true)
	elif event.is_action_released(_action2):
		_set_key_hint(action2_sprite, 1, false)

	if Slots.get_state(player_id) != Slots.State.BETTING:
		return
	if event.is_action_pressed(_action1):
		Slots.place_bet(player_id)
	elif event.is_action_pressed(_action2):
		Slots.close(player_id)

func _on_table_toggled(for_player: String, is_open: bool) -> void:
	if for_player != player_id:
		return
	visible = is_open
	felt.visible = is_open
	_reset_key_hints()

# Key letters per player, matching table_ui.gd: p1 uses Q/E, p2 uses U/O.
func _key_letter(slot: int) -> String:
	var letters: Array = ["Q", "E"] if player_id == "p1" else ["U", "O"]
	return letters[slot]

func _set_key_hint(sprite: AnimatedSprite2D, slot: int, pressed: bool) -> void:
	var anim: String = _key_letter(slot) + ("CircGreen" if pressed else "CircGrey")
	# Skips quietly until the SpriteFrames atlas with these animations is added.
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _reset_key_hints() -> void:
	_set_key_hint(action1_sprite, 0, false)
	_set_key_hint(action2_sprite, 1, false)

func _on_state_changed(for_player: String, state) -> void:
	if for_player != player_id:
		return
	var betting: bool = state == Slots.State.BETTING
	spin_button.disabled = not betting
	if betting:
		result_label.text = ""
		for sprite in reel_sprites:
			_show_card(sprite, Slots.random_card())
		action_hint_1.set_text("Spin")
		action_hint_2.set_text("Leave")
	else:
		action_hint_1.set_text("")
		action_hint_2.set_text("")

func _show_card(sprite: Sprite2D, card: Dictionary) -> void:
	sprite.texture = load(Slots.card_texture_path(card))

## Each reel flicks through random cards, then the reels stop left to right on
## the predetermined result before Slots pays out.
func _on_spin_result(for_player: String, reels: Array) -> void:
	if for_player != player_id:
		return
	var elapsed := 0.0
	var stopped := 0
	while stopped < reels.size():
		var next_stop := FIRST_REEL_STOP + REEL_STOP_GAP * stopped
		if elapsed >= next_stop:
			_show_card(reel_sprites[stopped], reels[stopped])
			stopped += 1
			continue
		for i in range(stopped, reels.size()):
			_show_card(reel_sprites[i], Slots.random_card())
		await get_tree().create_timer(SPIN_TICK).timeout
		elapsed += SPIN_TICK
	Slots.finish_spin(player_id)

func _on_round_ended(for_player: String, result: String, payout: float) -> void:
	if for_player != player_id:
		return
	result_label.text = "%s (payout %d)" % [result, round(payout)]
	_refresh_info()

func _refresh_info() -> void:
	hp_label.text = "HP: %d" % round(PlayerStats.get_hp(player_id))
	bet_label.text = "Bet: %d" % round(Slots.get_bet(player_id))

func _on_hp_changed(changed_player_id: String, _hp: float) -> void:
	if changed_player_id == player_id:
		_refresh_info()
