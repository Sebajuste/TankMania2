extends CanvasLayer

var instanced_player_line = preload("res://ui/Multiplayer/LobbyPlayerItem.tscn")

var _udp

var _upnp

onready var _player_list = $MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/PlayerList
onready var _start_btn = $MarginContainer/Panel/MarginContainer/VBoxContainer/Header/StartButton
onready var _ready_btn = $MarginContainer/Panel/MarginContainer/VBoxContainer/Header/ReadyButton

func _add_or_update_line(id, info):
	
	var line #= $MarginContainer/VBoxContainer/PlayerList.get_node( str(id) )
	if _player_list.has_node( str(id) ):
		line = _player_list.get_node( str(id) )
	else:
		line = instanced_player_line.instance()
		_player_list.add_child(line)
	
	line.set_name( str(id)  )
	if info:
		line.player_info = info
	return line

remote func _start_game():
	
	get_tree().change_scene("res://scenes/Multiplayer.tscn")
	

remote func _player_ready(id, ready):
	
	print("_player_ready")
	
	var player_item = _add_or_update_line(id, null)
	
	player_item.ready = ready
	
	if get_tree().is_network_server():
		var total_ready = 0
		for index in range(_player_list.get_child_count()):
			
			var child = _player_list.get_child(index)
			
			if child.ready:
				total_ready += 1
		
		if total_ready > 1 and total_ready == _player_list.get_child_count():
			_start_btn.disabled = false
		else:
			_start_btn.disabled = true

remote func _register_player(id, info):
	
	_add_or_update_line(id, info)
	
	print("lobby -> register player id: ", id, ", info: ", info)
	
	
	if get_tree().is_network_server():
		
		rpc_id(id, "_player_ready", 1, true)
		
		for peer_id in mp_state.players:
			rpc_id(id, "_player_ready", peer_id, _player_list.get_node( str(peer_id) ).ready)

func _player_connected(id):
	print("_player_connected ", id)
	pass


func _player_disconnected(id):
	print("lobby -> player disconnected, id: ", id)
	
	var line = _player_list.get_node( str(id) )
	if line:
		line.queue_free()
	

func _on_disconnect():
	
	get_tree().change_scene("res://ui/Multiplayer/MultiplayerMenu.tscn")
	

func _send_info(host, port):
	
	var info = {"name": "Room", "host": IP.get_local_addresses(), "port": 34567, "currentPlayers": 1, "maxPlayers": 4}
	
	_udp.set_dest_address( host, port)
	_udp.put_packet( to_json(info).to_ascii() )
	

func _ready():
	
	print("Lobby ready")
	
	print("_ready player_info: ", mp_state.player_info)
	
	var id = get_tree().get_network_unique_id()
	_add_or_update_line(id, mp_state.player_info)
	
	if get_tree().is_network_server():
		
		#$HolePunching.resgister_server()
		
		_upnp = UPNP.new()
		_upnp.discover()
		
		var result = _upnp.add_port_mapping(mp_state.port, mp_state.port, "TankMania2")
		
		if result != UPNP.UPNP_RESULT_SUCCESS:
			print("error : ", result)
		
		# Listen for discover this room
		_udp = PacketPeerUDP.new()
		_udp.listen(3335)
		
		_start_btn.disabled = true
		_ready_btn.visible = false
		_player_list.get_node( str(id) ).ready = true
	else:
		_start_btn.visible = false
	
	
	mp_state.connect("register_player", self, "_register_player")
	mp_state.connect("player_connected", self, "_player_connected")
	mp_state.connect("player_disconnected", self, "_player_disconnected")
	mp_state.connect("server_disconnected", self, "_on_disconnect")
	
	if get_tree().is_network_server():
		_send_info("192.168.1.255", 3334)
	

func _exit_tree():
	
	if _upnp:
		_upnp.delete_port_mapping(mp_state.port)
	
	if _udp:
		_udp.close()
	

func _process(delta):
	
	if _udp and _udp.get_available_packet_count() > 0:
		var array_bytes = _udp.get_packet()
		var IP_CLIENT = _udp.get_packet_ip()
		var PORT_CLIENT = _udp.get_packet_port()
		
		var message = array_bytes.get_string_from_ascii()
		
		print("msg server: ", array_bytes.get_string_from_ascii(), " from ", IP_CLIENT, ":", PORT_CLIENT)
		
		if message == "Discover":
			
			_send_info(IP_CLIENT, PORT_CLIENT)
			



func _on_ReadyButton_pressed():
	
	print("_on_ReadyButton_pressed")
	
	var id = get_tree().get_network_unique_id()
	
	var state = not _player_list.get_node( str(id) ).ready
	
	rpc("_player_ready", id, state )
	_player_ready(id, state )
	


func _on_StartButton_pressed():
	
	if get_tree().is_network_server():
		get_tree().set_refuse_new_network_connections(true)
		rpc("_start_game")
		_start_game()
	



func _on_Exit_pressed():
	
	get_tree().get_meta("network_peer").close_connection()
	get_tree().set_network_peer(null)
	
	get_tree().change_scene("res://ui/Multiplayer/MultiplayerMenu.tscn")
	
