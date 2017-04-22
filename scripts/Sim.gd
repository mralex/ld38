extends Node2D

const Simplex = preload("Simplex.gd")

enum TILE_TYPES {
	DIRT,
	GRASS,
	WEEDS,
	WATER,
	CONCRETE,
	ROSES,
	DAFODILS,
	ORCHIDS,
}

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
	var map
	
	func _init(map, x, y, type):
		self.map = map
		self.type = type
		self.position = Vector2(x, y)
	
	func _tick(clock):
		if clock.minutes > 0 && clock.minutes % 60 != 0:
			return

		var water = 0
		var grass = 0
		var surrounding = surrounding_tiles()
	
		for tile in surrounding:
			if tile == null:
				continue

			if tile.type == 1:
				grass += 1
			if tile.type == 3:
				water += 1
		
		randomize()
		# Dirt near water turns into grass
		if type == 0 && water > 0 && randi() % 10 == 1:
			type = 1
		# Dirt near grass turns into grass
		elif type == 0 && grass > 0 && randi() % 10 == 1:
			type = 1
		
		randomize()
		if type == 1 && randi() % 1000 == 1:
			type = 2
	
	func type_string():
		if type == 0:
			return "Dirt"
		elif type == 1:
			return "Grass"
		elif type == 2:
			return "Weeds"
		elif type == 3:
			return "Water"
		elif type == 4:
			return "Concrete"
		elif type == 5:
			return "Roses"
		elif type == 6:
			return "Dafodils"
		elif type == 7:
			return "Orchids"
		else:
			return "Unknown!"

	func randomize_type():
		type = randi() % 7 + 1
		
	func surrounding_tiles():
		var surrounding = []
		var x = position.x
		var y = position.y
		surrounding.append(self.map.get_tile(x + 1, y))
		surrounding.append(self.map.get_tile(x + 1, y + 1))
		surrounding.append(self.map.get_tile(x, y + 1))
		surrounding.append(self.map.get_tile(x - 1, y + 1))
		surrounding.append(self.map.get_tile(x - 1, y))
		surrounding.append(self.map.get_tile(x - 1, y - 1))
		surrounding.append(self.map.get_tile(x, y - 1))
		surrounding.append(self.map.get_tile(x + 1, y - 1))
		
		return surrounding

class GameMap:
	var data = []
	var width = 0
	var height = 0
	var tileMap
	
	func _init(width, height, tileMap):
		self.width = width
		self.height = height
		self.tileMap = tileMap
		
		data.resize(width * height)
	
		randomize()
		var s = (randi() % 100 + 10) * 0.001
		
		for x in range(width):
			for y in range(height):
				var noise = Simplex.simplex2(x * s, y * s) / 2.0 + 0.5
				var type = TILE_TYPES.DIRT
				
				if noise < 0.7:
					type = TILE_TYPES.GRASS
				elif noise < 0.8:
					type = TILE_TYPES.DIRT
				else:
					type = TILE_TYPES.WATER
				
				data[width * y + x] = GameTile.new(self, x, y, type)

		refresh_entire_tile_map()
	
	func _tick(clock):
		# Update tiles every minute
		if clock.ticks % clock.ticksPerMinute == 0:
			for cell in data:
				cell._tick(clock)

	func update_randomly():
		var x = randi() % self.width
		var y = randi() % self.height
		
		get_tile(x, y).randomize_type()
		refresh_tile_map(x, y)
		# print("Updated tile %s,%s to %s" % [x, y, data[y][x]])
	
	func refresh_tile_map(x, y):
		# Not a fan of directly poking the tile map from this class. 
		# Fix that later I suppose...
		var tile = get_tile(x, y)
		self.tileMap.set_cell(x, y, tile.type)
	
	func refresh_entire_tile_map():
		for x in range(width):
			for y in range(height):
				self.tileMap.set_cell(x, y, get_tile(x, y).type)
	
	func get_tile(x, y):
		var index = width * y + x

		if index > data.size() - 1 || index < 0:
			return null
			
		return data[index]
	
	func reset_tile(x, y):
		var tile = get_tile(x, y)
		var type = tile.type
		
		if type == TILE_TYPES.WATER:
			return
			
	#	if type == 0:
	#		tile.type = 3
	#	else:
		tile.type = TILE_TYPES.DIRT
	
	func lay_path(x, y):
		var tile = get_tile(x, y)
		
		if not tile:
			return
		
		if tile.type == TILE_TYPES.WATER:
			return
			
		# Can only place path on solid ground, not water
		tile.type = TILE_TYPES.CONCRETE
	
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
	map.refresh_entire_tile_map()
	
func _tick():
	map._tick(clock)

	# Update a tile every 10 in-game minutes
	if clock.minutes > lastTickUpdate && clock.minutes > 0 && clock.minutes % 10 == 0:
		#map.update_randomly()
		lastTickUpdate = clock.minutes
