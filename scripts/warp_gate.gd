extends Area2D

@export var exit_gate : NodePath
@export var exit_offset := Vector2(40, 0)

func _on_body_entered(body:Node2D) -> void:
	if not body.has_meta("player_id"):
		return
	var exit : Node2D = get_node(exit_gate)
	body.global_position = exit.global_position + exit_offset
	if body.has_method("on_teleported"):
		body.on_teleported()
