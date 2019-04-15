extends HBoxContainer

export var title = "" setget set_title

var time setget set_time
var score setget set_score

func set_title(value):
	title = value
	if has_node("Title"):
		get_node("Title").text = value

func set_time(value):
	time = value
	$Time.time = time

func set_score(value):
	score = value
	$Score/Value.text = str(value)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
