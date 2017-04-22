extends Node2D

signal cursor_update

var simNode
var uiNode

func _ready():
	simNode = get_node("SimNode")
	uiNode = get_node("UI")
	
	connect_ui_signals()
	
	set_fixed_process(true)
	
func _fixed_process(delta):
	var position = get_viewport().get_mouse_pos()
	var tilePos = Vector2(0, 0)
	# Is mouse cursor over the tile map?
	if position.x <= 1024:
		# Figure out which tile we're over
		tilePos = Vector2(floor(position.x / 32), floor(position.y / 32))
	
	position_cursor(tilePos)
	emit_signal("cursor_update", tilePos)

func position_cursor(tilePos):
	var cursorNode = get_node("MapCursor")
	
	cursorNode.set_pos(tilePos * 32)

func connect_ui_signals():
	uiNode.connect("speed_normal", self, "_set_speed_normal")
	uiNode.connect("speed_fast", self, "_set_speed_fast")
	uiNode.connect("speed_pause", self, "_set_speed_pause")

func _set_speed_normal():
	simNode.clock.set_speed(1)

func _set_speed_fast():
	simNode.clock.set_speed(2)

func _set_speed_pause():
	simNode.clock.set_speed(0)