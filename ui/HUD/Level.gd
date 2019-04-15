extends CanvasLayer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var level setget set_level
var score setget set_score
var time setget set_time

func set_level(newLevel):
	level = newLevel
	
	$MarginContainer/VBoxContainer/LevelContainer/Level.text = str(level)
	

func set_score(value):
	score = value
	$MarginContainer/VBoxContainer/ScoreContainer/Score.text = str(value)

func set_time(value):
	time = value
	
	$MarginContainer/VBoxContainer/Time.time = value
	

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_level_changed(level):
	
	set_level(level)
	
	pass # replace with function body
