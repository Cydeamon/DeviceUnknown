extends Node3D

var is_environment_light_on = true

func _ready():
	$Player/Hook/CollisionShape3D.disabled = true

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


func _on_environment_light_switch_off_body_entered(body):
	if body.editor_description == "Player" && is_environment_light_on:
		$AnimationPlayer.play("EnvironmentLightOff")
		is_environment_light_on = false
	
func _on_environment_light_switch_on_body_entered(body):
	if body.editor_description == "Player" && !is_environment_light_on:
		$AnimationPlayer.play("EnvironmentLightOn")
		is_environment_light_on = true
