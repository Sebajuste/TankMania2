extends "res://scenes/Game.gd"

var instanced_tank = preload("res://models/FV510-Warrior/Warrior.tscn")

var instanced_tank_player = preload("res://models/FV510-Warrior/PlayerWarrior.tscn")

var instanced_tank_ennemy = preload("res://models/FV510-Warrior/EnnemyWarrior.tscn")

var instanced_military_crate = preload("res://models/MilitaryCrate/MilitaryCrate.tscn")


var _total_goal_player = 0

func create_ennemy(config):
	
	print("create_ennemy", config)
	
	var ennemy_tank = instanced_tank_ennemy.instance()
	
	if config.master_id == get_tree().get_network_unique_id():
		ennemy_tank = instanced_tank_ennemy.instance()
	else:
		ennemy_tank = instanced_tank.instance()
	
	ennemy_tank.add_to_group("ennemy")
	$Ennemies.add_child(ennemy_tank)
	ennemy_tank.set_name(config.name)
	ennemy_tank.transform.origin = $Environment/GridMap._get_global_position( config.position )
	ennemy_tank.set_network_master(config.master_id)
	

func create_crate(config):
	
	print("create_crate", config)
	
	var crate = instanced_military_crate.instance()
	$Supply.add_child(crate)
	crate.set_name(config.name)
	crate.transform.origin = $Environment/GridMap._get_global_position( config.position )
	crate.set_network_master(config.master_id)
	


#func _clear_level():
#	
#	for index in range($Supply.get_child_count()):
#		$Supply.get_child(index).queue_free()
#	
#	for index in range($Ennemies.get_child_count()):
#		$Ennemies.get_child(index).queue_free()
#	
#	print("Level cleared")
#	

#func _generate_level(config):
#	
#	$Environment/GridMap.start_position = config.start_pos
#	$Environment/GridMap.gen_seed = config.gen_seed
#	$Environment/GridMap.size = config.size
#	$Environment/GridMap.generate()

func _set_player_position(config):
	
	#$Environment/StartPoints.global_transform.origin = $Environment/GridMap._get_global_position( config.start_pos )
	
	for id in config.spawn_points:
		var player = $Players.get_node( str(id) )
		player.global_transform.origin = config.spawn_points[id]
		player.global_transform.origin.y = 5
		player.reset()
		print("player ", id, " at pos ", config.spawn_points[id])
	
	#for index in range($Players.get_child_count()):
	#	var player = $Players.get_child(index)
	#	print("player ", player.name, " at ", $Environment/GridMap._get_global_position( config.startPos ) )
	#	player.global_transform.origin = $Environment/GridMap._get_global_position( config.startPos )


func _create_objects_level(config):
	
	# Create ennemies
	
	for index in range( config.ennemies.size() ):
		
		var ennemy_config = config.ennemies[index]
		create_ennemy(ennemy_config)
	
	# Create crates
	
	for index in range( config.crates.size() ):
		var crate_config = config.crates[index]
		create_crate(crate_config)
	

remote func pre_start_game(config):
	
	print("pre_start_game", config)
	
	set_level( config.level )
	
	# Remove all previous assets
	
	clear_level()
	
	# Generate World
	
	generate_level(config.gen_seed, config.size, config.start_pos)
	
	# Position Goal
	
	$Goal.transform.origin = $Environment/GridMap._get_global_position( config.goal_position )
	
	# Positions Players
	
	_set_player_position(config)
	
	# Create objects
	
	_create_objects_level(config)
	

var ennemy_counter = 0
var crate_counter = 0

func _create_objects_config(config):
	
	print("create_objects")
	
	var ennemies = Array()
	var crates = Array()
	
	# Create Ennemies and Crate
	
	var max_deep = $Environment/GridMap.get_max_deep()
	
	for index in range( $Environment/GridMap.cells.size() ):
		
		var cell = $Environment/GridMap.cells[index]
		
		if max_deep == cell.deep:
			
			config["goal_position"] = cell.position
		
		if max_deep - cell.deep > 2:
			
			if cell.childs.size() > 1:
				
				var ennemy_config = {"master_id": 1, "name": "tank_" + str(ennemy_counter), "position": cell.position}
				ennemies.append(ennemy_config)
				ennemy_counter += 1
			
			if cell.childs.size() == 0:
				
				var crate_config = {"master_id": 1, "name": "create_" + str(crate_counter), "position": cell.position}
				crates.append(crate_config)
				crate_counter += 1
	
	print( ennemies )
	print( crates )
	
	config["ennemies"] = ennemies
	config["crates"] = crates



