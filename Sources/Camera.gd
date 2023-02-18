extends Camera3D

@export var lerp_speed = 3.0
@export var target_path : NodePath
@export var offset = Vector3.ZERO

var target = null
var flip_offset = false

func _ready():
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if target:
		offset.x = -abs(offset.x) if flip_offset else abs(offset.x)
		global_transform = global_transform.interpolate_with(
			target.global_transform.translated_local(offset), 
			lerp_speed * delta
		)
