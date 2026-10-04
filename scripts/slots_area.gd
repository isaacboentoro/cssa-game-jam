extends Area2D

var players_in_range: Dictionary = {} # player_id -> true
var occupied_by := ""

func _ready() -> void:
	Slots.table_toggled.connect(_on_slots_toggled)

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
		if event.is_action_pressed(action):
			occupied_by = player_id
			# Deferred so this same key press isn't also read as "spin" by the overlay.
			Slots.call_deferred("open", player_id)
			return

func _on_slots_toggled(player_id: String, is_open: bool) -> void:
	if not is_open and player_id == occupied_by:
		occupied_by = ""
