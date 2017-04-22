extends Node2D

class GameClock:
	signal tick
	var timeMultiplier = 1.0
	var timeStep = 0
	var timeToProcess = 0
	
	# Start the game at 6am
	var ticks = 7200
	
	var ticksPerMinute = 20
	var minutes = 0
	
	func _init():
		timeStep = 1 / (60.0 * timeMultiplier)
	
	func update(delta):
		# Are we paused?
		if timeMultiplier == 0:
			return

		timeToProcess += delta
		
		while(timeToProcess > 0.0):
			ticks += 1
			
			# Update the scene i guess!
			update_time()
			emit_signal("tick")
			
			timeToProcess -= timeStep
		
		if timeToProcess < 0.0:
			return
		
		timeToProcess = 0.0
	
	func update_time():
		minutes = int(ticks / ticksPerMinute)
	
	func set_speed(speed):
		if speed == 0:
			timeMultiplier = 0
		elif speed == 1:
			timeMultiplier = 1
		elif speed == 2:
			timeMultiplier = 15

		timeStep = 1 / (60.0 * timeMultiplier)

class GameTile:
	var position = Vector2(0, 0)
	var type = 0
	
	func _init(x, y, type):
		self.type = type
		self.position = Vector2(x, y)
	
	func type_string():
		if type == 0:
			return "Grass"
		elif type == 1:
			return "Water"
		elif type == 2:
			return "Dirt"
		elif type == 3:
			return "Concrete"
		elif type == 4:
			return "Roses"
		elif type == 5:
			return "Dafodils"
		elif type == 6:
			return "Orchids"
		elif type == 7:
			return "Weeds"
		else:
			return "Unknown!"

	func randomize_type():
		type = randi() % 8

class GameMap:
	var data = []
	var width = 0
	var height = 0
	var tileMap
	
	func _init(width, height, tileMap):
		self.width = width
		self.height = height
		self.tileMap = tileMap

		# Initialize map to dirt
		for y in range(height):
			data.append([])
			for x in range(width):
				data[y].append(GameTile.new(x, y, 2))
	
	func update_randomly():
		var x = randi() % self.width
		var y = randi() % self.height
		
		self.data[y][x].randomize_type()
		refresh_tile_map(x, y)
		# print("Updated tile %s,%s to %s" % [x, y, data[y][x]])
	
	func refresh_tile_map(x, y):
		# Not a fan of directly poking the tile map from this class. 
		# Fix that later I suppose...
		self.tileMap.set_cell(x, y, self.data[y][x].type)
	
	func get_tile(tilePos):
		return data[tilePos.y][tilePos.x]
	
	func reset_tile(tilePos):
		var tile = data[tilePos.y][tilePos.x]
		var type = tile.type
		
		if type == 2:
			return
		
		if type == 7:
			tile.type = 0
		else:
			tile.type = 2
		
		refresh_tile_map(tilePos.x, tilePos.y)
	
const mapSize = Vector2(32, 22)
var clock
var map
var lastTickUpdate = -1

func _ready():
	set_process(true)
	initialize_clock()
	initialize_map()

func initialize_clock():
	clock = GameClock.new()
	clock.connect("tick", self, "_tick")

func initialize_map():
	map = GameMap.new(int(mapSize.width), int(mapSize.height), get_node("../WorldMap"))

func _process(delta):
	clock.update(delta)
	
func _tick():
	# Update a tile every 10 in-game minutes
	if clock.minutes > lastTickUpdate && clock.minutes > 0 && clock.minutes % 10 == 0:
		map.update_randomly()
		lastTickUpdate = clock.minutes
