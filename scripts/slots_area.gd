extends Area2D

const COOLDOWN_SECONDS := 15.0
const COOLDOWN_TINT := Color(0.4, 0.4, 0.4)
const LABEL_SHOW_SECONDS := 1.2
const LABEL_FADE_SECONDS := 0.3

var players_in_range: Dictionary = {} # player_id -> true
var occupied_by := ""
var cooldown_left := 0.0

var _cooldown_label: Label
var _label_tween: Tween

func _ready() -> void:
	Slots.table_toggled.connect(_on_slots_toggled)

	_cooldown_label = Label.new()
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cooldown_label.size = Vector2(120, 20)
	_cooldown_label.position = Vector2(-60, -60) # centered above the machine
	_cooldown_label.add_theme_font_size_override("font_size", 12)
	_cooldown_label.add_theme_constant_override("outline_size", 4)
	_cooldown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_cooldown_label.z_index = 10
	_cooldown_label.visible = false
	add_child(_cooldown_label)

func _process(delta: float) -> void:
	if cooldown_left <= 0.0:
		return
	cooldown_left = max(cooldown_left - delta, 0.0)
	if _cooldown_label.visible:
		_cooldown_label.text = "Cooldown: %ds" % ceili(cooldown_left)
	if cooldown_left == 0.0:
		_set_dimmed(false)
		_hide_cooldown_label()

func _on_body_entered(body: Node) -> void:
	if body.has_meta("player_id"):
		players_in_range[body.get_meta("player_id")] = true

func _on_body_exited(body: Node) -> void:
	players_in_range.erase(body.get_meta("player_id"))

func _unhandled_input(event: InputEvent) -> void:
	if occupied_by != "":
		return
	for player_id in players_in_range:
		if Slots.is_open(player_id):
			continue # already playing at some machine; slots_ui.gd owns their input
		var action: String = player_id + "_action1"
		if not event.is_action_pressed(action):
			continue
		if cooldown_left > 0.0:
			_show_cooldown_label()
			return
		occupied_by = player_id
		# Deferred so this same key press isn't also read as "spin" by the overlay.
		Slots.call_deferred("open", player_id)
		return

func _on_slots_toggled(player_id: String, is_open: bool) -> void:
	if not is_open and player_id == occupied_by:
		occupied_by = ""
		cooldown_left = COOLDOWN_SECONDS
		_set_dimmed(true)

# Dims the machine's visuals but not the cooldown label.
func _set_dimmed(dimmed: bool) -> void:
	for child in get_children():
		if child is CanvasItem and child != _cooldown_label:
			child.modulate = COOLDOWN_TINT if dimmed else Color.WHITE

func _show_cooldown_label() -> void:
	if _label_tween:
		_label_tween.kill()
	_cooldown_label.text = "Cooldown: %ds" % ceili(cooldown_left)
	_cooldown_label.modulate.a = 1.0
	_cooldown_label.visible = true
	_label_tween = create_tween()
	_label_tween.tween_interval(LABEL_SHOW_SECONDS)
	_label_tween.tween_property(_cooldown_label, "modulate:a", 0.0, LABEL_FADE_SECONDS)
	_label_tween.tween_callback(_hide_cooldown_label)

func _hide_cooldown_label() -> void:
	if _label_tween:
		_label_tween.kill()
	_cooldown_label.visible = false
