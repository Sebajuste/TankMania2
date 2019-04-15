extends CanvasLayer

var instanced_room_item = preload("res://ui/Multiplayer/RoomItem.tscn")

const SERVER_IP = "127.0.0.1"
const SERVER_PORT = 34567

const MAX_PLAYERS = 4

var _udp = PacketPeerUDP.new()

onready var _room_list = $MarginContainer/Panel/VBoxContainer/Content/MarginContainer/Panel/ScrollContainer/RoomList

onready var _direct_hostname = $MarginContainer/Panel/VBoxContainer/Footer/Control/Host
onready var _direct_port = $MarginContainer/Panel/VBoxContainer/Footer/Control/Port


func refresh():
	
	for index in range(_room_list.get_child_count()):
		_room_list.get_child(index).queue_free()
	
	var stg = "Discover"
	var pac = stg.to_ascii()
	_udp.put_packet(pac)
	
	$HolePunching.request_gamelist()
	

func _set_player_info():
	
	
	var username = $MarginContainer/Panel/VBoxContainer/Header/Username.text
	#var color = $MarginContainer/VBoxContainer/HBoxContainer3/ColorPickerButton.color
	
	mp_state.player_info = { "username": username }
	


func _add_server(name, host, port):
	
	var room_item = instanced_room_item.instance()
	room_item.room_name = name
	room_item.host = host
	room_item.port = port
	room_item.connect("join", self, "_on_join_room")
	_room_list.add_child(room_item)
	

func _ready():
	
	mp_state.connect("connect_succeeded", self, "_connect_succeeded")
	mp_state.connect("connect_failed", self, "_connect_failed")
	
	_udp = PacketPeerUDP.new()
	
	_udp.listen(3334)
	_udp.set_dest_address("192.168.1.255", 3335)
	
	refresh()
	

func _exit_tree():
    _udp.close()

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	
	if _udp.get_available_packet_count() > 0:
		var array_bytes = _udp.get_packet()
		var IP_CLIENT = _udp.get_packet_ip()
		var PORT_CLIENT = _udp.get_packet_port()
		
		var info = parse_json( array_bytes.get_string_from_ascii() )
		
		
		print("msg server: ", info, " from ", IP_CLIENT, ":", PORT_CLIENT)
		
		_add_server(info.name, IP_CLIENT, info.port)
		
	


func _connect_succeeded(id, player_info):
	
	print("_connect_succeeded", id, player_info)
	
	get_tree().change_scene("res://ui/Multiplayer/LobbyMenu.tscn")
	
	pass


func _connect_failed():
	
	print("Cannot connect to server")
	
	pass


func _on_join_room(host, port):
	
	print("Join room on ", host, ":", port)
	
	_set_player_info()
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(host, port)
	get_tree().set_network_peer(peer)
	get_tree().set_meta("network_peer", peer)
	

func _on_JoinButton_pressed():
	
	_on_join_room(_direct_hostname.text, int(_direct_port.text) )
	


func _on_HostButton_pressed():
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	get_tree().set_meta("network_peer", peer)
	
	mp_state.enable = true
	mp_state.master_server = true
	mp_state.port = SERVER_PORT
	
	_set_player_info()
	
	get_tree().change_scene("res://ui/Multiplayer/LobbyMenu.tscn")
	


func _on_ReturnMainButton_pressed():
	
	get_tree().set_network_peer(null)
	
	get_tree().change_scene("res://ui/Main/Main.tscn")
	


func _on_Refresh_pressed():
	
	refresh()
	


func _on_HolePunching_gamelist_received(gamelist):
	
	for index in range(gamelist.size()):
		
		var game_server = gamelist[index]
		
		var name = "Game Room"
		if game_server.has("name"):
			name = game_server.name
		
		_add_server(name, game_server.host, game_server.port)
		
	