func _configure_start_game():
	
	print("_configure_start_game")
	
	_total_goal_player = 0
	
	
	# Call to pre-start game with the spawn points
	
	var start_pos = Vector3( randi() % ($Environment/GridMap.size-1) + 1, 0, randi() % ($Environment/GridMap.size-1) + 1 )
	
	var config = {"level": level, "gen_seed": randi(), "size": world_size, "start_pos": start_pos}
	
	clear_level()
	generate_level(config.gen_seed, config.size, config.start_pos)
	
	var spawn_points = {}
	var global_start_pos = $Environment/GridMap._get_global_position( start_pos )
	spawn_points[1] = $Environment/StartPoints/Point1.transform.origin + global_start_pos
	var index = 1
	for p in mp_state.players:
		spawn_points[p] = $Environment/StartPoints.get_child(index).transform.origin + global_start_pos
		index += 1
	config["spawn_points"] = spawn_points
	
	_create_objects_config(config)
	
	print("Final config : ", config)
	rpc("pre_start_game", config)
	
	#
	# Self Configuration
	#
	
	$Goal.transform.origin = $Environment/GridMap._get_global_position( config.goal_position )
	
	# Positions Players
	
	_set_player_position(config)
	
	# Create objects
	
	_create_objects_level(config)
	

func _create_player(p_id):
	
	print("_create_player ", p_id)
	
	var tank
	
	if p_id == get_tree().get_network_unique_id():
		tank = instanced_tank_player.instance()
		
		print("Create own tank");
		
		# Connect to HUD
		
		tank.connect("health_changed", $HUD, "_on_Player_health_changed")
		tank.connect("main_gun_reloading", $HUD, "_on_Player_main_gun_reloading")
		
	else:
		tank = instanced_tank.instance()
	
	tank.add_to_group("player")
	tank.set_name(str(p_id)) # Use unique ID as node name
	#tank.position = config.spawn_points[p_id]
	
	tank.set_network_master(p_id) #set unique id as master
	
	$Players.add_child(tank)

remote func _init_game():
	
	print("_init_game");
	
	for p_id in mp_state.players:
		_create_player(p_id)
	_create_player( get_tree().get_network_unique_id() )
	
	

func _on_disconnect():
	
	get_tree().change_scene("res://ui/Multiplayer/MultiplayerMenu.tscn")
	

func _ready():
	
	print("Multiplayer level loading");
	
	
	if get_tree().is_network_server():
		
		#for p_id in mp_state.players:
		#	rpc_id(p_id, "_init_game")
		rpc("_init_game")
		_init_game()
		
		_configure_start_game()
	else:
		
		mp_state.connect("server_disconnected", self, "_on_disconnect")
		
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _exit_tree():
	
	get_tree().set_network_peer(null)
	

func _on_Goal_body_entered(body):
	
	if not body.is_in_group("player"):
		return
	
	print("_on_Goal_body_entered ", _total_goal_player)
	print("mp_state.players.size()", mp_state.players.size())
	
	if get_tree().is_network_server():
		_total_goal_player += 1
		
		var reach_player = 0
		for index in range($Players.get_child_count()):
			
			var p = $Players.get_child(index)
			if p.alive:
				reach_player += 1
		
		if _total_goal_player == reach_player:
			
			for index in range($Players.get_child_count()):
				var player = $Players.get_child(index)
				print("call rpc repair")
				player.rpc("_repair", player.max_health / 2)
			
			level += 1
			
			world_size += 1
			
			_configure_start_game()
			


func _on_Goal_body_exited(body):
	
	if not body.is_in_group("player"):
		return
	
	print("_on_Goal_body_exited")
	
	if get_tree().is_network_server():
		
		if _total_goal_player > 0:
			_total_goal_player -= 1

