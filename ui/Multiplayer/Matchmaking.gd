extends MarginContainer

#const MATCHMAKING_SERVER_URL = "http://localhost:8080/games-matchmaking/games/TankMania2/matchmaking"
const MATCHMAKING_SERVER_URL = "http://app-4c73f63a-b483-44f3-aab7-4fd6dde767a9.cleverapps.io/games-matchmaking/games/TankMania2/matchmaking"

const USE_SSL = false

const port_min = 3330
const port_max = 3350

var _upnp

var _host
var _port = -1
var _local_port = -1
var _started_as_host = false

var _username

var _request_token = null

func check_local_port(port):
	
	# TODO : check if the port is available
	
	return true

func find_local_port():
	for port in range(port_min, port_max):
		if check_local_port(port):
			return port
	return -1

func find_upnp_port(port_internal):
	for port in range(port_min, port_max):
		var result = _upnp.add_port_mapping(port, port_internal, "TankMania2", "UDP", 300)
		if result == UPNP.UPNP_RESULT_SUCCESS:
			return port
	return -1


func start_as_master():
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(_local_port, 4)
	get_tree().set_network_peer(peer)
	get_tree().set_meta("network_peer", peer)
	
	mp_state.enable = true
	mp_state.master_server = true
	mp_state.port = _port
	mp_state.player_info = { "username": _username }
	
	get_tree().change_scene("res://ui/Multiplayer/LobbyMenu.tscn")
	

func start_as_slave(host, port):
	
	mp_state.enable = true
	mp_state.master_server = false
	mp_state.player_info = { "username": _username }
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(host, port)
	get_tree().set_network_peer(peer)
	get_tree().set_meta("network_peer", peer)
	
	_clear_upnp()
	
	print("Connection to master...")
	

func _connect_succeeded(id, player_info):
	
	print("_connect_succeeded", id, player_info)
	
	get_tree().change_scene("res://ui/Multiplayer/LobbyMenu.tscn")
	


func _connect_failed():
	
	print("Cannot connect to server")
	
	$Panel/VBoxContainer/StatusContainer/Info.text = "Error : Cannot connect to the session"
	


func _clear_upnp():
	if _upnp and _port != -1:
		_upnp.delete_port_mapping(_port)
	

# Called when the node enters the scene tree for the first time.
func _ready():
	
	_upnp = UPNP.new()
	_upnp.discover()
	
	_host = _upnp.query_external_address()
	
	_local_port = find_local_port()
	
	if _local_port == -1:
		print("Cannot find valid local UDP port")
		return
	
	_port = find_upnp_port(_local_port)
	
	if _port == -1:
		print("Cannot open port using UPNP")
		return
	
	mp_state.connect("connect_succeeded", self, "_connect_succeeded")
	mp_state.connect("connect_failed", self, "_connect_failed")
	

func _exit_tree():
	
	pass

func _process(delta):
	
	var username = $Panel/VBoxContainer/UsernameControl/Control/Username.text
	
	if username.length() > 4:
		$Panel/VBoxContainer/UsernameControl/Control/StartMatchmaking.disabled = false
	else:
		$Panel/VBoxContainer/UsernameControl/Control/StartMatchmaking.disabled = true
	

func _on_ReturnMain_pressed():
	
	_clear_upnp()
	
	get_tree().change_scene("res://ui/Main/Main.tscn")
	


func _on_StartMatchmaking_pressed():
	
	_username = $Panel/VBoxContainer/UsernameControl/Control/Username.text
	
	if _username.length() <= 4:
		return
	
	var headers = ["Content-Type: application/json"]
	var query = to_json({"name": _username, "host": _host, "port": _port})
	$HTTPRequestMatchmakingJoin.request(MATCHMAKING_SERVER_URL + "/join", headers, USE_SSL, HTTPClient.METHOD_POST, query)
	
	$MatchmakingRequestTimer.start()
	
	$Panel/VBoxContainer/UsernameControl.visible = false
	$Panel/VBoxContainer/StatusContainer.visible = true
	
	$Panel/VBoxContainer/StatusContainer/Info.text = "Connection to matchmaking server"
	

func _on_CancelButton_pressed():
	
	if _request_token:
		
		$HTTPRequestMatchmakingCancel.request(MATCHMAKING_SERVER_URL + "/" + _request_token, [], USE_SSL, HTTPClient.METHOD_DELETE)
		
	
	$Panel/VBoxContainer/UsernameControl.visible = true
	$Panel/VBoxContainer/StatusContainer.visible = false
	


func _on_MatchmakingRequestTimer_timeout():
	
	if not _request_token:
		return
	
	$HTTPRequestMatchmakingStatus.request(MATCHMAKING_SERVER_URL + "/" + _request_token, [], USE_SSL, HTTPClient.METHOD_GET)
	
	$MatchmakingRequestTimer.start()
	

func _on_HTTPRequestMatchmakingJoin_request_completed(result, response_code, headers, body):
	
	var json_str = body.get_string_from_utf8()
	
	print("Response :", result, response_code, headers, json_str)
	
	if response_code >= 404:
		
		$Panel/VBoxContainer/StatusContainer/Info.text = "ERROR"
		
		return
	
	if response_code == 200:
		
		var response = parse_json( json_str )
		
		_request_token = response.request_token
		
		$Panel/VBoxContainer/StatusContainer/Info.text = "Waiting players..."
		
	


func _on_HTTPRequestMatchmakingStatus_request_completed(result, response_code, headers, body):
	
	var json_str = body.get_string_from_utf8()
	
	print("Response :", result, response_code, headers, json_str)
	
	if response_code >= 404:
		print("Internal Error")
		return
	
	if response_code == 200:
		
		var response = parse_json( json_str )
		
		if response.status == "READY":
			
			print("Game Session found")
			
			$Panel/VBoxContainer/StatusContainer/Info.text = "Game session starting..."
			
			$MatchmakingRequestTimer.stop()
			
			#if response.host == _host and response.port == _port:
			if response.master == _username:
				start_as_master()
			else:
				start_as_slave(response.host, response.port)
			
		
		if response.status == "IN_ROOM":
			
			$Panel/VBoxContainer/StatusContainer/Info.text = "Session found. Wait other players..."
			
		
		if response.status == "IN_QUEUE":
			
			$Panel/VBoxContainer/StatusContainer/Info.text = "Searching players..."
			
		
	


func _on_HTTPRequestMatchmakingCancel_request_completed(result, response_code, headers, body):
	
	var json_str = body.get_string_from_utf8()
	
	print("Response :", result, response_code, headers, json_str)
	
	if response_code >= 404:
		print("Internal Error")
		return
	
	if response_code == 200:
		
		print("Game Session found")
		
		pass
	
	pass # Replace with function body.



