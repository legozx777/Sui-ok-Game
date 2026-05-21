extends Node2D

const SAVE_FILE: String = "user://data.save"
const MIN_CLAMPS:= [ # at 415 x
	416 + 16, 
	416 + 20, 
	416 + 24, 
	416 + 33, 
	416 + 44, 
]
const MAX_CLAMPS:= [ # at 895
	894 - 16, 
	894 - 20, 
	894 - 24, 
	894 - 33, 
	894 - 44, 
]
const POOF_SCALES:= [
	0.25 * 1, 
	0.25 * 1.25, 
	0.25 * 1.5, 
	0.25 * (67.0/32), 
	0.25 * 2.75, 
	0.25 * (105.0/32), 
	0.25 * (121.0/32), 
	0.25 * 4.75, 
	0.25 * (169.0/32), 
	0.25 * (217.0/32), 
	0.25 * 8,
]

var master_bus:= AudioServer.get_bus_index("Master")
var bg_opacity:= 0.5
# vv  game data
var playing: bool
var game_seen: int # resets on game, which fruits can spawn
var curr_fruit: int # fruit being dropped / held by player
var next_fruit: int # fruit that is next
var score: int

# vv  loaded from disk
var evo_seen: int # wheel of evo  0-10
var high_score: int # 0-4 billion
var playtime: int # in seconds  0-4 billion or 136 years
""" more shit to add
menu screen (or not)
add actual sound to DeathSound
change background (photo / color) of box (draw actual background) (get sprite for player - cloud thingy)
add drop speed slider for the background fruits

change check_death to be more efficient with a physics object at lineOfDeath
check spawn distribution for fruits (cus rn its random maybe in game its not)

can transfer save data using a hash of save.data with something added infront to prevent tampering
(if someone goes through all that effort to cheat, just let them man....)
 ^^ (FileAccess.open_encrypted or .open_encrypted_with_pass)

global leaderboad w/ ip or smth as a unique identifier for each ("cosmetic" username and highscore)
"""
func _ready():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		evo_seen = file.get_8()
		high_score = file.get_32()
		playtime = file.get_32()
		file.close()
	else:
		evo_seen = 0
		high_score = 0
		playtime = 0
		if FileAccess.file_exists("user://seen.txt"):
			evo_seen = FileAccess.open("user://seen.txt", FileAccess.READ).get_8()
			DirAccess.remove_absolute("user://seen.txt")
		if FileAccess.file_exists("user://high-score.txt"):
			high_score = FileAccess.open("user://high-score.txt", FileAccess.READ).get_32()
			DirAccess.remove_absolute("user://high-score.txt")
		save_data()
	
	$HighScoreLabel.text = "High Score:\n" + str(high_score)
	$AudioSlider.value = AudioServer.get_bus_volume_db(master_bus)
	$BgOpacitySlider.value = bg_opacity
	set_playtime()
	set_evo()
	
	new_game()
	background_fruit_drop()
	#if FileAccess.file_exists("user://not-malware.exe"):
		#FileAccess.open("user://not-malware.exe", FileAccess.WRITE)
	

func _process(_delta):
	if playing:
		var pos = Vector2(clamp(get_local_mouse_position().x, MIN_CLAMPS[curr_fruit], MAX_CLAMPS[curr_fruit]), 60)
		$Player.position = pos
		if (
				Input.is_action_just_pressed("drop") and $Player.visible
				and get_local_mouse_position().distance_to($Container.position) < 600
			):
			$Player.visible = false
			$DropSound.play()
			spawn_fruit(curr_fruit, pos, 0)
			curr_fruit = next_fruit
			set_curr()
			next_fruit = randi() % (game_seen + 1)
		

func spawn_fruit(index: int, pos: Vector2, type: int, opacity = 0.5) -> void:
	# type 0 - player spawned, 1 - merge spawned, 2 - background
	#await get_tree().create_timer(0.02).timeout
	var fruit = load("res://fruit.tscn").instantiate()
	add_child(fruit)
	fruit.seen_signal.connect(on_seen)
	fruit.score_signal.connect(add_score)
	fruit.spawn_new_signal.connect(spawn_fruit)
	fruit.hit_signal.connect(on_hit)
	fruit.sett(index, pos, type, opacity)
	if type == 0:
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(fruit):
			fruit.just_player_spawned = false
	elif type == 1:
		$Poof.position = pos
		$Poof.scale = Vector2.ONE * POOF_SCALES[index]
		$Poof.visible = true
		$Poof.play()
		$MergeSound.play()
		fruit.just_player_spawned = false
		

func on_hit() -> void:
	if playing:
		set_next()
		$NextPoof.scale = Vector2(POOF_SCALES[next_fruit], POOF_SCALES[next_fruit])
		$NextPoof.visible = true
		$NextPoof.play()
		if not $Player.visible:
			$Player.visible = true
	await get_tree().create_timer(0.5).timeout
	check_death()
	

func on_seen(index:int) -> void:
	if evo_seen < index:
		evo_seen = index
		#save_data(index, high_score, playtime) # data is saved every sec
		set_evo()
	if game_seen < index and index < 5:
		game_seen = index

