extends Spatial

export (int) var damage = 1
export (int) var speed = 100
export (float) var lifetime = 4

var velocity

var _shooter

var _exploded = false

func start(position, direction, shooter):
	
	_shooter = shooter
	
	var rotTransform = global_transform.looking_at(direction, Vector3(0, 1, 0))
	var thisRotation = Quat(global_transform.basis).slerp(rotTransform.basis, 1)
	global_transform = Transform(thisRotation, position)
	
	velocity = direction * speed
	
	$LifeTime.wait_time = lifetime
	$LifeTime.start()
	

func explode():
	$AnimationPlayer.play("Explode")
	_exploded = true
	visible = false


func _process(delta):
	
	if _exploded:
		return
	
	if velocity:
		global_transform.origin += velocity * delta
	

func _on_LifeTime_timeout():
	queue_free()

func _on_TankShell_body_entered(body):
	explode()
	if body.has_method("_take_damage") :
		
		if mp_state.enable:
			if is_network_master():
				print("expode, call take damage")
				body.rpc("_take_damage", damage, _shooter)
		else:
			print("expode, call take damage")
			body._take_damage(damage, _shooter)

