extends CanvasLayer

signal resumed

var visible setget set_visible

var _default_mouse_cursor = load("res://mouse_cursor.png")

func set_visible(value):
	
	visible = value
	$Panel.visible = value
	$MarginContainer.visible = value
	
	if visible:
		Input.set_custom_mouse_cursor(_default_mouse_cursor)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_ResumeButton_pressed():
	print("on resume")
	emit_signal("resumed")
	set_visible( false )
	

func _on_Button_pressed():
	
	set_visible( false )
	$Options.reload()
	$Options.visible = true
	

func _on_ReturnMenuButton_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://ui/Main/Main.tscn")
	

func _on_ExitGameButton_pressed():
	
	get_tree().quit()
	

func _on_Options_exited():
	
	set_visible( true )
	$Options.visible = false
	
