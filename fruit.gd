extends RigidBody2D

signal seen_signal(index: int)
signal score_signal(score: int)
signal spawn_new_signal(index: int, pos: Vector2, poof: bool)
signal hit_signal
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
var hit_local: bool = false
var just_player_spawned: bool = true
var index: int
var type: int # 0 = player spawned, 1 = merge spawned, 2 = background

func _on_body_entered(body):
	if type != 2:
		if not hit_local:
			hit_local = true
			hit_signal.emit()
		if body.get_groups().find("fruit") != -1 and body.index == index:
			var pos = position.lerp(body.position, 0.5)
			body.free()
			score_signal.emit(SCORES[index])
			seen_signal.emit(index + 1)
			if index != 10: # index 10 means 2 suika collided
				spawn_new_signal.emit(index + 1, pos, 1)
			queue_free()
	elif body.get_groups().find("floor") != -1:
		queue_free()

func sett(index: int, pos: Vector2, type: int, opacity: float) -> void:
	var fruitList = [$Cherry, $Strawberry, $Grape, $Tangerine, $Orange, 
		$Apple, $Melon, $Peachnya, $Pineapple, $Wintermelon, $SUIKA]
	self.index = index
	self.position = pos
	self.type = type
	$CollisionShape2D.scale = Vector2.ONE * SCALES[index]
	if type == 2:
		$CollisionShape2D.scale *= 0.6
		fruitList[index].scale *= 0.6
		self.z_index = -2 # -2 bc peach has z of 1, and we need -1
		self.collision_layer = 2
		self.collision_mask = 2
		self.gravity_scale = 0.05
		self.rotation = randf() * TAU
		self.modulate = Color(1, 1, 1, opacity)
		self.angular_velocity = randf_range(-0.2, 0.2)
		self.remove_from_group("fruit")
		self.add_to_group("background")
	if index != 0:
		fruitList[index-1].visible = false
	fruitList[index].visible = true
	
	
func get_top_pos() -> float:
	const FRUIT_SIZE = [16, 20, 24, 34, 44, 53, 61, 76, 85, 109, 128]
	return self.position.y - FRUIT_SIZE[index]
