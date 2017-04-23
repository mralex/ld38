extends Panel

var simNode
var rootNode

var constructionUI
var jobUI

signal speed_normal
signal speed_fast
signal speed_pause
signal mode_change
signal construction_mode_change
signal job_mode_change

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	rootNode = get_parent()
	rootNode.connect("cursor_update", self, "_cursor_updated")

	simNode = get_node("../SimNode")
	simNode.clock.connect("tick", self, "_tick")

	constructionUI = get_node("ConstructionMenu")
	constructionUI.connect("button_selected", self, "_on_construction_button_selected")

	jobUI = get_node("JobMenu")
	jobUI.connect("button_selected", self, "_on_job_button_selected")

	get_node("JudgeDialog").connect("confirmed", self, "_on_close_judge_popup")

	get_node("Menu").connect("button_selected", self, "_on_mode_button_selected")

func update_tile_label(tilePos):
	var tileLabel = get_node("TileLabel")
	var tile = simNode.map.get_tile(tilePos.x, tilePos.y)

	if tile == null:
		tileLabel.set_text("")
		return

	tileLabel.set_text("(%s,%s)\n%s (Age: %s)\n(Growth rate: %.2f)\n(Growth amount: %.2f)\n(Distance to water: %d)" % [tilePos.x, tilePos.y, tile.type_string(), tile.age, tile.growth_rate, tile.growth_amount, tile.distance_to_water])

func _cursor_updated(tilePos):
	if tilePos.x < 0 or tilePos.y < 0 or tilePos.x > simNode.map.width - 1 or tilePos.y > simNode.map.height - 1:
		return

	update_tile_label(tilePos)

func update_date_time(minutes):
	var timeLabel = get_node("DateLabel")

	var hours = minutes / 60
	var days = hours / 24 + 1
	var years = days / 364 + 1

	timeLabel.set_text("Year: %s, Day: %s, %02d:%02d" % [years, days % 365, hours % 24, minutes % 60])

func update_money():
	var moneyLabel = get_node("MoneyLabel")

	moneyLabel.set_text("$%.2f" % simNode.map.money)

func update_rating(rating):
	var ratingLabel = get_node("RatingLabel")
	ratingLabel.set_text("Rating: %.2f" % rating)

func _tick():
	update_date_time(simNode.clock.minutes)
	update_money()
	update_rating(simNode.map.rating)
	check_judge()

func _on_mode_button_selected(index):
	if index == 1:
		constructionUI.show()
	else:
		constructionUI.hide()
	
	if index == 2:
		jobUI.show()
	else:
		jobUI.hide()

	emit_signal("mode_change", index)

func _on_construction_button_selected(index):
	emit_signal("construction_mode_change", index)

func _on_job_button_selected(index):
	emit_signal("job_mode_change", index)

func _on_NormalButton_button_up():
	emit_signal("speed_normal")

func _on_FastButton_button_up():
	emit_signal("speed_fast")

func _on_PauseButton_button_up():
	emit_signal("speed_pause")

func check_judge(msg=""):
	if simNode.clock.ticks > 0 && simNode.clock.ticks % simNode.clock.ticksPerDay == 0:
		# Show judgement every day
		var judgementPopup = get_node("JudgeDialog")
		judgementPopup.set_text("The neighbours think your garden is pretty nice. Keep up the good work!")
		judgementPopup.popup_centered()
		emit_signal("speed_pause")

func _on_close_judge_popup():
	emit_signal("speed_normal")
