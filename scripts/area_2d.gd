extends Area2D

var players_in_range : Dictionary = {} # player_id -> true

func _on_body_entered(body:Node) -> void:
	if body.has_meta("player_id"):
		players_in_range[body.get_meta("player_id")] = true
		
func _on_body_exited(body: Node) -> void:
	players_in_range.erase(body.get_meta("player_id"))

func _unhandled_input(event: InputEvent) -> void:
	for player_id in players_in_range:
		var action : String = player_id + "_action1"
		if event.is_action_pressed(action):
			Blackjack.toggle_table(player_id)
