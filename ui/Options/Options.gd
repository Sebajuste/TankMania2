extends Control


onready var resolution_select = $MarginContainer/Panel/MarginContainer/VBoxContainer/Resolution/HBoxContainer/Control/ResolutionList

onready var fullscreen_checkbox = $MarginContainer/Panel/MarginContainer/VBoxContainer/Fullscreen/HBoxContainer/Fullscreen
onready var antialiasing_checkbox = $MarginContainer/Panel/MarginContainer/VBoxContainer/Antialiasing/HBoxContainer/Antialiasing


signal exited

var display = {"h" : 0,"w":0}
var fullscreen
var antialiasing = true
var vsync = true

var audio = Vector3()
var muted = false

func reload():
	
	display.h = configuration.Settings.Display.HEIGHT
	display.w = configuration.Settings.Display.WIDTH
	fullscreen = configuration.Settings.Display.FullScreen
	antialiasing = configuration.Settings.Display.Antialiasing
	
	for index in resolution_select.get_item_count():
		var text = resolution_select.get_item_text(index)
		var res = text.split("x")
		
		if res[1] == String(display.h) && res[0] == String(display.w):
			resolution_select.select(index)
		
	
	print("configuration", configuration.Settings)
	print("antialiasing_checkbox: ", antialiasing_checkbox)
	print("antialiasing: ", antialiasing)
	
	fullscreen_checkbox.pressed = fullscreen
	antialiasing_checkbox.pressed = antialiasing
	
	
	
	
	pass

func _ready():
	reload()

func _on_Fullscreen_toggled(button_pressed):
	
	fullscreen = button_pressed
	


func _on_ResolutionList_item_selected(index):
	
	var res = resolution_select.get_item_text(index).split("x")
	display.w = res[0]
	display.h = res[1]
	


func _on_ApplyButton_pressed():
	
	configuration.update_Settings(display.h, display.w, fullscreen, vsync, antialiasing, audio, muted)
	


func _on_ExitButton_pressed():
	
	emit_signal("exited")
	
	pass # replace with function body


func _on_Antialiasing_toggled(button_pressed):
	
	antialiasing = button_pressed
	
