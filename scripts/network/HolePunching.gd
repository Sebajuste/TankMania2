extends Node

const PING_TIME = 5000

export var master_host = "127.0.0.1"
export (int) var master_port = 34000

export (bool) var server = false
export (int) var server_port = 33000
export (bool) var auto_start = false


signal gamelist_received

signal client_connected



var _packet_id_counter = 0

var _udp_discover

var clients = Array() setget set_clients

var _last_packet_id_received = -1

var _ping_timer = PING_TIME

func request_gamelist():
	
	print("request_gamelist")
	
	var data = {"action": "request", "game": "Test"}
	
	var packet = _encode(data)
	
	_udp_discover.set_dest_address(master_host, master_port)
	var r = _udp_discover.put_packet(packet)
	
	print(r)


func join_game(host, port):
	
	var data_join = {"action": "join", "server": {"host": host, "port": port} }
	var packet_join = _encode(data_join)
	_udp_discover.set_dest_address(master_host, master_port)
	_udp_discover.put_packet(packet_join)


#
# Start Host
#

func create_server():
	
	_udp_discover.close()
	_udp_discover.listen(server_port)


func resgister_server():
	
	var data = {"action": "register", "game": "TankMania2", "server": {} }
	var packet = _encode(data)
	
	_udp_discover.set_dest_address(master_host, master_port)
	_udp_discover.put_packet(packet)

func unregister_server():
	
	var data = {"action": "unregister", "game": "TankMania2", "server": {} }
	var packet = _encode(data)
	
	_udp_discover.set_dest_address(master_host, master_port)
	_udp_discover.put_packet(packet)
	

func start_game():
	
	var data = {"action": "start"}
	var packet = _encode(data)
	
	for c in clients:
		_udp_discover.set_dest_address(c.host, c.port)
		_udp_discover.put_packet(packet)
		
	_udp_discover.close()
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(server_port)
	get_tree().set_network_peer(peer)

func _send_ping():
	
	for c in clients:
		var data = {"action": "ping"}
		var ping_packet = _encode(data)
		_udp_discover.set_dest_address(c.host, c.port)
		_udp_discover.put_packet(ping_packet)
	
	pass


func _ready():
	
	_udp_discover = PacketPeerUDP.new()
	
	if auto_start:
		create_server()

func _exit_tree():
	
	if server:
		unregister_server()
	
	_udp_discover.close()
	

func _process(delta):
	
	_ping_timer -= delta
	if _ping_timer < 0:
		_send_ping()
		_ping_timer = PING_TIME
	
	if _udp_discover.get_available_packet_count() > 0:
		
		var packet = _udp_discover.get_packet()
		
		var message = _decode(packet)
		
		print("message: ", message)
		
		if message.status != null and message.status == "ERROR":
			print("Oops...")
			return
			
		#
		# Server events
		#
		
		# From master
		if message.action == "join_client":
			
			var client = message.client
			
			var data = {"action": "hole_punching"}
			var join_packet = _encode(data)
			
			_udp_discover.set_dest_address(client.host, client.port)
			_udp_discover.put_packet(join_packet)
			
			
		# From client
		if message.action == "connect":
			
			# TODO : register client
			
			var client = {}
			
			client["host"] = _udp_discover.get_packet_ip()
			client["port"] = _udp_discover.get_packet_port()
			
			clients.append(client)
			
			emit_signal("client_connected", client)
			
		
		
		#
		# Client events
		#
		
		# From master
		if message.action == "join_server":
			
			# Connect to server
			var server = message.server
			
			var data = {"action": "connect"}
			var connect_packet = _encode(data)
			
			_udp_discover.set_dest_address(server.host, server.port)
			_udp_discover.put_packet(connect_packet)
		
		
		# From master
		if message.action == "request_response":
			
			emit_signal("gamelist_received", message.game_list)
			
		
		
		#From server
		if message.action == "hole_punching":
		
			# Do nothing
			print("hole_punching")
		
		
		# From server
		if message.action == "start":
			
			_udp_discover.close()
			
			var server_host = _udp_discover.get_packet_ip()
			var server_port = _udp_discover.get_packet_port()
			
			var peer = NetworkedMultiplayerENet.new()
			peer.create_client(server_host, server_port)
			get_tree().set_network_peer(peer)
			
		var response = {}
		var response_packet = _encode_with_packetid(get_packet_id(), response)
		
		_udp_discover.set_dest_address(_udp_discover.get_packet_ip(), _udp_discover.get_packet_port())
		_udp_discover.put_packet(response_packet)



func get_packet_id():
	return  _last_packet_id_received

func set_clients(value):
	pass

func _encode_with_packetid(packet_id, object):
	
	var packet = PoolByteArray()
	
	var json_str = to_json(object)
	
	var length = json_str.length()
	
	var crc = 0
	
	packet.append(packet_id & 0xff)
	
	#packet.append(length)
	packet.append(  length & 0x000000ff  )
	packet.append( (length & 0x0000ff00) >> 8)
	packet.append( (length & 0x00ff0000) >> 16)
	packet.append( (length & 0xff000000) >> 14)
	
	packet.append_array(json_str.to_utf8())
	
	packet.append(  crc & 0x000000ff  )
	packet.append( (crc & 0x0000ff00) >> 8)
	packet.append( (crc & 0x00ff0000) >> 16)
	packet.append( (crc & 0xff000000) >> 14)
	
	return packet


func _encode(object):
	
	var packet_id = _packet_id_counter
	_packet_id_counter += 1
	
	return _encode_with_packetid(packet_id, object)


func _decode(packet):
	
	var packet_id = packet[0]
	_last_packet_id_received = packet_id
	
	var length = packet[1] | (packet[2] << 8) | (packet[3] << 16) | (packet[4] << 24)
	
	var json_str = packet.subarray(5, length+5).get_string_from_utf8()
	
	print("json_str: ", json_str)
	
	# TODO : check CRC
	
	return parse_json( json_str )
