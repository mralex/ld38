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
	TALL_GRASS,
	SOWN_DIRT,
}

const tile_prices = {
	TILE_TYPES.CONCRETE: 5,
	TILE_TYPES.ROSES: 5,
	TILE_TYPES.DAFODILS: 5,
	TILE_TYPES.ORCHIDS: 10,
	TILE_TYPES.GRASS: 2,
	TILE_TYPES.DIRT: 1,
}

const BASE_AWARD_MONEY = 500
const BASE_GRASS_GROWTH_RATE = 0.02
const BASE_FLOWER_GROWTH_RATE = 0.2
const TALL_GRASS_BASE_HEIGHT = 75
const FLOWER_GROWN_AMOUNT = 50
const INITIAL_WATER_DISTANCE = 10000

const TICKS_PER_MINUTE = 10

# 6am
const START_TIME = TICKS_PER_MINUTE * 60 * 6

class GameClock:
	signal tick
	var timeMultiplier = 1.0
	var timeStep = 0
	var timeToProcess = 0

	# Start the game at 6am
	var ticks = START_TIME

	var ticksPerMinute = TICKS_PER_MINUTE
	var ticksPerDay = TICKS_PER_MINUTE * 60 * 24
	var minutes = 0
	var minutesLastTick = 0

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

		#if timeToProcess < 0.0:
	#		return

		timeToProcess = 0.0

	func update_time():
		minutesLastTick = minutes
		minutes = int(ticks / ticksPerMinute)

	func is_tick_on_minute():
		return ticks % ticksPerMinute == 0

	func set_speed(speed):
		print("set speed to %s" % speed)
		if speed == 0:
			timeMultiplier = 0.0
		elif speed == 1:
			timeMultiplier = 1.0
		elif speed == 2:
			timeMultiplier = 15.0

		timeToProcess = 0.0
		timeStep = 1 / (60.0 * timeMultiplier)