func add_score(s:int) -> void:
	score += s
	$ScoreLabel.text = "Score:\n" + str(score)
	if score > high_score:
		high_score = score
		#save_data(seen, score, playtime) # data is saved every sec
		$HighScoreLabel.text = "High Score:\n" + str(score)
	

func check_death() -> void:
	for fruit in get_tree().get_nodes_in_group("fruit"):
		if fruit.get_top_pos() < 90 and not fruit.just_player_spawned:
			$Player.visible = false
			$DeathLabel.visible = true
			$RestartButton.visible = true
			$DeathSound.play()
			playing = false
			

func new_game() -> void:
	for fruit in get_tree().get_nodes_in_group("fruit"):
		fruit.queue_free()
	game_seen = 0
	curr_fruit = 0
	next_fruit = 0
	score = 0
	set_curr()
	set_next()
	$ScoreLabel.text = "Score: 0"
	$Player.visible = true
	$DeathLabel.visible = false
	$RestartButton.visible = false
	playing = true
	

func save_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_8(evo_seen)
	file.store_32(high_score)
	file.store_32(playtime)
	file.close()
	

func background_fruit_drop() -> void:
	var index = randi() % (evo_seen + 1)
	var posx = randf_range(-50, 1330)
	var pos = Vector2(posx, -200)
	if bg_opacity != 0:
		spawn_fruit(index, pos, 2, bg_opacity)
	await get_tree().create_timer(0.1).timeout
	background_fruit_drop()
	

# vv  sprite setters  vv
func set_curr() -> void:
	$Player/Cherry.visible = true
	$Player/Strawberry.visible = true
	$Player/Grape.visible = true
	$Player/Tangerine.visible = true
	$Player/Orange.visible = true
	if curr_fruit != 0:
		$Player/Cherry.visible = false
	if curr_fruit != 1:
		$Player/Strawberry.visible = false
	if curr_fruit != 2:
		$Player/Grape.visible = false
	if curr_fruit != 3:
		$Player/Tangerine.visible = false
	if curr_fruit != 4:
		$Player/Orange.visible = false
	
func set_next() -> void:
	$Next/Cherry.visible = true
	$Next/Strawberry.visible = true
	$Next/Grape.visible = true
	$Next/Tangerine.visible = true
	$Next/Orange.visible = true
	if next_fruit != 0:
		$Next/Cherry.visible = false
	if next_fruit != 1:
		$Next/Strawberry.visible = false
	if next_fruit != 2:
		$Next/Grape.visible = false
	if next_fruit != 3:
		$Next/Tangerine.visible = false
	if next_fruit != 4:
		$Next/Orange.visible = false
	
func set_evo() -> void: # i for index
	if evo_seen >= 1:
		$EvoWheel/FruitWheel/Strawberry.visible = true
	if evo_seen >= 2:
		$EvoWheel/FruitWheel/Grape.visible = true
	if evo_seen >= 3:
		$EvoWheel/FruitWheel/Tangerine.visible = true
	if evo_seen >= 4:
		$EvoWheel/FruitWheel/Orange.visible = true
	if evo_seen >= 5:
		$EvoWheel/FruitWheel/Apple.visible = true
	if evo_seen >= 6:
		$EvoWheel/FruitWheel/Melon.visible = true
	if evo_seen >= 7:
		$EvoWheel/FruitWheel/Peachnya.visible = true
	if evo_seen >= 8:
		$EvoWheel/FruitWheel/Pineapple.visible = true
	if evo_seen >= 9:
		$EvoWheel/FruitWheel/Wintermelon.visible = true
	if evo_seen >= 10:
		$EvoWheel/FruitWheel/SUIKA.visible = true
	
func set_playtime() -> void:
	var s: int = playtime % 60
	var m: int = (playtime / 60) % 60
	var hours: int = playtime / 3600
	var seconds:= str(s)
	var minutes:= str(m)
	if len(str(s)) == 1:
		seconds = "0" + str(s)
	if len(str(m)) == 1:
		minutes = "0" + str(m)
	$PlaytimeLabel.text = "Playtime:\nH:MM:SS\n%s:%s:%s" % [hours, minutes, seconds]
	
# ^^  sprite setters  ^^

func _on_playtime_timer_timeout():
	playtime += 1
	set_playtime()
	save_data()
	

func _on_restart_pressed():
	new_game()
	
func _on_bgm_finished():
	$BGM.play()
	

func _on_poof_animation_finished():
	$Poof.visible = false
	

func _on_next_poof_animation_finished():
	$NextPoof.visible = false
	

func _on_credits_button_pressed():
	$CreditsLabel.visible = not $CreditsLabel.visible
	

func _on_audio_slider_value_changed(value: float):
	AudioServer.set_bus_mute(master_bus, value < $AudioSlider.min_value + $AudioSlider.step)
	AudioServer.set_bus_volume_db(master_bus, value)
	

func _on_bg_opacity_slider_value_changed(value: float):
	bg_opacity = value
