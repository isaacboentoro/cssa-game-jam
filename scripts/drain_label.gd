extends Label

func _ready() -> void:
	PlayerStats.drain_rate_changed.connect(_on_drain_rate_changed)
	_refresh()

func _on_drain_rate_changed(_rate: float) -> void:
	_refresh()

func _refresh() -> void:
	text = "Drain: %d hp/s" % round(PlayerStats.drain_rate)
