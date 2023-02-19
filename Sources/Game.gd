extends Node3D

func _ready():
	$Hook/CollisionShape3D.disabled = true

func _process(delta):
	$Camera.flip_offset = $Player/RobotTop.rotation.y < 0
	draw_dash_ui()
	
func draw_dash_ui():
	if $Player.is_dashing:
		$UI/UI/HBoxContainer/DashLabel.text = "Dashing"	
	else:
		if $Player.is_dash_cooling_down:
			$UI/UI/HBoxContainer/DashLabel.text = "Dash cooling down: "	+ str(round($Player/Timers/DashCooldown.time_left))
		else:
			$UI/UI/HBoxContainer/DashLabel.text = "Dash is ready"
