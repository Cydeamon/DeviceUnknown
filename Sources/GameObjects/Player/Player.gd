extends CharacterBody3D

##########################################################################
##########################################################################
##########################################################################

@export var speed = 5.0
@export var jump_velocity = 4.5

@export var hook_object : Node3D

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

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var double_jump_used = false
var target_rotation_y = 0

var is_dash_cooling_down = false
var is_dashing = false

##########################################################################
##########################################################################
##########################################################################

func _ready():
	$RobotTop/AnimationPlayer.play("Idle")

func _process(delta):
	if hook_object:
		hook_object.global_transform = $RobotTop/Armature/MiddleBody/HookPoint.global_transform
		

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
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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
