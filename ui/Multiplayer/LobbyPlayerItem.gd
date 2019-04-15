extends Panel

var player_info setget set_playerinfo
var ready setget set_ready

onready var _username = $MarginContainer/HBoxContainer/UsernameLabel
onready var _state = $MarginContainer/HBoxContainer/StateLabel


func set_playerinfo(newPlayer):
	
	player_info = newPlayer
	
	_username.text = player_info.username
	#$HBoxContainer/ColorRect.color = player_info.color


func set_ready(newStatus):
	ready = newStatus
	
	if ready:
		_state.text = "Ready"
		_state.self_modulate = Color(0.4, 0.8, 0.2, 1)
	else:
		_state.text = "Waiting"
		_state.self_modulate = Color(0.8, 0.4, 0.2, 1)
	

func _ready():
	
	set_ready(false)
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
