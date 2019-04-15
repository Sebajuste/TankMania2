extends KinematicBody

var instanced_shell = preload("res://models/tank_shell/tank_shell.tscn")

var instanced_fire = preload("res://effects/Fire.tscn")

const GRAVITY = -9.8

const ACCEL= 2
const DEACCEL= 4

export (float) var max_speed = 20
export (float) var rotation_speed  = 1

export (float) var turret_rotation_speed = 4

export (int) var max_health = 10

signal health_changed
signal damaged
signal destroyed
signal main_gun_reloading

slave var health setget set_health

slave var velocity = Vector3()
var move_target = Vector3()

slave var target_dir = Vector3() setget set_target_dir

slave var alive = true setget _set_alive

var _main_gun_ready = true

var _fire = null


slave var slave_global_transform = Transform()


func set_target_dir(value):
	target_dir = value
	pass

master func reset():
	
	if mp_state.enable and not is_network_master():
		return
	
	alive = true
	health = max_health
	velocity = Vector3()
	
	if mp_state.enable:
		rset("alive", alive)
		rset("health", health)
		rset("velocity", velocity)
	
	if _fire != null:
		_fire.queue_free()
	$EngineSound.playing = true

remote func set_health(newHealth):
	
	if mp_state.enable and is_network_master():
		rset("health", newHealth)
	
	if newHealth > max_health:
		health = max_health
	else:
		health = newHealth
	emit_signal("health_changed", health * 100 / max_health)
	
	if health <= (max_health / 2):
		$Smoke.visible = true
	else:
		$Smoke.visible = false
	

remote func enable_headlights(value):
	
	$Headlights.visible = value
	
	if mp_state.enable and is_network_master():
		rpc("enable_headlights", value)
	


remote func main_shoot():
	
	if not alive:
		return
	
	if mp_state.enable and is_network_master():
		rpc("main_shoot")
	
	if _main_gun_ready:
		_main_gun_ready = false
		$MainGunTimer.start()
		
		var dir = ($Turret/Muzzle.global_transform.origin - $Turret.global_transform.origin).normalized()
		
		var shell = instanced_shell.instance()
		shell.set_network_master( get_network_master() )
		
		var root = get_tree().get_root()
		root.add_child(shell)
		
		shell.start( $Turret/Muzzle.global_transform.origin , dir, self)
		
		#$FireSound.play()
		$AnimationPlayer.play("fire")
		


remote func destroy():
	
	if mp_state.enable and is_network_master():
		rpc("destroy")
	
	alive = false
	
	if _fire == null:
		_fire = instanced_fire.instance()
		add_child(_fire)
		_fire.name = "Fire"
		_fire.transform.origin = Vector3(0, 2, 0)
	
	$EngineSound.playing = false
	
	emit_signal("destroyed")


func _set_alive(newValue):
	alive = newValue
	if alive and _fire != null:
		_fire.queue_free()

master func _repair(value):
	
	if health + value > max_health:
		set_health(max_health)
	else:
		set_health(health + value)
	
	if not alive:
		alive = true
		rset("alive", true)
	
	if _fire != null:
		_fire.queue_free()
	

master func _take_damage(damage, by_who):
	
	if not alive:
		return
	
	set_health(health - damage)
	
	if health > 0:
		emit_signal("health_changed", health * 100 / max_health)
	else:
		emit_signal("health_changed", 0)
		if mp_state.enable:
			rpc("destroy")
		destroy()
	
	emit_signal("damaged", damage, by_who)
	


func _control(delta):
	pass

func _control_result(hvel):
	pass

func _ready():
	
	health = max_health
	emit_signal("health_changed", 100)

func _exit_tree():
	$EngineSound.stop()

func _process(delta):
	
	if not $MainGunTimer.is_stopped():
		
		var percent = 100 - ($MainGunTimer.time_left * 100) / $MainGunTimer.wait_time
		
		emit_signal("main_gun_reloading", $MainGunTimer.time_left, percent);
	

func _physics_process(delta):
	
	if not alive:
		return
	
	_control(delta)
	
	# Move Turret
	
	var target_pos = $Turret.global_transform.origin + target_dir
	if $Turret.global_transform.origin != target_pos:
		var rotTransform = $Turret.global_transform.looking_at(target_pos, Vector3(0, 1, 0))
		var thisRotation = Quat($Turret.global_transform.basis).slerp(rotTransform.basis, turret_rotation_speed * delta)
		$Turret.global_transform = Transform(thisRotation, $Turret.global_transform.origin)
	
	
	
	# Move Tank
	
	velocity.y += delta * GRAVITY
	
	var hvel = velocity
	hvel.y = 0
	
	var accel = DEACCEL
	if move_target.dot(hvel) > 0:
		accel = ACCEL
	
	hvel = hvel.linear_interpolate(move_target, accel * delta)
	
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
	
	
	
	$EngineSound.pitch_scale = 0.6 + (hvel.length() / max_speed) * 0.7
	
	_control_result(hvel)
	
	if mp_state.enable:
		if is_network_master():
			rset_unreliable("velocity", velocity)
			rset_unreliable("slave_global_transform", global_transform)
		else:
			global_transform = slave_global_transform


func _on_MainGunTimer_timeout():
	_main_gun_ready = true
	emit_signal("main_gun_reloading", 0, 100);
	$MainGunTimer.stop()
