extends CanvasLayer

var instanced_score_item = preload("res://ui/Score/ScoreItem.tscn")

var _default_mouse_cursor = load("res://mouse_cursor.png")

const SCORE_SERVER_URL = "http://app-4c73f63a-b483-44f3-aab7-4fd6dde767a9.cleverapps.io/games-score/games/TankMania2/levels"
#const SCORE_SERVER_URL = "http://127.0.0.1:8080/games-score/games/TankMania2/levels"
const USE_SSL = false

const user_dir = "user://"

const score_path = user_dir + "Score.json"

signal next
signal retry


export (bool) var visible = false setget set_visible

enum {LOAD_ERROR_COULDNT_OPEN, LOAD_SUCCESS}

onready var _root_container = $MarginContainer
onready var _current_score = $MarginContainer/Panel/MarginContainer/VBoxContainer/PlayerScore/CurrentScore
onready var _best_score = $MarginContainer/Panel/MarginContainer/VBoxContainer/PlayerScore/BestScore

onready var _score_list = $MarginContainer/Panel/MarginContainer/VBoxContainer/MarginContainer/BestScores/ScoreList

onready var _username_input = $MarginContainer/Panel/Container/Username


var _level = 0
var _score_file = ConfigFile.new()


func set_visible(value):
	visible = value
	if _root_container:
		_root_container.visible = visible
	if visible:
		Input.set_custom_mouse_cursor(_default_mouse_cursor)


func refresh(level):
	
	refresh_online(level)
	
	var error = _score_file.load(score_path)
	if error != OK:
		print("Error loading the settings. Error code: %s" % error)
		return LOAD_ERROR_COULDNT_OPEN
	
	var username = _score_file.get_value("config", "username")
	
	if username != null:
		_username_input.text = username
		_username_input.editable = false
	
	
	if _score_file.has_section_key(str(level), "score") and _score_file.has_section_key(str(level), "time"):
		_best_score.score = _score_file.get_value( str(level), "score")
		_best_score.time = _score_file.get_value( str(level), "time")
	
	
	return LOAD_SUCCESS

func refresh_online(level):
	
	# Clear all score
	for index in range( _score_list.get_child_count() ):
		_score_list.get_child(index).queue_free()
	
	# Request to reload score
	$HTTPRequestScoreList.request(SCORE_SERVER_URL + "/" + str(level) + "/best", [], USE_SSL)
	


func set_score(score):
	
	_level = score.level
	
	refresh(score.level)
	
	$MarginContainer/Panel/Title.text = "Score : Level %d" % score.level
	
	_current_score.score = score.score
	_current_score.time = score.time
	
	if _best_score.score == null or (score.score >= _best_score.score and score.time < _best_score.time):
		
		_best_score.score = score.score
		_best_score.time = score.time
		
		_score_file.set_value( str(score.level), "score", score.score)
		_score_file.set_value( str(score.level), "time", score.time)
		
		_score_file.save(score_path)
		
	else:
		_best_score.score = 0
		_best_score.time = 0
	

func _ready():
	
	_root_container.visible = visible
	
	# DEBUG
	#set_score({"level": 0, "score": 20, "time": 67000})
	#_username_input.text = "Test_00006"
	

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	
	if _username_input.text.length() > 4 and _username_input.text != "Username":
		$MarginContainer/Panel/Container/ShareButton.disabled = false
	else:
		$MarginContainer/Panel/Container/ShareButton.disabled = true
	
	pass

func _on_ShareButton_pressed():
	
	if _username_input.text == "Username":
		return
	
	if _username_input.editable:
		_score_file.set_value( "config", "username", _username_input.text)
		_username_input.editable = false
		_score_file.save(score_path)
	
	
	#var query = JSON.print(data_to_send)
	var query = to_json({"score": _current_score.score, "time": _current_score.time})
	
	var username = _username_input.text.percent_encode ()
	
	# Add 'Content-Type' header:
	var headers = ["Content-Type: application/json"]
	var path = "/" + str(_level) + "/users/" + username
	var result = $HTTPRequestPushScore.request(SCORE_SERVER_URL + path, headers, USE_SSL, HTTPClient.METHOD_PUT, query)
	
	#print("URL: ", SCORE_SERVER_URL + "/" + str(_level) + "/users/" + _username_input.text)
	
	print("path: ", path, ", query: ", query)
	print("push score result: ", result)
	
	# TODO : Push Score
	
	pass # replace with function body



func _on_NextButton_pressed():
	
	emit_signal("next")
	

func _on_RetryButton_pressed():
	
	emit_signal("retry")
	


func _on_HTTPRequestScoreList_request_completed(result, response_code, headers, body):
	
	# TODO : fill score list with results
	
	if response_code != 200:
		return
	
	print("--- Request Best Score result ---")
	
	print("response_code: ", response_code )
	print("result: ", result )
	#print("headers: ", headers )
	#print("body: ", body )
	#print("body str: ", body.get_string_from_utf8() )
	
	var json_str = body.get_string_from_utf8()
	var score_list = parse_json( json_str )
	
	#print("score_list: ", score_list)
	
	for index in range( score_list.size()):
		var score = score_list[index]
		#print("score: ", score)
		
		var score_item = instanced_score_item.instance()
		score_item.title = score.username
		score_item.score = score.score
		score_item.time = score.time
		_score_list.add_child(score_item)
		
	



func _on_HTTPRequestPushScore_request_completed(result, response_code, headers, body):
	
	print("--- Push Score result ---")
	
	print("response_code: ", response_code )
	print("result: ", result )
	#print("headers: ", headers )
	
	refresh_online(_level)
	
	pass # replace with function body
