extends Control

const MAIN_SCENE := "res://scenes/game.tscn"

@onready var message_label: Label = $MessageLabel
@onready var restart_button: Button = $RestartButton

func _ready() -> void:
	var loser := PlayerStats.last_loser_id
	message_label.text = "%s ran out of HP!" % loser.to_upper()
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.grab_focus()

func _on_restart_pressed() -> void:
	PlayerStats.reset()
	get_tree().change_scene_to_file(MAIN_SCENE)
