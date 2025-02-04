extends Node2D

@export var width:int
@export var height:int
@export var x_start:int
@export var y_start:int
@export var offset:int
@export var amountMoves : int = 20
@onready var plop_sound: AudioStreamPlayer2D = $"../plop-sound"

var explode = preload("res://scenes/explosion.tscn")

var powerUps = [
	preload("res://scenes/arrow_leftright.tscn"),
	preload("res://scenes/bomb.tscn"),
	preload("res://scenes/blue_flower.tscn"),
	preload("res://scenes/green_flower.tscn"),
	preload("res://scenes/purple_flower.tscn"),
	preload("res://scenes/red_flower.tscn"),
	preload("res://scenes/yellow_flower.tscn")]

var checked = false

var score : int = 0

var possible_blocks := [
	preload("res://scenes/blue_block.tscn"),
	preload("res://scenes/green_block.tscn"),
	preload("res://scenes/purple_block.tscn"),
	preload("res://scenes/red_block.tscn"),
	preload("res://scenes/yellow_block.tscn")
]

var all_blocks := []

var touch = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	all_blocks = make_2d_array()
	spawn_blocks()
	$"../moves".text = str(amountMoves)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass;

func make_2d_array() -> Array:
	var array := []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func spawn_blocks() -> void:
	for i in width:
		for j in height:
			var rand := randi_range(0, possible_blocks.size()-1)
			var block = possible_blocks[rand].instantiate()
			add_child(block)
			block.set_position(grid_to_pixel(i, j))
			all_blocks[i][j] = block

func delete_all_checked() -> void:
	for i in width:
		for j in height:
			if all_blocks[i][j] != null:
				if all_blocks[i][j].isChecked:
					all_blocks[i][j].queue_free()
					all_blocks[i][j] = null
				
	
