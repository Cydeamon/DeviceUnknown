extends Area3D

@export var lerp_speed = 3.0
@export var offset = Vector3(4, 0.5, 8)

func _on_body_entered(body):
	if body.editor_description == "Player":
		get_viewport().get_camera_3d().lerp_speed = lerp_speed
		get_viewport().get_camera_3d().offset = offset
