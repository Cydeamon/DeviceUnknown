extends Node3D

func _ready():
	$Hook/CollisionShape3D.disabled = true

func _process(delta):
	$Camera.flip_offset = $Player/RobotTop.rotation.y < 0
