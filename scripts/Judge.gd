extends AcceptDialog

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

# FIXME: Import this from the Sim script somehow?
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

var neighbors = [
	["Jim", "he", "his"],
	["Joyce", "she", "hers"],
	["Barnaby", "he", "his"],
	["Dennis", "he", "his"],
	["Gavin", "he", "his"],
	["Tom", "he", "his"],
	["Phyllis", "she", "hers"],
	["Iris", "she", "hers"],
	["Hyacinth", "she", "hers"],
	["Poppy", "she", "hers"],
]

var places = [
	"up the street",
	"next door",
	"across the road",
]

var adjectives = [
	"thinks",
	"told me",
	"has it on good authority",
	"wanted me to tell you",
	"says",
	"mentioned in passing",
]

var garden = "that your garden"

var responses = {
	"dirt": "that your garden is quite messy",
	"weeds": "you have too many weeds",
	"shaggy": "it's looking a bit scruffy",
	"flowers": "you have a lovely arrangement",
	"blooming": "it's very nice bloom indeed",
	"low": "that it's laughable",
	"mid": "is better",
	"high": "jealous"
}

var ratings = [
	"You should be ashamed!",
	"Your garden is appalling, and bringing down our property prices!",
	"To be honest, your garden could do with some work.",
	"Well, it certainly looks like a garden.",
	"Not bad, but not great, if I'm being completely honest.",
	"Keep up the good work!",
	"Your garden is really getting there.",
	"Your garden is quite the talk of the town. Well done.",
	"Stunning!",
	"We think your garden is quite magnificent, how did you do it?!",
]

func judge_map_stats(stats):
	var neighbor = neighbors[randi() % neighbors.size()]
	var place = places[randi() % places.size()]
	var adjective = adjectives[randi() % adjectives.size()]

	var rating = ratings[int(stats["score"])]
	var response = "%s %s %s %s." % [neighbor[0], place, adjective, get_response(neighbor, stats)]

	var text = "%s\n\n%s\n\n" % [rating, response]

	return text

func get_response(neighbor, stats):
	if stats["dirt_score"] <= 3:
		return responses["dirt"]
	elif stats[TILE_TYPES.WEEDS] > 4:
		return responses["weeds"]
	elif stats["shaggy_score"] == 0:
		return responses["shaggy"]
	elif stats["flowers_score"] > 1 && stats["flowers_score"] < 8:
		return responses["flowers"]
	elif stats["flowers_score"] >= 4 && stats["grown_flowers_percent"] > 0.6:
		return responses["blooming"]

	if stats["score"] >= 8.0:
		return "%s's %s" % [neighbor[1], responses["high"]]
	elif stats["score"] >= 4.0:
		return "%s %s" % [neighbor[2], responses["mid"]]
	else:
		return responses["low"]
