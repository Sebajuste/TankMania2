extends Node


signal level_changed

var level = 1 setget set_level

var world_size = 10

var _config = {}
var _elapsed_time = 0
var _score = 0 setget set_score

func set_level(newValue):
	level = newValue
	emit_signal("level_changed", level)

func set_score(newValue):
	_score = newValue
	$Level.set_score(_score)

func clear_level():
	
	_elapsed_time = 0
	set_score(0)
	
	$Level.set_score(_score)
	
	for index in range($Supply.get_child_count()):
		$Supply.get_child(index).queue_free()
	
	for index in range($Ennemies.get_child_count()):
		$Ennemies.get_child(index).queue_free()
	
	print("Level cleared")


func generate_level(gen_seed, size, start_pos):
	
	$Environment/GridMap.start_position = start_pos
	$Environment/GridMap.gen_seed = gen_seed
	$Environment/GridMap.size = size
	$Environment/GridMap.generate()


func _create_objects_config(config):
	pass

func _create_objects_level(config):
	pass

func _configure_start_game():
	
	print("_configure_start_game")
	
	
	# Call to pre-start game with the spawn points
	
	var start_pos = Vector3( randi() % ($Environment/GridMap.size-1) + 1, 0, randi() % ($Environment/GridMap.size-1) + 1 )
	
	_config = {"gen_seed": randi(), "size": 10, "start_pos": start_pos}
	
	clear_level()
	generate_level(_config.gen_seed, _config.gen_size, _config.start_pos)
	
	_create_objects_config(_config)
	
	#
	# Self Configuration
	#
	
	$Goal.transform.origin = $Environment/GridMap._get_global_position( _config.goal_position )
	
	# Create objects
	
	_create_objects_level(_config)
	

func _open_menu():
	
	get_node("MainMenu").visible = not get_node("MainMenu").visible
	

func _on_MainMenu_resumed():
	
	$CrossHair.reset()
	

func _ready():
	
	get_node("MainMenu").visible = false
	

func _process(delta):
	
	_elapsed_time += delta
	
	$Level.set_time( int(_elapsed_time*1000) )
	

func _input(event):
	
	if event is InputEventKey and event.scancode == KEY_ESCAPE and event.pressed:
		_open_menu()
	
