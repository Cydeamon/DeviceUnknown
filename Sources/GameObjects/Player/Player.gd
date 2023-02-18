extends CharacterBody3D

@export var speed = 5.0
@export var jump_velocity = 4.5

@export var hook_object : Node3D

@export_category("Abilities")
@export var ability_active_double_jump = false
@export var ability_active_dash = false
@export var ability_active_rockets = false
@export var ability_active_lazer = false
@export var ability_active_flame = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var double_jump_used = false
var target_rotation_y = 0

func _ready():
	$RobotTop/AnimationPlayer.play("Idle")

func _process(delta):
	if hook_object:
		hook_object.global_transform = $RobotTop/Armature/MiddleBody/HookPoint.global_transform
		
	if velocity.x != 0:
		if velocity.x < 0:
			target_rotation_y = -PI / 2
		else:			
			target_rotation_y = PI / 2
			
	if target_rotation_y:
		$RobotTop.rotation.y = move_toward($RobotTop.rotation.y, target_rotation_y, delta * 10)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		double_jump_used = false

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		var can_jump = is_on_floor()
		
		if !double_jump_used && ability_active_double_jump && !is_on_floor():
			can_jump = true
			double_jump_used = true
		
		if can_jump:
			velocity.y = jump_velocity
			$AnimationPlayer.play("JumpLight")
		
		

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

	move_and_slide()
	$RobotBottom/AnimationPlayer.speed_scale = velocity.x / speed
