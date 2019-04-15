extends Area

export (int) var repair = 2

var rotation_speed = 2

var _rotation_angle = 0

slave func _remove():
	print("crate removed")
	queue_free()

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	
	_rotation_angle += rotation_speed * delta
	
	var rot = Quat(Vector3(0, 1, 0), _rotation_angle)
	var t = get_transform()
	set_transform(Transform(rot, t.origin))
	

func _on_MilitaryCrate_body_entered(body):
	
	if not body.is_in_group("player"):
		return
	
	print("repair ", body, " from crate")
	
	if mp_state.enable:
		if is_network_master():
			print("event repair from master crate")
			body.rpc("_repair", repair)
			rpc("_remove")
			_remove()
	elif ("health" in body):
		body.health += repair
		_remove()
	
	
