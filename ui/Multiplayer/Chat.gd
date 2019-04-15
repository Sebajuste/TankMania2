extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"


onready var _room_tab = $VBoxContainer/TabContainer

onready var _line = $VBoxContainer/HBoxContainer/LineEdit

func send(room_name, username, text):
	
	var chat_room = _get_room(room_name)
	
	var line = Label.new()
	line.text = text
	chat_room.add_child(line)
	

func _get_room(room_name):
	
	return _room_tab.get_node(room_name).get_node("ChatRoom")
	

func _get_selected_room():
	
	var chat_room = _room_tab.get_child(0).get_node("ChatRoom")
	
	return chat_room



func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_LineEdit_text_entered(new_text):
	
	var room_name = "Room1"
	var username = mp_state.player_info.username
	
	if mp_state.enable:
		rpc("send", room_name, username, new_text)
	
	send(room_name, username, new_text)
	_line.text = ""
	



func _on_Button_pressed():
	
	var room_name = "Room1"
	var username = mp_state.player_info.username
	
	if mp_state.enable:
		rpc("send", room_name, username, _line.text)
	
	send(room_name, username, _line.text)
	_line.text = ""
	
