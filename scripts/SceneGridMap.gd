extends Spatial

var instanced_shell = preload("res://tileset/tiles/CityTile.tscn")

#export var list = []

export (Vector3) var cell_size = Vector3(30, 1, 30)


var _item_map = {}
var _tiles_map = {}

func clear():
	for pos in _tiles_map:
		_tiles_map[pos].queue_free()
	_tiles_map.clear()
	_item_map.clear()
	pass

func get_cell_item(x, y, z):
	
	var pos = Vector3(x, y, z)
	if _item_map.has(pos):
		return _item_map[pos].item
	return -1
	


func set_cell_item(x, y, z, item, orientation=0):
	
	var pos = Vector3(x, y, z)
	if get_cell_item(x, y, z) != -1:
		#_tiles_map[pos].tile.queue_free()
		_item_map.erase(pos)
		pass
	
	if item == -1:
		return
	
	
	_item_map[pos] = {"item": item, "orientation": orientation}
	


func generate_tiles():
	
	for pos in _item_map:
		var tile = instanced_shell.instance()
		tile.transform = tile.transform.translated(pos * cell_size + cell_size / 2)
		
		var inner_spatial = tile.get_node("Spatial")
		inner_spatial.transform = inner_spatial.transform.rotated(Vector3(0, 1, 0), deg2rad(90 * _item_map[pos].orientation ) )
		add_child(tile)
		_tiles_map[pos] = tile
	


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
