extends "res://scenes/Game.gd"

var instanced_ennemy_tank = preload("res://models/FV510-Warrior/EnnemyWarrior.tscn")

var instanced_military_crate = preload("res://models/MilitaryCrate/MilitaryCrate.tscn")

var _start_pos
var _start_health

var _max_heatlh_ennemy_tank = 3

var _total_tank = 0
var _total_damage = 0
var _total_tank_destroyed = 0

func get_path_nav(from, to):
	var begin = $Navigation.get_closest_point( from )
	var end = $Navigation.get_closest_point(to)
	
	var p = $Navigation.get_simple_path(begin, end)
	
	var path = Array(p)
	path.append(end)
	path.invert()
	
	return path

func clear_level():
	.clear_level()
	
	_total_tank = 0
	_total_damage = 0
	_total_tank_destroyed = 0

func _generate_world(startPos):
	
	# Remove all previous assets
	
	clear_level()
	
	# Init the new scene
	
	print("start pos", $Environment/GridMap._get_global_position( startPos ) )
	
	$Player.global_transform.origin = $Environment/GridMap._get_global_position( startPos )
	$Player.global_transform.origin.y = 2
	
	$Environment/GridMap.start_position = startPos
	
	$Environment/GridMap.generate()
	
	# Generate Ennemies & Crates
	
	var max_deep = $Environment/GridMap.get_max_deep()
	
	for index in range( $Environment/GridMap.cells.size() ):
		
		var cell = $Environment/GridMap.cells[index]
		
		if max_deep == cell.deep:
			$Goal.transform.origin = $Environment/GridMap._get_global_position( cell.position )
		
		if max_deep - cell.deep > 2:
			
			if cell.childs.size() > 1:
				var ennemy_tank = instanced_ennemy_tank.instance()
				$Ennemies.add_child(ennemy_tank)
				ennemy_tank.connect("damaged", self, "_on_ennemy_damaged")
				ennemy_tank.connect("destroyed", self, "_on_ennemy_destroyed")
				ennemy_tank.max_health = _max_heatlh_ennemy_tank
				ennemy_tank.health = _max_heatlh_ennemy_tank
				ennemy_tank.transform.origin = $Environment/GridMap._get_global_position( cell.position )
				ennemy_tank.transform.origin.y = 2
				_total_tank += 1
			
			if cell.childs.size() == 0:
				
				var crate = instanced_military_crate.instance()
				$Supply.add_child(crate)
				crate.transform.origin = $Environment/GridMap._get_global_position( cell.position )
				
				print("crate created")
	

func _open_menu():
	._open_menu()
	get_tree().paused = true

func _on_MainMenu_resumed():
	._on_MainMenu_resumed()
	get_tree().paused = false
	

func _ready():
	
	$GameOver.visible = false
	get_node("MainMenu").visible = false
	
	_start_pos = Vector3(1, 0, 1)
	
	set_level(1)
	
	_generate_world( _start_pos )
	
	$Player.health = $Player.max_health
	_start_health = $Player.max_health



#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_ennemy_destroyed():
	set_score( _score + 10 )
	_total_tank_destroyed += 1

func _on_ennemy_damaged(damage, by_who):
	
	if by_who == $Player:
		
		set_score( _score + damage )
		_total_damage += damage
	
	


func _on_Goal_body_entered(body):
	
	get_tree().paused = true
	
	if _total_tank_destroyed == _total_tank:
		_score += 100
	
	
	var time = int(_elapsed_time * 1000)
	
	var score = {"level": level, "time": time, "score": _score, "total_damage": _total_damage, "tank_destroyed": _total_tank_destroyed, "total_tank": _total_tank}
	
	$Score.set_score(score)
	
	$Score.visible = true
	

func _on_Player_destroyed():
	
	$GameOver.visible = true
	


func _on_Score_next():
	
	
	$Environment/GridMap.gen_seed += 1
	$Environment/GridMap.size += 2
	
	_start_pos = Vector3( randi() % ($Environment/GridMap.size-1) + 1, 0, randi() % ($Environment/GridMap.size-1) + 1 )
	 
	set_level( level + 1)
	
	_max_heatlh_ennemy_tank += 2
	if _max_heatlh_ennemy_tank > 10:
		_max_heatlh_ennemy_tank = 10
	
	_generate_world( _start_pos )
	
	var health = $Player.health
	$Player.reset()
	$Player.health = health + $Player.max_health / 2
	_start_health = $Player.health
	
	
	_on_MainMenu_resumed()
	$Score.visible = false
	


func _on_Score_retry():
	
	_generate_world( _start_pos )
	
	$Player.health = _start_health
	
	_on_MainMenu_resumed()
	$Score.visible = false
	


func _on_GameOver_restarted():
	
	_on_MainMenu_resumed()
	$Player.reset()
	
	_ready()
	
