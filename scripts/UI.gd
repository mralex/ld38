extends Panel

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var simNode
var rootNode

signal speed_normal
signal speed_fast
signal speed_pause
signal mode_change

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	rootNode = get_parent()
	rootNode.connect("cursor_update", self, "_cursor_updated")
	
	simNode = get_node("../SimNode")
	simNode.clock.connect("tick", self, "_tick")
	
	get_node("VButtonArray").connect("button_selected", self, "_on_mode_button_selected")

func update_tile_label(tilePos):
	var tileLabel = get_node("TileLabel")
	var tile = simNode.map.get_tile(tilePos.x, tilePos.y)
	
	if tile == null:
		return

	tileLabel.set_text("(%s,%s)\n%s" % [tilePos.x, tilePos.y, tile.type_string()])

func _cursor_updated(tilePos):
	if tilePos.x < 0 or tilePos.y < 0 or tilePos.x > simNode.map.width - 1 or tilePos.y > simNode.map.height - 1:
		return
	
	update_tile_label(tilePos)

func update_date_time(minutes):
	var timeLabel = get_node("DateLabel")

	var hours = minutes / 60
	var days = hours / 24 + 1
	var years = days / 364 + 1 

	timeLabel.set_text("Year: %s, Day: %s, %s:%s" % [years, days % 365, hours % 24, minutes % 60])

func update_money():
	var moneyLabel = get_node("MoneyLabel")
	
	moneyLabel.set_text("$25")

func _tick():
	update_date_time(simNode.clock.minutes)
	update_money()

func _on_mode_button_selected(index):
	emit_signal("mode_change", index)

func _on_NormalButton_button_up():
	emit_signal("speed_normal")

func _on_FastButton_button_up():
	emit_signal("speed_fast")

func _on_PauseButton_button_up():
	emit_signal("speed_pause")
