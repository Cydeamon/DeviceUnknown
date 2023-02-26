extends Node3D

@export var speed = 2.0
var exploding = false

func _process(delta):
	if !exploding: 
		global_position += global_transform.basis.y * speed * delta

func _on_hit_detection_body_entered(body):
	exploding = true
	$Rocket.hide()
	explode()
	
func explode():
	$AnimationPlayer.play("explode")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		hide()
		get_parent().remove_child(self)
		queue_free()
