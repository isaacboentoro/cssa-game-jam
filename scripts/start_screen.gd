extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const HOLD_SECONDS := 1.0
const KEY_SHEET := preload("res://assets/hud-elements/QEUO-Buttons.png")
# Y of each key's grey circle icon in QEUO-Buttons.png; the green version sits 16px to the right.
const KEY_REGION_Y := {"Q": 16, "E": 48, "U": 80, "O": 112}

@onready var p1_action1_icon: TextureRect = %P1Action1Icon
@onready var p1_action2_icon: TextureRect = %P1Action2Icon
@onready var p2_action1_icon: TextureRect = %P2Action1Icon
@onready var p2_action2_icon: TextureRect = %P2Action2Icon
@onready var start_p1_icon: TextureRect = %StartP1Icon
@onready var start_p2_icon: TextureRect = %StartP2Icon
@onready var hold_progress: ProgressBar = %HoldProgress

var _icons: Dictionary = {} # letter -> [grey, green]
var _hold_time := 0.0
var _starting := false

func _ready() -> void:
	for letter in KEY_REGION_Y:
		_icons[letter] = [_make_icon(letter, false), _make_icon(letter, true)]
	p1_action2_icon.texture = _icons["E"][0]
	p2_action2_icon.texture = _icons["O"][0]
	hold_progress.max_value = HOLD_SECONDS

func _make_icon(letter: String, green: bool) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = KEY_SHEET
	tex.region = Rect2(16 if green else 0, KEY_REGION_Y[letter], 16, 16)
	return tex

func _process(delta: float) -> void:
	var p1_held := Input.is_action_pressed("p1_action1")
	var p2_held := Input.is_action_pressed("p2_action1")

	var p1_icon: AtlasTexture = _icons["Q"][1 if p1_held else 0]
	var p2_icon: AtlasTexture = _icons["U"][1 if p2_held else 0]
	p1_action1_icon.texture = p1_icon
	start_p1_icon.texture = p1_icon
	p2_action1_icon.texture = p2_icon
	start_p2_icon.texture = p2_icon

	_hold_time = _hold_time + delta if p1_held and p2_held else 0.0
	hold_progress.value = _hold_time

	if _hold_time >= HOLD_SECONDS and not _starting:
		_starting = true
		get_tree().change_scene_to_file(GAME_SCENE)
