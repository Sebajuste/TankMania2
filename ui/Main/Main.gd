extends CanvasLayer

var _default_mouse_cursor = load("res://mouse_cursor.png")

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	Input.set_custom_mouse_cursor(_default_mouse_cursor)
	
	pass


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_PlayButton_pressed():
	
	get_tree().change_scene("res://scenes/SinglePlayer.tscn")
	

func _on_Online_pressed():
	
	get_tree().change_scene("res://ui/Multiplayer/Matchmaking.tscn")
	

func _on_MultiplayerButton_pressed():
	
	get_tree().change_scene("res://ui/Multiplayer/MultiplayerMenu.tscn")
	

func _on_OptionButon_pressed():
	
	$Options.reload()
	$Options.visible = true
	

func _on_ExitButton_pressed():
	
	get_tree().quit()
	


func _on_Options_exited():
	
	$Options.visible = false
	