class GameTile:
	var position = Vector2(0, 0)
	var type = TILE_TYPES.DIRT
	var sprite = TILE_TYPES.DIRT
	var map

	var growth_rate = 0.0
	var growth_amount = 0.0

	# minutes since epoch
	var added_at = -1

	# minutes since planting
	var age = -1

	var distance_to_water = -1

	var surrounding_tiles = []

	func _init(map, x, y, type):
		self.map = map
		set_type(type)
		self.position = Vector2(x, y)

	func _tick(clock):
		if added_at == -1:
			added_at = clock.minutes
			age = 0

		if clock.is_tick_on_minute():
			growth_amount += growth_rate
			age += 1

		if clock.is_tick_on_minute() && clock.minutes % 60 == 0:
			if type == TILE_TYPES.GRASS && age > 60 && randi() % 1000 == 1:
				set_type(TILE_TYPES.WEEDS)
			elif type == TILE_TYPES.WEEDS && randi() % 50 == 1:
				# Set a surrounding tile to weed if we're a weed
				randomize()
				var tile = surrounding_tiles[randi() % 8]
				if tile != null && tile.type == TILE_TYPES.GRASS:
					tile.set_type(TILE_TYPES.WEEDS)

		update_water_proximity()

		return

	func update_water_proximity():
		var water = INITIAL_WATER_DISTANCE
		var proximities = []

		if type == TILE_TYPES.WATER:
			distance_to_water = 0
			return

		for tile in surrounding_tiles:
			if tile == null:
				continue

			if tile.type == TILE_TYPES.WATER:
				water = 0
				break

			if tile.distance_to_water > -1 && tile.distance_to_water < water:
				water = tile.distance_to_water

		if water != INITIAL_WATER_DISTANCE:
			distance_to_water = water + 1

	func set_type(type):
		self.type = type
		age = -1
		added_at = -1
		growth_amount = 0.0

		var base_growth_rate = 0
		var growth_rate_mod = 6

		if type == TILE_TYPES.GRASS:
			base_growth_rate = BASE_GRASS_GROWTH_RATE
			growth_rate_mod = 24
		elif type == TILE_TYPES.ROSES || type == TILE_TYPES.DAFODILS || type == TILE_TYPES.ORCHIDS:
			base_growth_rate = BASE_FLOWER_GROWTH_RATE

		growth_rate = base_growth_rate + (randf() / growth_rate_mod) * 0.5

	func get_sprite():
		if (type == TILE_TYPES.ROSES || type == TILE_TYPES.DAFODILS || type == TILE_TYPES.ORCHIDS) && growth_amount < FLOWER_GROWN_AMOUNT:
			return TILE_TYPES.SOWN_DIRT

		if is_tall_grass():
			return TILE_TYPES.TALL_GRASS

		return type

	func is_tall_grass():
		return type == TILE_TYPES.GRASS && growth_amount > TALL_GRASS_BASE_HEIGHT

	func type_string():
		if type == TILE_TYPES.DIRT:
			return "Dirt"
		elif type == TILE_TYPES.GRASS:
			if growth_amount > TALL_GRASS_BASE_HEIGHT:
				return "Tall Grass"
			else:
				return "Grass"
		elif type == TILE_TYPES.WEEDS:
			return "Weeds"
		elif type == TILE_TYPES.WATER:
			return "Water"
		elif type == TILE_TYPES.CONCRETE:
			return "Concrete"
		elif type == TILE_TYPES.ROSES:
			return "Roses"
		elif type == TILE_TYPES.DAFODILS:
			return "Dafodils"
		elif type == TILE_TYPES.ORCHIDS:
			return "Orchids"
		else:
			return "Unknown!"

	func randomize_type():
		type = randi() % 7 + 1

	func register_surrounding_tiles():
		var surrounding = []
		var x = position.x
		var y = position.y

		surrounding.resize(8)
		surrounding[0] = self.map.get_tile(x + 1, y)
		surrounding[1] = self.map.get_tile(x + 1, y + 1)
		surrounding[2] = self.map.get_tile(x, y + 1)
		surrounding[3] = self.map.get_tile(x - 1, y + 1)
		surrounding[4] = self.map.get_tile(x - 1, y)
		surrounding[5] = self.map.get_tile(x - 1, y - 1)
		surrounding[6] = self.map.get_tile(x, y - 1)
		surrounding[7] = self.map.get_tile(x + 1, y - 1)

		surrounding_tiles = surrounding

	func mow():
		type = TILE_TYPES.GRASS
		growth_amount = 0

