extends Label

@export var player_id := "p1"

func _ready() -> void:
	PlayerStats.hp_changed.connect(_on_hp_changed)
	_refresh()

func _on_hp_changed(changed_player_id: String, _hp: float) -> void:
	if changed_player_id == player_id:
		_refresh()

func _refresh() -> void:
	text = "HP: %d" % round(PlayerStats.get_hp(player_id))
