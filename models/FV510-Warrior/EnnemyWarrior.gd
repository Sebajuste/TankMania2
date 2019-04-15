extends "res://scripts/Tank.gd"

export (int) var detect_radius = 40


var targets = Array()

var target = null
var last_target_pos

var move_path = null
var next_move_pos = null

func target_update():
	
	if not target and targets.size() > 0 and (not mp_state.enable or is_network_master()):
		target = targets.front()
	
	pass

func target_remove():
	
	if target:
		var idx = targets.find(target)
		if idx != -1:
			targets.remove(idx)
		target = null
		target_update()
	

func _take_damage(damage, shooter):
	
	._take_damage(damage, shooter)
	
	if not target and shooter.is_in_group("player") and (not mp_state.enable or is_network_master()):
		target = shooter
	

func _control(delta):
	
	if mp_state.enable and not is_network_master():
		return
	
	
	move_target = Vector3()
	
	if move_path != null and move_path.size() > 0:
		
		if next_move_pos == null:
			next_move_pos = move_path[ move_path.size() - 1 ]
			move_path.remove(move_path.size() - 1)
	
	if next_move_pos != null:
		
		# rotation to
		
		var rot = get_rotation()
		
		var rotTransform = self.global_transform.looking_at(next_move_pos, Vector3(0, 1, 0))
		var thisRotation = Quat(self.global_transform.basis).slerp(rotTransform.basis, rotation_speed * delta)
		self.global_transform = Transform(thisRotation, self.global_transform.origin)
		
		# move to
		
		var v = (self.global_transform.origin - next_move_pos )
		v.y = 0
		v = v.normalized()
		
		var forward = self.get_global_transform().basis.z
		var dot = forward.dot( v )
		
		if dot > 0.90:
			move_target = Vector3(0, 0, -1).rotated(Vector3(0, 1, 0), rot.y)
		
		move_target = move_target.normalized() * max_speed
		
		if abs( self.global_transform.origin.distance_to(next_move_pos) ) < 20:
			next_move_pos = null
	


func _ready():
	
	$DetectionArea/CollisionShape.shape.radius = detect_radius
	
	

func _process(delta):
	
	if not alive or (mp_state.enable and not is_network_master()):
		return
	
	if target:
		
		if not target.is_inside_tree():
			target_remove()
			target_update()
			return
		
		if ("alive" in target) and not target.alive:
			target_remove()
			target_update()
			return
		
		var target_position = target.global_transform.origin
		
		target_dir = (target_position - $Turret.global_transform.origin)
		target_dir.y = 0
		target_dir = target_dir.normalized()
		
		if mp_state.enable and is_network_master():
			rset_unreliable("target_dir", target_dir)
		
		if mp_state.enable and is_network_master():
			#rset("target_position", target_position)
			pass
		
		var space_state = get_world().direct_space_state
		var hit = space_state.intersect_ray(self.global_transform.origin + Vector3(0, 1, 0), target_position + Vector3(0, 1, 0))
		
		if hit and hit.collider == target:
			
			last_target_pos = target_position
			
			if abs( self.global_transform.origin.distance_to(target_position) ) > 20:
				next_move_pos = target_position
			
			var v = (self.global_transform.origin - target_position )
			v.y = 0
			v = v.normalized()
			
			var forward = $Turret.get_global_transform().basis.z
			var dot = forward.dot( v )
			
			if dot > 0.99:
				main_shoot()
			
		else:
			next_move_pos = last_target_pos
	
	


func _on_DetectionArea_body_entered(body):
	
	if mp_state.enable and not is_network_master():
		return
	
	if body.is_in_group("player"):
		targets.append(body)
		target_update()
	

func _on_DetectionArea_body_exited(body):
	
	if mp_state.enable and not is_network_master():
		return
	
	var idx = targets.find(body)
	if idx != -1:
		targets.remove(idx)
	
	if target == body:
		target = null
		target_update()
	

