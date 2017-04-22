extends Node2D

signal cursor_update
signal cursor_clicked

var simNode
var uiNode

func _ready():
	simNode = get_node("SimNode")
	uiNode = get_node("UI")
	
	connect_ui_signals()
	
	set_fixed_process(true)
	set_process_input(true)

func tile_at_pos(position):
	var tilePos = Vector2(0, 0)
	# Is mouse cursor over the tile map?
	if position.x <= 1024:
		# Figure out which tile we're over
		tilePos = Vector2(floor(position.x / 32), floor(position.y / 32))
	
	return tilePos

func _fixed_process(delta):
	var position = get_viewport().get_mouse_pos()
	var tilePos = tile_at_pos(position)
	
	position_cursor(tilePos)
	emit_signal("cursor_update", tilePos)

func _input(ev):
	if ev.type == InputEvent.MOUSE_BUTTON && ev.is_action_released("left_click"):
		var tilePos = tile_at_pos(ev.pos)
		emit_signal("cursor_clicked", tilePos)

func position_cursor(tilePos):
	var cursorNode = get_node("MapCursor")
	
	cursorNode.set_pos(tilePos * 32)

func connect_ui_signals():
	uiNode.connect("speed_normal", self, "_set_speed_normal")
	uiNode.connect("speed_fast", self, "_set_speed_fast")
	uiNode.connect("speed_pause", self, "_set_speed_pause")
	self.connect("cursor_clicked", self, "_reset_tile")

func _set_speed_normal():
	simNode.clock.set_speed(1)

func _set_speed_fast():
	simNode.clock.set_speed(2)

func _set_speed_pause():
	simNode.clock.set_speed(0)
	
func _reset_tile(tilePos):
	simNode.map.reset_tile(tilePos)