extends Node


signal register_player
signal player_connected
signal player_disconnected
signal connect_succeeded
signal connect_failed
signal server_disconnected

var player_info = {"username": ""}

var players = {}

var enable : bool = false

var master_server = false

var port : int

remote func _register_player(id, info):
	
	print("_register_player id: ", id, ", info: ", info)
	
	# If I'm the server, let the new guy know about existing players
	if get_tree().is_network_server():
		# Send my info to new player
		rpc_id(id, "_register_player", 1, player_info)
		# Send the info of existing players
		for peer_id in players:
			rpc_id(id, "_register_player", peer_id, info)
			rpc_id(peer_id, "_register_player", id, info)
	
	# Store the info
	players[id] = info
	
	emit_signal("register_player", id, info)

func _player_connected(id):
	print("_player_connected ", id )
	emit_signal("player_connected", id)
	pass

func _player_disconnected(id):
	print("player disconnected, id: ", id)
	players.erase(id) # Erase player from info
	emit_signal("player_disconnected", id)

func _connect_succeeded():
	print("connected_succeeded");
	
	enable = true
	
	# Send my ID and info to all the other peers
	rpc("_register_player", get_tree().get_network_unique_id(), player_info)
	
	emit_signal("connect_succeeded", get_tree().get_network_unique_id(), player_info)

func _connect_fail():
	
	print("_connect_failed")
	enable = false
	emit_signal("connect_failed")

func _server_disconnected():
	print("_server_disconnected")
	enable = false
	emit_signal("server_disconnected")

func _ready():
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connect_succeeded")
	get_tree().connect("connection_failed", self, "_connect_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
