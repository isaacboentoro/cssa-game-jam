extends Label

@export var player_id := "p1"

#func _ready() -> void:
	#PlayerStats.hp_changed.connect(_on_hp_changed)
	#_refresh()

#func _on_hp_changed(changed_player_id: String, _hp: float) -> void:
	#if changed_player_id == player_id:
	#	_refresh()

#func _refresh() -> void:
#	text = "HP: %d" % round(PlayerStats.get_hp(player_id))

var HP: int
var bolthpu = 0
var bolthpl = -10
func _process(delta: float) -> void:
	HP = int(PlayerStats.get_hp(player_id))
	if HP > bolthpu:
		addbolts()
		bolthpu += 10
		bolthpl += 10
	if HP < bolthpl:
		get_child(boltposi).queue_free()
		boltposi -= 1
		bolthpu -= 10
		bolthpl -= 10
		boltposx -= 30
		pass
	var HPmod = HP % 10
	if deletecooldown >= 1:
		if HPmod <= 4:
			if HPmod <= 1:
				get_child(boltposi).play("explode")
			else:
				get_child(boltposi).play("flashingred")
		else:
			get_child(boltposi).play("default")
	deletecooldown += delta

var boltposx = 20
var boltposi = -1
var deletecooldown = 1

func deletebolt():
	if deletecooldown >= 1:
		get_child(boltposi).queue_free()
		boltposi -= 1
		boltposx -= 30
		deletecooldown = 0
	else:
		return

func addbolts():
	var bolt = AnimatedSprite2D.new()
	bolt.sprite_frames = load("res://assets/hud-elements/lightning.tres")
	bolt.position.x = boltposx
	bolt.position.y = 30
	bolt.texture_filter= 1
	boltposx += 30
	bolt.scale.x = 3
	bolt.scale.y = 3
	boltposi += 1
	add_child(bolt)
	print("made bolt" + str(boltposi))
	pass
