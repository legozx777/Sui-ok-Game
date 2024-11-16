extends RigidBody2D

signal seeen(index: int)
signal score(score: int)
signal spawn_new(index: int, pos: Vector2, poof: bool)
signal hit
const SCALES: Array = [
	1, 
	1.25, 
	1.5, 
	(67.0/32), # 210%, 2.09375
	2.75, 
	(105.0/32), # 330%, 3.29125
	(121.0/32), # 380%, 3.78125
	4.75, 
	(169.0/32), # 530%, 5.28125
	(217.0/32), # 680%, 6.78125
	8,
]
const SCORES: Array = [
	1,
	3,
	6,
	10,
	15,
	21,
	28,
	36,
	45,
	55,
	66,
]
var hitt: bool = false
var just_player_spawned: bool = true
var index: int
var type: int # 0 = player spawned, 1 = merge spawned, 2 = background

func _on_body_entered(body):
	if type != 2:
		if not hitt:
			hitt = true
			hit.emit()
		if body.get_groups().find("fruit") != -1 and body.index == index:
			var pos
			if position.y >= body.position.y: # sets y pos to the lower fruit
				pos = Vector2(lerp(position.x, body.position.x, 0.5), position.y)
			else:
				pos = Vector2(lerp(position.x, body.position.x, 0.5), body.position.y)
			body.free()
			score.emit(SCORES[index])
			seeen.emit(index + 1)
			if index != 10: # index 10 means 2 suika collided
				spawn_new.emit(index + 1, pos, 1)
			queue_free()
	elif body.get_groups().find("fruit") == -1 and body.get_groups().find("background") == -1:
		queue_free()

func sett(indexx: int, pos: Vector2, type: int) -> void:
	self.index = indexx
	self.position = pos
	self.type = type
	if type == 2:
		self.collision_layer = 2
		self.collision_mask = 2
		self.z_index = -1
		self.gravity_scale = 0.05
		self.rotation = randf() * 2 * PI
		self.modulate = Color(1, 1, 1, 0.5)
		self.remove_from_group("fruit")
		self.add_to_group("background")
	$CollisionShape2D.scale = Vector2(SCALES[indexx], SCALES[indexx])
	if indexx == 0:
		$Cherry.visible = true
	elif index == 1:
		$Cherry.visible = false
		$Strawberry.visible = true
	elif index == 2:
		$Strawberry.visible = false
		$Grape.visible = true
	elif index == 3:
		$Grape.visible = false
		$Tangerine.visible = true
	elif index == 4:
		$Tangerine.visible = false
		$Orange.visible = true
	elif index == 5:
		$Orange.visible = false
		$Apple.visible = true
	elif index == 6:
		$Apple.visible = false
		$Melon.visible = true
	elif index == 7:
		$Melon.visible = false
		$Peachnya.visible = true
	elif index == 8:
		$Peachnya.visible = false
		$Pineapple.visible = true
	elif index == 9:
		$Pineapple.visible = false
		$Wintermelon.visible = true
	elif index == 10:
		$Wintermelon.visible = false
		$SUIKA.visible = true
	
func get_top_pos() -> float:
	const FRUIT_SIZE = [16, 20, 24, 34, 44, 53, 61, 76, 85, 109, 128]
	return self.position.y - FRUIT_SIZE[index]
