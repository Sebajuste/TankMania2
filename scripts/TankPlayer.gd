extends "res://scripts/Tank.gd"

var _is_moving = false

var _mouse_control = true

func _update_target(mouse_pos):
	
	# Get the 3D cursor position
	
	mouse_pos += Vector2(16, 16)
	
	var ray_length = 1000
	
	var camera = $Camera
	
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(from, to)
	
	# If available, set position as target direction
	if result:
		#print( result.collider.get_name() )
		target_dir = (result.position - $Turret.global_transform.origin)
		target_dir.y = 0
		target_dir = target_dir.normalized()
		if mp_state.enable and is_network_master():
			rset_unreliable("target_dir", target_dir)
	


func _control(delta):
	
	#if not is_network_master():
	#	return
	
	_is_moving = false
	
	# Rotation
	
	var rot = get_rotation()
	rot.x = 0
	rot.z = 0
	
	if(Input.is_action_pressed("turn_right")):
		rot += Vector3(0, -1, 0) * rotation_speed * delta
		_mouse_control = true
	
	if(Input.is_action_pressed("turn_left")):
		rot += Vector3(0,  1, 0) * rotation_speed * delta
		_mouse_control = true
	
	set_rotation(rot)
	
	
	# Move
	
	move_target = Vector3()
	
	if is_on_floor():
		
		if Input.is_action_pressed("forward"):
			move_target = Vector3(0, 0, -1).rotated(Vector3(0, 1, 0), rot.y)
			_mouse_control = true
		
		if Input.is_action_pressed("back"):
			move_target = Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), rot.y)
			_mouse_control = true
		
		if _mouse_control:
			move_target.y = 0
			move_target = move_target.normalized() * max_speed
			
		else:
			
			var cam_xform = $Camera.global_transform
			
			var xVal = Input.get_joy_axis(0, 0)
			var yVal = Input.get_joy_axis(0, 1)
			
			var joy_dir = Vector3(xVal, 0, yVal)
			
			print( joy_dir.length() )
			
			if xVal != 0:
				_is_moving = true
				move_target += xVal * cam_xform.basis[0]
			
			if yVal != 0:
				_is_moving = true
				move_target += yVal * cam_xform.basis[2]
			
			
			move_target.y = 0
			move_target = move_target.normalized() * (max_speed * joy_dir.length() )
	
	
	
	# Actions
	
	if _mouse_control:
		_update_target( get_viewport().get_mouse_position() )
		
	else:
		var joy_dir = Vector3(Input.get_joy_axis(0, 2), 0, Input.get_joy_axis(0, 3)).normalized()
		
		if joy_dir.x != 0 or joy_dir.z != 0:
			target_dir = joy_dir
			if mp_state.enable and is_network_master():
				rset_unreliable("target_dir", target_dir)
	
	
	if Input.is_action_just_pressed("main_fire"):
		main_shoot()
	

func _control_result(hvel):
	
	if _is_moving:
		var angle = atan2(hvel.x, hvel.z)
		var rot = get_rotation()
		rot.y = angle + deg2rad(180)
		set_rotation(rot)

func _process(delta):
	
	if Input.is_action_just_pressed("headlights"):
		
		enable_headlights( not $Headlights.visible )
		
	

func _physics_process(delta):
	
	var root = get_tree().get_root().get_node("Game")
	
	var lock_pos = $Turret/Muzzle.global_transform.translated(Vector3(0, 0, -100)).origin
	
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray( $Turret/Muzzle.global_transform.origin, lock_pos, [self] )
	
	if result and result.collider.is_in_group("ennemy"):
		root.get_node("CrossHair").set_target_lock(true)
	else:
		root.get_node("CrossHair").set_target_lock(false)
	

var _last_mouse_pos = null

func _input(event):
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	if _last_mouse_pos == null:
		_last_mouse_pos = mouse_pos
	
	# On each mouse mouvement
	if event is InputEventMouseMotion and _last_mouse_pos != mouse_pos:
		_last_mouse_pos = mouse_pos
		_mouse_control = true
	
	if event is InputEventJoypadMotion:
		_mouse_control = false
