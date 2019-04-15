extends CanvasLayer


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Player_health_changed(value):
	
	$MarginContainer/Container/HealthContainer/HealthBar/Tween.interpolate_property(
		$MarginContainer/Container/HealthContainer/HealthBar, "value",
		$MarginContainer/Container/HealthContainer/HealthBar.value, value, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	$MarginContainer/Container/HealthContainer/HealthBar/Tween.start()
	

func _on_Player_main_gun_reloading( time, percent ):
	
	$MarginContainer/Container/ReloadContainer/ReloadBar.value = int(percent)
	
	pass # replace with function body
