extends CharacterBody3D

##########################################################################
##########################################################################
##########################################################################

@export var speed = 5.0
@export var jump_velocity = 4.5
@export var hook_object : Node3D
@export var aim_target_point : Vector3
@export var active_weapon = Weapon.NO_WEAPON

@export_category("Abilities")
@export var ability_active_double_jump = false
@export var ability_active_dash = false
@export var ability_active_rockets = false
@export var ability_active_lazer = false
@export var ability_active_flame = false

@export_subgroup("Dash")
@export var dash_speed = 10

##########################################################################
##########################################################################
##########################################################################

enum Weapon { NO_WEAPON, LAZER, ROCKETS, FIRE }
enum Arm {LEFT, RIGHT}

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var double_jump_used = false
var target_rotation_y = 0

var skeleton : Skeleton3D
var left_arm_shoulder = null
var right_arm_shoulder = null

var current_arm : Arm
var is_dash_cooling_down = false
var is_dashing = false
var is_firing = false
var is_aiming = false

##########################################################################
##########################################################################
##########################################################################

func _ready():
	$RobotTop/AnimationPlayer.play("Idle")
	skeleton = $RobotTop/Armature/Skeleton3D
	left_arm_shoulder = skeleton.find_bone("UpperArmLeft")
	right_arm_shoulder = skeleton.find_bone("UpperArmRight")
	
	$RobotTop/AnimationPlayer.connect("animation_finished", _on_robot_top_animation_finished)
	

func _process(delta):
	if hook_object:
		hook_object.global_transform = $RobotTop/Armature/MiddleBody/HookPoint.global_transform
		
	check_fire()
		
	if is_firing:
		if current_arm == Arm.LEFT:
			if !$RobotTop/AnimationPlayer.current_animation == "FireLeftStart" && !is_aiming:
				$RobotTop/AnimationPlayer.play("FireLeftArm")
		else:
			if !$RobotTop/AnimationPlayer.current_animation == "FireRightStart" && !is_aiming:
				$RobotTop/AnimationPlayer.play("FireRightArm")
				
		aim_arm_at_mouse_position()
		
		if is_aiming:
			fire()
	else:		
		$Lazer.hide()
		
func aim_arm_at_mouse_position():
	var shoulder_global_pos : Vector3
	var shoulder = left_arm_shoulder if current_arm == Arm.LEFT else right_arm_shoulder

	shoulder_global_pos = global_position + skeleton.get_bone_global_pose(shoulder).origin
	var direction = Vector3(shoulder_global_pos - get_world_mouse_position()).normalized()
	var angle = Vector3.RIGHT.angle_to(direction)
	angle = -sign(direction.y) * angle
	var quat
	
	if target_rotation_y < 0:
		quat = Quaternion(Vector3.RIGHT, deg_to_rad(90)) * Quaternion(Vector3.FORWARD, angle)
		
		if current_arm == Arm.LEFT:
			quat *= Quaternion(0, 1, 0, 0)
	else:
		quat = Quaternion(Vector3.LEFT, deg_to_rad(90)) * Quaternion(Vector3.FORWARD, angle)
		
		if current_arm == Arm.RIGHT:
			quat *= Quaternion(0, 1, 0, 0)
	
	skeleton.set_bone_pose_rotation(shoulder, quat.normalized())
	
	
func get_world_mouse_position():
	var result = Vector3.ZERO
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_start_pos = camera.project_ray_origin(mouse_pos)
	var ray_end_pos = camera.project_ray_normal(mouse_pos) * 2000
	
	var ray_params = PhysicsRayQueryParameters3D.create(ray_start_pos, ray_end_pos)
	ray_params.collide_with_areas = true
	ray_params.collide_with_bodies = false
	ray_params.collision_mask = 0b1000000000000000 # Check collisions on 16 layer
	
	var ray_cast_result = get_world_3d().direct_space_state.intersect_ray(ray_params)
	
	if (ray_cast_result.has("position")):
		result = ray_cast_result["position"]
	
	return result
	
	
func check_fire():
	if active_weapon != Weapon.NO_WEAPON:
		if active_weapon == Weapon.LAZER || active_weapon == Weapon.FIRE:
			current_arm = Arm.LEFT
		else:
			current_arm = Arm.RIGHT
			
		if Input.is_action_pressed("fire"):
			is_firing = true
		else:
			is_aiming = false
			
			if is_firing:
				$RobotTop/AnimationPlayer.stop()
				
				if current_arm == Arm.LEFT:
					$RobotTop/AnimationPlayer.play("FireLeftArmEnd")
				else:
					$RobotTop/AnimationPlayer.play("FireRightArmEnd")
				
				$RobotTop/AnimationPlayer.play("Idle")
				is_firing = false


func fire():
	if active_weapon == Weapon.LAZER:
		fire_lazer()
		

func fire_lazer():
	$Lazer.global_rotation = $RobotTop/Armature/Skeleton3D/LazerSpawnPoint.global_rotation
	$Lazer.global_position = $RobotTop/Armature/Skeleton3D/LazerSpawnPoint.global_position	
	$Lazer.show()	
	
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		double_jump_used = false
		
	# Handle direction rotation	
	if velocity.x != 0:
		if velocity.x < 0:
			target_rotation_y = -PI / 2
		else:			
			target_rotation_y = PI / 2
			
	if target_rotation_y:
		$RobotTop.rotation.y = move_toward($RobotTop.rotation.y, target_rotation_y, delta * 10)

	# Handle Dash.
	if Input.is_action_just_pressed("dash") && !is_dashing && !is_dash_cooling_down:
		is_dashing = true
		$Timers/DashTimer.start()
		$RobotTop/AnimationPlayer.play("DashStart")

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		var can_jump = is_on_floor()
		
		if !double_jump_used && ability_active_double_jump && !is_on_floor():
			can_jump = true
			double_jump_used = true
		
		if can_jump:
			velocity.y = jump_velocity
			$AnimationPlayer.play("JumpLight")
			is_dashing = false
		
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if is_dashing:
		if target_rotation_y > 0:
			velocity = Vector3(dash_speed, 0, 0)
		else:
			velocity = Vector3(-dash_speed, 0, 0)
		
	move_and_slide()
	$RobotBottom/AnimationPlayer.speed_scale = direction.x


func _on_dash_cooldown_timeout():
	is_dash_cooling_down = false


func _on_dash_timer_timeout():
	is_dash_cooling_down = true
	is_dashing = false
	$Timers/DashCooldown.start()
	$RobotTop/AnimationPlayer.stop()
	$RobotTop/AnimationPlayer.play("DashEnd")
	$RobotTop/AnimationPlayer.queue("Idle")


func _on_robot_top_animation_finished(animation_name):
	if animation_name == "FireLeftArm" || animation_name == "FireRightArm":
		is_aiming = true
	
