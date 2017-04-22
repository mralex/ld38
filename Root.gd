extends Node2D

signal cursor_update
signal cursor_clicked

var simNode
var uiNode

var isMouseDown = false

enum CURSOR_MODE {
	DIG,
	PATH,
	PLANT,
	FILL_WATER,
	GRASS,
	MOW_GRASS,
}

var mode = CURSOR_MODE.DIG

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
	
	if isMouseDown:
		emit_signal("cursor_clicked", tilePos)

func _input(ev):
	if ev.type == InputEvent.MOUSE_BUTTON && ev.is_action_pressed("left_click"):
		#var tilePos = tile_at_pos(ev.pos)
		#emit_signal("cursor_clicked", tilePos)
		isMouseDown = true
	elif ev.type == InputEvent.MOUSE_BUTTON && ev.is_action_released("left_click"):
		isMouseDown = false

func position_cursor(tilePos):
	var cursorNode = get_node("MapCursor")
	
	cursorNode.set_pos(tilePos * 32)

func connect_ui_signals():
	uiNode.connect("speed_normal", self, "_set_speed_normal")
	uiNode.connect("speed_fast", self, "_set_speed_fast")
	uiNode.connect("speed_pause", self, "_set_speed_pause")
	uiNode.connect("mode_change", self, "_set_mode")
	self.connect("cursor_clicked", self, "_interact_tile")

func _set_speed_normal():
	simNode.clock.set_speed(1)

func _set_speed_fast():
	simNode.clock.set_speed(2)

func _set_speed_pause():
	simNode.clock.set_speed(0)

func _set_mode(m):
	mode = m

func _interact_tile(tilePos):
	if mode == CURSOR_MODE.DIG:
		simNode.map.reset_tile(tilePos.x, tilePos.y)
	elif mode == CURSOR_MODE.PATH:
		simNode.map.lay_path(tilePos.x, tilePos.y)
	elif mode == CURSOR_MODE.MOW_GRASS:
		simNode.map.mow_grass(tilePos.x, tilePos.y)