class GameMap:
	var data = []
	var width = 0
	var height = 0
	var tileMap

	var money = 1000.0
	var rating = 5.0

	func _init(width, height, tileMap):
		self.width = width
		self.height = height
		self.tileMap = tileMap

		data.resize(width * height)

		randomize()
		var s = (randi() % 100 + 10) * 0.001
		var xOffset = randi() % 100
		var yOffset = randi() % 100

		for x in range(width):
			for y in range(height):
				var noise = Simplex.simplex2(xOffset + x * s, yOffset + y * s) / 2.0 + 0.5
				var type = TILE_TYPES.DIRT

				if noise < 0.7:
					type = TILE_TYPES.GRASS
				elif noise < 0.8:
					type = TILE_TYPES.DIRT
				else:
					type = TILE_TYPES.WATER

				data[width * y + x] = GameTile.new(self, x, y, type)

		for tile in data:
			tile.register_surrounding_tiles()

		refresh_entire_tile_map()
		refresh_rating()

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
				self.tileMap.set_cell(x, y, get_tile(x, y).get_sprite())

	func get_tile(x, y):
		var index = width * y + x

		if index > data.size() - 1 || index < 0:
			return null

		return data[index]

	func reset_tile(x, y):
		var tile = get_tile(x, y)

		if not tile:
			return

		if tile.type == TILE_TYPES.WATER:
			return

		tile.set_type(TILE_TYPES.DIRT)

	func lay_path(x, y):
		var tile = get_tile(x, y)

		if not tile:
			return

		if tile.type == TILE_TYPES.WATER:
			return

		# Can only place path on solid ground, not water
		tile.set_type(TILE_TYPES.CONCRETE)

	func mow_grass(x, y):
		var tile = get_tile(x, y)

		if not tile:
			return

		if tile.type == TILE_TYPES.GRASS:
			tile.mow()

	func plant_seeds(x, y, seed_type):
		var tile = get_tile(x, y)
		var type
		if not tile:
			return

		if tile.type != TILE_TYPES.DIRT:
			return

		# Only plan seeds in dirt
		if seed_type == 1:
			type = TILE_TYPES.ROSES
		elif seed_type == 2:
			type = TILE_TYPES.DAFODILS
		elif seed_type == 3:
			type = TILE_TYPES.ORCHIDS

		money -= tile_prices[type]
		tile.set_type(type)

	func plant_grass(x, y):
		var tile = get_tile(x, y)
		var type
		if not tile:
			return

		if tile.type != TILE_TYPES.DIRT:
			return

		money -= tile_prices[TILE_TYPES.GRASS]
		tile.set_type(TILE_TYPES.GRASS)

	func fill_water(x, y):
		var tile = get_tile(x, y)
		var type
		if not tile:
			return

		if tile.type != TILE_TYPES.WATER:
			return

		tile.set_type(TILE_TYPES.DIRT)

	func rate_map():
		var stats = {
			TILE_TYPES.GRASS: 0,
			TILE_TYPES.DIRT: 0,
			TILE_TYPES.WATER: 0,
			"flowers": 0,
			"grown_flowers": 0,
			"dead_flowers": 0,
			TILE_TYPES.WEEDS: 0,
			"shaggy": 0
		}

		for tile in data:
			if tile.type == TILE_TYPES.ROSES ||  tile.type == TILE_TYPES.DAFODILS ||  tile.type == TILE_TYPES.ORCHIDS:
				stats["flowers"] += 1
				if tile.growth_amount >= FLOWER_GROWN_AMOUNT:
					stats["grown_flowers"] += 1
			elif tile.is_tall_grass():
				stats["shaggy"] += 1
			else:
				stats[tile.type] += 1

		stats["grass_to_dirt"] = float(stats[TILE_TYPES.GRASS]) / float(stats[TILE_TYPES.DIRT])

		var size = float(data.size())

		var grass_percent = float(stats[TILE_TYPES.GRASS] - stats["shaggy"]) / size
		var grass_score = 2
		if grass_percent == 0:
			grass_score = 0

		if grass_percent > 0.6:
			grass_score = 8

		if stats["shaggy"] > 0:
			grass_score -= 2

		if stats[TILE_TYPES.WEEDS] > 2:
			grass_score -= 3

		var shaggy_percent = float(stats["shaggy"] + stats[TILE_TYPES.WEEDS]) / size
		var shaggy_score = 5
		if shaggy_percent > 0.3:
			shaggy_score = 0

		var dirt_percent = float(stats[TILE_TYPES.DIRT]) / size
		var dirt_score = 8
		if dirt_percent > 0.6:
			dirt_score = 2
		elif dirt_percent > 0.4:
			dirt_score = 3
		elif dirt_percent > 0.1:
			dirt_score = 5

		var flowers_percent = float(stats["flowers"]) / (size / 2)
		var grown_flowers_percent = float(stats["grown_flowers"]) / float(stats["flowers"])
		var flowers_score = 0
		if flowers_percent > 0:
			flowers_score = 1

			if flowers_percent > 0.2:
				flowers_score = 4
			if flowers_percent > 0.5:
				flowers_score = 8
			if grown_flowers_percent > 0.5:
				flowers_score += 3

		var base_score = float(grass_score + dirt_score + flowers_score + shaggy_score)
		stats["base_score"] = base_score
		stats["grass_score"] = grass_score
		stats["shaggy_score"] = shaggy_score
		stats["dirt_score"] = dirt_score
		stats["flowers_score"] = flowers_score

		var score = base_score / 32.0
		stats["score_float"] = score
		stats["score"] = score * 10

		return stats

	func refresh_rating():
		var stats = rate_map()
		rating = stats["score"]

	func award_prize_money(stats):
		var award = stats["score_float"] * BASE_AWARD_MONEY
		money += award
		return award

const mapSize = Vector2(32, 23)
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

	if clock.is_tick_on_minute() && clock.minutes > 0 && clock.minutes % 60 == 0:
		map.refresh_rating()
