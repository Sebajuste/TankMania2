#extends GridMap
extends "res://scripts/SceneGridMap.gd"

const MAX_DEEP = 100

enum Dir {
	UP=0x01, RIGHT=0x02, DOWN=0x04, LEFT=0x08
}

export (int) var size = 10
export (int) var gen_seed = 1

export (Vector3) var start_position = Vector3(1, 0, 1)

export var startup : bool = false

var root_cell

var cells = Array()

var _max_deep = 0
var _last_cell

var _dead_end_cells = Array()

func get_max_deep():
	return _max_deep

func generate():
	
	# Clear map
	clear()
	for i in range(0, size+1):
		for j in range(0, size+1):
			set_cell_item(i, 0, j, 0, randi() % 4)
	
	_max_deep = 0
	_last_cell = null
	_dead_end_cells = Array()
	
	cells = Array()
	
	# Init random config
	seed( gen_seed )
	
	# Generate Map
	var root_cell = _gen(null, start_position.x, start_position.z, 0)
	
	self.root_cell = root_cell
	
	_dead_end_cells.erase( _last_cell )
	
	generate_tiles()
	


class Cell:
	
	var parent : Cell
	var position : Vector3
	var deep : int
	var childs = Array()
	
	func _init(parent : Cell, pos : Vector3, deep : int):
		self.parent = parent
		self.position = pos
		self.deep = deep
	


class CellGen:
	
	var up
	var right
	var down
	var left
	var count
	
	func _init():
		count = 0
	
	func get_random_dir():
		
		if count == 0:
			return
		
		var next_dir = randi() % count + 1
		
		var count = 0
		
		if up:
			count += 1
		
		if count == next_dir:
			return Dir.UP
		
		if right:
			count += 1
		
		if count == next_dir:
			return Dir.RIGHT
		
		if down:
			count += 1
		
		if count == next_dir:
			return Dir.DOWN
		
		if left:
			count += 1
		
		if count == next_dir:
			return Dir.LEFT
		
	



func _check_dir(i, j):
	
	var d = CellGen.new() 
	
	if j-2 > 0 and get_cell_item(i, 0, j-2) == 0:
		d.up = true
		d.count += 1
	
	if i+2 < size and get_cell_item(i+2, 0, j) == 0:
		d.right = true
		d.count += 1
	
	if j+2 < size and get_cell_item(i, 0, j+2) == 0:
		d.down = true
		d.count += 1
	
	if i-2 > 0 and get_cell_item(i-2, 0, j) == 0:
		d.left = true
		d.count += 1
	
	return d

func _get_global_position(cell_pos):
	
	return global_transform.translated( cell_pos ).origin * cell_size + global_transform.translated( cell_size / 2 ).origin
	

func _gen(parent, i, j, deep):
	
	if deep == MAX_DEEP:
		return
	
	var cell = Cell.new(parent, Vector3(i, 0, j), deep)
	
	cells.append(cell)
	
	set_cell_item(i, 0, j, -1)
	
	var cellGen = _check_dir(i, j)
	
	var test = 0
	
	while cellGen.count > 0:
		
		if test > 4:
			print("Error")
			break
		
		test += 1
		
		var dir = cellGen.get_random_dir()
		
		var child
		
		match dir:
			Dir.UP:
				set_cell_item(i, 0, j-1, -1)
				child = _gen(cell, i, j-2, deep+1)
			Dir.RIGHT:
				set_cell_item(i+1, 0, j, -1)
				child = _gen(cell, i+2, j, deep+1)
			Dir.DOWN:
				set_cell_item(i, 0, j+1, -1)
				child = _gen(cell, i, j+2, deep+1)
			Dir.LEFT:
				set_cell_item(i-1, 0, j, -1)
				child = _gen(cell, i-2, j, deep+1)
		
		cell.childs.append(child)
		
		cellGen = _check_dir(i, j)
	
	if deep > _max_deep:
		_max_deep = deep
		_last_cell = cell
	
	if cell.childs.size() == 0:
		_dead_end_cells.append( cell )
	
	return cell

func _ready():
	
	if startup:
		generate()
	
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