func grid_to_pixel(column: int, row: int) -> Vector2:
	var new_x := x_start + offset * column
	var new_y := y_start + -offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(x_pos, y_pos) -> Vector2:
	var new_x = roundi((x_pos - x_start) / offset)
	var new_y = roundi((y_pos - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("ui_touch") and amountMoves > 0:
		touch = get_global_mouse_position()
		var grid_position = pixel_to_grid(touch.x, touch.y)
		var inputTriggered = false
		if isBlockNotSingle(grid_position):
			check_match_at(grid_position, all_blocks[grid_position.x][grid_position.y].color)
			explodeBlocks()
			countScore()
			var blockCount = countBlocks()
			var blockColor = all_blocks[grid_position.x][grid_position.y].color
			delete_all_checked()
			givePowerUp(grid_position, blockCount, blockColor)
			plop_sound.play()
			collapse_columns()
			refill_columns()
			amountMoves -= 1
			$"../moves".text = str(amountMoves)
			inputTriggered = true
		if isBlockPowerUp(grid_position) and inputTriggered == false:
			usePowerUp(grid_position)
			countScore()
			explodeBlocks()
			delete_all_checked()
			plop_sound.play()
			collapse_columns()
			refill_columns()
		await get_tree().create_timer(0.2).timeout
		
func check_direction(direction: String, grid_position, type) -> bool:
	if type == "sameColor":
		if direction == "left":
			if grid_position.x > 0:
				if all_blocks[grid_position.x-1][grid_position.y] != null:
					if all_blocks[grid_position.x-1][grid_position.y].isChecked == false:
						if all_blocks[grid_position.x-1][grid_position.y].color == all_blocks[grid_position.x][grid_position.y].color:
							return true
		if direction == "right":
			if grid_position.x < width-1:
				if all_blocks[grid_position.x+1][grid_position.y] != null:
					if all_blocks[grid_position.x+1][grid_position.y].isChecked == false:
						if all_blocks[grid_position.x+1][grid_position.y].color == all_blocks[grid_position.x][grid_position.y].color:
							return true
		if direction == "up":
			if grid_position.y < height-1:
				if all_blocks[grid_position.x][grid_position.y+1] != null:
					if all_blocks[grid_position.x][grid_position.y+1].isChecked == false:
						if all_blocks[grid_position.x][grid_position.y+1].color == all_blocks[grid_position.x][grid_position.y].color:
							return true
		if direction == "down":
			if grid_position.y > 0:
				if all_blocks[grid_position.x][grid_position.y-1] != null:
					if all_blocks[grid_position.x][grid_position.y-1].isChecked == false:
						if all_blocks[grid_position.x][grid_position.y-1].color == all_blocks[grid_position.x][grid_position.y].color:
								return true
	if type == "block":
		if direction == "left":
			if grid_position.x > 0:
				if all_blocks[grid_position.x-1][grid_position.y] != null:
					return true
		if direction == "right":
			if grid_position.x < width-1:
				if all_blocks[grid_position.x+1][grid_position.y] != null:
					return true
		if direction == "up":
			if grid_position.y < height-1:
				if all_blocks[grid_position.x][grid_position.y+1] != null:
					return true
		if direction == "down":
			if grid_position.y > 0:
				if all_blocks[grid_position.x][grid_position.y-1] != null:
					return true
		if direction == "left-up":
			if grid_position.x > 0 and grid_position.y < height-1:
				if all_blocks[grid_position.x-1][grid_position.y+1] != null:
					return true
		if direction == "right-up":
			if grid_position.x < width-1 and grid_position.y < height-1:
				if all_blocks[grid_position.x+1][grid_position.y+1] != null:
					return true
		if direction == "left-down":
			if grid_position.x > 0 and grid_position.y > 0:
				if all_blocks[grid_position.x-1][grid_position.y-1] != null:
					return true
		if direction == "right-down":
			if grid_position.x < width-1 and grid_position.y > 0:
				if all_blocks[grid_position.x+1][grid_position.y-1] != null:
					return true
	return false
	
func usePowerUp(grid_position) -> void:
	var powerUpType = all_blocks[grid_position.x][grid_position.y].powerUpType
	if powerUpType == "arrow-leftright":
		for i in width:
			all_blocks[i][grid_position.y].isChecked = true
	if powerUpType == "bomb":
		all_blocks[grid_position.x][grid_position.y].isChecked = true
		if check_direction("left", grid_position, "block"):
			all_blocks[grid_position.x-1][grid_position.y].isChecked = true
		if check_direction("right", grid_position, "block"):
			all_blocks[grid_position.x+1][grid_position.y].isChecked = true
		if check_direction("up", grid_position, "block"):
			all_blocks[grid_position.x][grid_position.y+1].isChecked = true
		if check_direction("down", grid_position, "block"):	
			all_blocks[grid_position.x][grid_position.y-1].isChecked = true
		if check_direction("left-up", grid_position, "block"):
			all_blocks[grid_position.x-1][grid_position.y+1].isChecked = true
		if check_direction("right-up", grid_position, "block"):
			all_blocks[grid_position.x+1][grid_position.y+1].isChecked = true
		if check_direction("left-down", grid_position, "block"):
			all_blocks[grid_position.x-1][grid_position.y-11].isChecked = true
		if check_direction("right-down", grid_position, "block"):	
			all_blocks[grid_position.x+1][grid_position.y-1].isChecked = true
	if powerUpType == "red-flower":
		all_blocks[grid_position.x][grid_position.y].isChecked = true
		for i in width:
			for j in height:
				if all_blocks[i][j].color == "red":
					all_blocks[i][j].isChecked = true
	if powerUpType == "yellow-flower":
		all_blocks[grid_position.x][grid_position.y].isChecked = true
		for i in width:
			for j in height:
				if all_blocks[i][j].color == "yellow":
					all_blocks[i][j].isChecked = true
	if powerUpType == "purple-flower":
		all_blocks[grid_position.x][grid_position.y].isChecked = true
		for i in width:
			for j in height:
				if all_blocks[i][j].color == "purple":
					all_blocks[i][j].isChecked = true
	if powerUpType == "green-flower":
		all_blocks[grid_position.x][grid_position.y].isChecked = true
		for i in width:
			for j in height:
				if all_blocks[i][j].color == "green":
					all_blocks[i][j].isChecked = true
	if powerUpType == "blue-flower":
		all_blocks[grid_position.x][grid_position.y].isChecked = true
		for i in width:
			for j in height:
				if all_blocks[i][j].color == "blue":
					all_blocks[i][j].isChecked = true
func isBlockPowerUp(grid_position) -> bool:
	if all_blocks[grid_position.x][grid_position.y].color == "powerup":
		return true
	return false
	
func isBlockNotSingle(grid_position):
	if all_blocks[grid_position.x][grid_position.y] != null and all_blocks[grid_position.x][grid_position.y].color != "powerup":
		if grid_position.x >= 0 and grid_position.x <= width-1:
			if grid_position.y >= 0 and grid_position.y <= height-1:
				if check_direction("left", grid_position, "sameColor") or check_direction("right", grid_position, "sameColor") or check_direction("up", grid_position, "sameColor") or check_direction("down", grid_position, "sameColor"):
					return true
	return false

func check_match_at(grid_position, color):
	if all_blocks[grid_position.x][grid_position.y] != null:
		if grid_position.x >= 0 and grid_position.x <= width-1:
			if grid_position.y >= 0 and grid_position.y <= height-1:
				all_blocks[grid_position.x][grid_position.y].isChecked = true
				if check_direction("left", grid_position, "sameColor"):
					check_match_at(Vector2(grid_position.x-1, grid_position.y), all_blocks[grid_position.x][grid_position.y].color)
				if check_direction("right", grid_position, "sameColor"):
					check_match_at(Vector2(grid_position.x+1, grid_position.y), all_blocks[grid_position.x][grid_position.y].color)
				if check_direction("up", grid_position, "sameColor"):
					check_match_at(Vector2(grid_position.x, grid_position.y+1), all_blocks[grid_position.x][grid_position.y].color)
				if check_direction("down", grid_position, "sameColor"):
					check_match_at(Vector2(grid_position.x, grid_position.y-1), all_blocks[grid_position.x][grid_position.y].color)
			
func collapse_columns():
	for i in width:
		for j in height:
			if all_blocks[i][j] == null:
				for k in range(j+1, height):
					if all_blocks[i][k] != null:
						all_blocks[i][k].move(grid_to_pixel(i, j))
						all_blocks[i][j] = all_blocks[i][k]
						all_blocks[i][k] = null
						break

func refill_columns():
	for i in width:
		for j in height:
			if all_blocks[i][j] == null:
				var rand := randi_range(0, possible_blocks.size()-1)
				var block = possible_blocks[rand].instantiate()
				add_child(block)
				block.set_position(grid_to_pixel(i, height))
				block.move(grid_to_pixel(i, j))
				all_blocks[i][j] = block

func explodeBlocks():
	for i in width:
		for j in height:
			if all_blocks[i][j].isChecked:
				var explosion = explode.instantiate()
				add_child(explosion)
				match all_blocks[i][j].color:
					"yellow":
						explosion.process_material.color = Color(255, 241, 0)
					"purple":
						explosion.process_material.color = Color(139, 0, 255)
					"red":
						explosion.process_material.color = Color(255, 0, 0)
					"green":
						explosion.process_material.color = Color(0, 217, 0)
					"blue":
						explosion.process_material.color = Color(0, 93, 217)
				explosion.set_position(grid_to_pixel(i,j))
			
func countBlocks() -> int:
	var countedBlocks = 0
	for i in width:
		for j in height:
			if all_blocks[i][j].isChecked:
				countedBlocks += 1
	return countedBlocks

func givePowerUp(grid_position, blockCount, blockColor):
	if blockCount == 5:
		var rocket = powerUps[0].instantiate()
		add_child(rocket)
		rocket.set_position(grid_to_pixel(grid_position.x,grid_position.y))
		all_blocks[grid_position.x][grid_position.y] = rocket
	if blockCount >= 8:
		var flower : Node2D
		match blockColor:
			"blue":
				flower = powerUps[2].instantiate()
				add_child(flower)
				flower.set_position(grid_to_pixel(grid_position.x,grid_position.y))
				all_blocks[grid_position.x][grid_position.y] = flower
			"green":
				flower = powerUps[3].instantiate()
				add_child(flower)
				flower.set_position(grid_to_pixel(grid_position.x,grid_position.y))
				all_blocks[grid_position.x][grid_position.y] = flower
			"purple":
				flower = powerUps[4].instantiate()
				add_child(flower)
				flower.set_position(grid_to_pixel(grid_position.x,grid_position.y))
				all_blocks[grid_position.x][grid_position.y] = flower
			"red":
				flower = powerUps[5].instantiate()
				add_child(flower)
				flower.set_position(grid_to_pixel(grid_position.x,grid_position.y))
				all_blocks[grid_position.x][grid_position.y] = flower
			"yellow":
				flower = powerUps[6].instantiate()
				add_child(flower)
				flower.set_position(grid_to_pixel(grid_position.x,grid_position.y))
				all_blocks[grid_position.x][grid_position.y] = flower
	if blockCount < 8 and blockCount > 5:
		var bomb = powerUps[1].instantiate()
		add_child(bomb)
		bomb.set_position(grid_to_pixel(grid_position.x,grid_position.y))
		all_blocks[grid_position.x][grid_position.y] = bomb

func countScore():
	score = score + (countBlocks()-1)*3
	$"../scoreboard".text = "Score: " + str(score) 
	
