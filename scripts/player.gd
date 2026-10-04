extends CharacterBody2D

const SPEED = 300.0

@export var player_id := "p1"
@export var action_left := "p1_left"
@export var action_right := "p1_right"
@export var action_up := "p1_up"
@export var action_down := "p1_down"

var last_direction: Vector2 = Vector2.RIGHT
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	set_meta("player_id", player_id)
	if player_id == "p1":
		$AnimatedSprite2D.sprite_frames = load("res://assets/Robots/Blue/bluebot.tres")
	else:
		$AnimatedSprite2D.sprite_frames = load("res://assets/Robots/Green/greenbot.tres")



func _physics_process(_delta: float) -> void:
	process_movement()
	process_animation()
	move_and_slide()


func process_movement() -> void:
	var direction := Input.get_vector(action_left, action_right, action_up, action_down)
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO


func process_animation() -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)



func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")
