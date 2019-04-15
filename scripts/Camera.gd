extends Camera

export( bool ) var topLevel = true


export (NodePath) var followNode
export (Vector3) var followFrom = Vector3()



func _ready():
	
	if topLevel:
		set_as_toplevel(true)
	
	if followNode:
		followNode = get_node(followNode)
	else:
		followNode = null
	

func _process(delta):
	
	if followNode:
		
		global_transform.origin = followNode.global_transform.origin + followFrom
		
		look_at(followNode.global_transform.origin, Vector3(0, 1, 0))
		
	
	pass
