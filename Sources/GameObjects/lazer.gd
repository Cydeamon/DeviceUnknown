extends Node3D

@export var max_length = 6.0
var length
var prev_length

func _ready():
	$RayCast3D.target_position.y = max_length
	

func _process(delta):
	if $RayCast3D.is_colliding():		
		var origin = $RayCast3D.global_transform.origin
		var collision_point = $RayCast3D.get_collision_point()
		length = origin.distance_to(collision_point)
	else:
		length = max_length
	
	if prev_length != length:
		apply_length()
		
func apply_length():
	prev_length = length
	$Lazer.position.y = length / 2
	$Lazer.mesh.size.y = length
