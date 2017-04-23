extends Node

func _ready():
	get_node("ButtonGroup/StartButton").connect("button_up", self, "_on_start_pressed")
	get_node("ButtonGroup/QuitButton").connect("button_up", self, "_on_quit_pressed")
	
func _on_start_pressed():
	get_tree().change_scene("res://Root.tscn")

func _on_quit_pressed():
	get_tree().quit()
