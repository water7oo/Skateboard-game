extends CharacterBody3D


var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
@onready var Stamina_bar = $"UI Cooldowns"

var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 10.0  # Adjust the speed of blending

@onready var root_node = get_tree().get_root()
@onready var armature = $Armature
@onready var jump_wave = get_tree().get_nodes_in_group("Jump_wave")
@onready var dust_trail = get_tree().get_nodes_in_group("dust_trail")
@onready var jump_dust = get_tree().get_nodes_in_group("jump_dust")
@onready var move_dust = get_tree().get_nodes_in_group("move_dust")
@onready var burst_dust = get_tree().get_nodes_in_group("burst_dust")
@onready var wall_wave = get_tree().get_nodes_in_group("wall_wave")
#@onready var InputBuffer = get_node("/root/InputBuffer")

#Basic Movement
@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 0.1
@export var BASE_SPEED = 3
@export var MAX_SPEED = 7
@export var  STAMINA_DEPLETED_SPEED = 1
var SPEED = BASE_SPEED
var target_speed = BASE_SPEED
var current_speed = 0.0

var is_moving = false

@export var JUMP_VELOCITY = 3
@export var SHORT_JUMP = 4
@export var LONG_JUMP = 8
@export var RUNJUMP_MULTIPLIER = 1.3
var jump_timer = 0.0
var jump_tap_timer = 0.1
var jump_height = 128
var jumps = 1

#Acceleration and Speed
var ACCELERATION = 5.0 #the higher the value the faster the acceleration
var DECELERATION = 10.0 #the lower the value the slippier the stop
@export var BASE_ACCELERATION = 5
@export var BASE_DECELERATION = 3 
@export var DASH_ACCELERATION = 20
@export var DASH_DECELERATION = 20
var DASH_MAX_SPEED = BASE_SPEED * 3

@export var stamina = 250
@export var sprinting_deplete_rate = 5
@export var sprinting_refill_rate = 10
@export var sprinting_refill_rate_zero = 5
var is_dodging = false
var can_dodge = true
var can_sprint = true
var dash_timer = 0.0
var dodge_cooldown_timer = 0.0
@export var DODGE_SPEED = 10
@export var dash_duration = 0.04
@export var SECOND_DASH_ACCELERATION = 300
@export var SECOND_DASH_DECELERATION = 25
var INITIAL_DASH_ACCELERATION = ACCELERATION
var INITIAL_DASH_DECELERATION = DECELERATION
var INITIAL_MAX_SPEED = MAX_SPEED
var SECOND_MAX_SPEED = DASH_MAX_SPEED * 1.2
var is_second_sprint = false

@export var DODGE_ACCELERATION = 50
@export var DODGE_DECELERATION = 5


var WALL_JUMP_VELOCITY_MULTIPLIER = 2.5

var air_time = 0.0
var air_timer = 0.0
var sprint_timer = 0.0


var landing_animation_threshold = 1.0
var WALL_STAY_DURATION = 0.5  # Adjust this value to control how long the player stays on the wall after a jump
var wall_stay_timer = 0.0
var ORIGINAL_JUMP_VEL = JUMP_VELOCITY
var RUN_JUMP_VELOCITY = JUMP_VELOCITY * RUNJUMP_MULTIPLIER
var LERP_VAL = 0.2
var DODGE_LERP_VAL = 1
var wall_jump_position = Vector3.ZERO

var custom_gravity = 25.0 #The lower the value the floatier
var sprinting = false
var dodging = false
var dodge_timer = 0.0
@export var dodge_cooldown = 5
var is_in_air = false
var can_jump = true

var is_sprinting = false
#var light_attack1 = false
#var light_attack2 = false
#var medium_attack1 = false
var landing_position = Vector3.ZERO
var can_wall_jump = true
var has_wall_jumped = false

var fall = Vector3()
var wall_normal
var direction = Vector3()

var hitbox = null
var hitbox_active = false
var hitbox_duration = 0.2  # Adjust the duration of the hitbox here
var is_attacking = false
var jumping = Input.is_action_pressed("move_jump")
var drifting = Input.is_action_pressed("move_drift")
var camera_rotation_speed = 20
var armature_rotation_speed = 20


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:

		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-80), deg_to_rad(2))

		spring_arm_pivot.rotation.x = rotation_x
		spring_arm_pivot.rotation.y = rotation_y

	if Input.is_action_pressed("cam_down"):
		spring_arm_pivot.rotation.x -= joystick_sensitivity 
	if Input.is_action_pressed("cam_up"):
		spring_arm_pivot.rotation.x += joystick_sensitivity 
	if Input.is_action_pressed("cam_right"):
		spring_arm_pivot.rotation.y -= joystick_sensitivity 
	if Input.is_action_pressed("cam_left"):
		spring_arm_pivot.rotation.y += joystick_sensitivity 


#func rotate_player_and_camera(direction: int, delta: float) -> void:
	#var rotation_speed = armature_rotation_speed * delta * direction
	#armature.rotate(Vector3.UP, deg_to_rad(rotation_speed))
	#spring_arm_pivot.rotate(Vector3.UP, deg_to_rad(rotation_speed))
	#
func _proccess_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	_proccess_drift(delta)
	
	if direction:
		is_moving = true
		print(current_speed)
		if current_speed < target_speed:
			current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)
		else:
			current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)
	
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if direction && !is_sprinting && is_on_floor():
			target_blend_amount = 0.0
			current_blend_amount = lerp(current_blend_amount, target_blend_amount, blend_lerp_speed * delta)
		else:
			target_blend_amount = -1.0

	elif !direction && is_on_floor():
			velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
			velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)
			current_speed = sqrt(velocity.x * velocity.x + velocity.z * velocity.z)
			



	#var target_rotation = atan2(-velocity.x, -velocity.z)
	#var turn_radius = 90
	#var angle_adjustment = atan2(turn_radius, current_speed)
	#if Input.is_action_pressed("move_left"):
		#rotate_player_and_camera(1, delta)
	#elif Input.is_action_pressed("move_right"):
		#rotate_player_and_camera(-1, delta)
		#
	#elif Input.is_action_just_pressed("move_forward"):
		#print("Player is going forwards")
	#
	#armature.rotation.y = lerp_angle(armature.rotation.y, target_rotation, LERP_VAL)

	armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)

	for node in dust_trail:
			var particle_emitter = node.get_node("Dust")
			if particle_emitter && input_dir != Vector2.ZERO && is_on_floor():
				var should_emit_particles = Input.is_action_pressed("move_drift") && is_on_floor() && current_speed > 3
				particle_emitter.set_emitting(should_emit_particles)
				
			if jumping || velocity.y > 0:
				particle_emitter.set_emitting(false)
				
	for node in jump_dust:
		var particle_emitter = node.get_node("jump_dust")
		if particle_emitter && Input.is_action_just_pressed("move_jump"):
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)

	for node in move_dust:
		var particle_emitter = node.get_node("move_dust")
		if particle_emitter && is_on_floor() && direction && sprinting:
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)
			
			
	for node in burst_dust:
		var particle_emitter = node.get_node("burst_dust")
		if particle_emitter && is_on_floor() && dodging:
			particle_emitter.set_emitting(true)
		else:
			particle_emitter.set_emitting(false)

func _proccess_boosting(delta):
	if sprinting && is_moving && Stamina_bar.value > 0 && can_sprint:
		sprint_timer += delta
		is_sprinting = true
		Stamina_bar.value -= sprinting_deplete_rate * delta
		
		target_speed = MAX_SPEED
		ACCELERATION = DASH_ACCELERATION
		DECELERATION = DASH_DECELERATION
		target_blend_amount = 1.0
	else:
		is_sprinting = false
		target_speed = BASE_SPEED
		ACCELERATION = BASE_ACCELERATION
		DECELERATION = BASE_DECELERATION
		#$AnimationTree.set("parameters/Ground_Blend2/blend_amount", -1)
		
		if Stamina_bar.value < stamina:
			Stamina_bar.value += sprinting_refill_rate * delta
			
		if Stamina_bar.value == stamina:
			can_sprint = true

func _proccess_bursting(delta):
	if dodging && is_on_floor() && can_dodge && Stamina_bar.value > 0:
		is_dodging = true
		current_speed = DODGE_SPEED
		ACCELERATION = DODGE_ACCELERATION
		DECELERATION = DODGE_DECELERATION
		LERP_VAL = DODGE_LERP_VAL
		
		Stamina_bar.value -= 20
		#$AnimationTree.set("parameters/Ground_Blend3/blend_amount", 0)

		dodge_cooldown_timer = dodge_cooldown  # Start the cooldown
		can_dodge = false  # Disable dodging until cooldown finishes
		if Stamina_bar.value <= 0 && is_dodging:
			#$AnimationTree.set("parameters/Ground_Blend3/blend_amount", -1)
			current_speed = BASE_SPEED
	if is_dodging:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			is_dodging = false
			LERP_VAL = 0.2
			#$AnimationTree.set("parameters/Ground_Blend3/blend_amount", -1)

func _proccess_cooldown(delta):
	if !can_dodge:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			can_dodge = true
			dodge_cooldown_timer = 0

	if Input.is_action_just_released("move_dodge"):
		#$AnimationTree.set("parameters/Ground_Blend3/blend_amount", -1)
		ACCELERATION = BASE_ACCELERATION
		DECELERATION = BASE_DECELERATION
		if can_dodge:
			dodge_cooldown_timer = dodge_cooldown
			can_dodge = false

func _proccess_jump(delta):
	if is_on_floor():
		jumps = 1
	if jumping && can_jump && jumps > 0: 
		can_jump = false
		jumps -= 1
		velocity.y = JUMP_VELOCITY
	if !is_on_floor():
		air_timer += delta
		can_jump = false
		jumps = 0
		velocity.y -= custom_gravity * (delta)

	if Input.is_action_pressed("move_jump"):
		jump_timer += delta
		air_timer += delta
		
		
		if jump_timer <= 0.2:
			velocity.y = JUMP_VELOCITY
			can_jump = false
			jumps = 0
		else:
			velocity.y -= custom_gravity * delta
			#$AnimationTree.set("parameters/Jump_Blend/blend_amount", 0)
			can_jump = false
		

	if !is_on_floor() && jump_timer >= 0.3:
		jump_timer = 0.3
		can_jump = false


	if Input.is_action_just_pressed("move_jump"):
		air_timer = 0.0
		jump_timer = 0.0


		
	if Input.is_action_just_released("move_jump"):
		air_timer = 0.0
		jump_timer = 0.0
		if !is_on_floor() && jumping:
			print("HEY STOP SPAMMING JUMPS")

#func _process_walljump(delta):
	#if is_on_wall():
		#if Input.is_action_just_pressed("move_jump"):
			#var wall_normal = get_wall_normal()
			#if wall_normal != null && wall_normal != Vector3.ZERO:
				#wall_normal = wall_normal.normalized() 
				#velocity = wall_normal * (JUMP_VELOCITY * WALL_JUMP_VELOCITY_MULTIPLIER)
				#velocity.y += WALL_JUMP_VELOCITY_MULTIPLIER
#
				#has_wall_jumped = true
				#can_wall_jump = false
				#wall_jump_position = global_transform.origin
				#if has_wall_jumped:
					#for node in wall_wave:
							#node.global_transform.origin = wall_jump_position
							#if node.has_node("AnimationPlayer"):
								#node.get_node("AnimationPlayer").play("Landing_strong_001|CircleAction_002")

func _proccess_drift(delta):
	var drift_angle = 0
	if Input.is_action_pressed("move_drift") && is_on_floor():
		if Input.is_action_pressed("move_left"):
			drift_angle = 6
		elif Input.is_action_pressed("move_right"):
			drift_angle = -6
		armature.rotate_y(deg_to_rad(drift_angle)) 
	else:
		drift_angle = 0
		
func _physics_process(delta):
	_proccess_movement(delta)
	_proccess_jump(delta)
	_unhandled_input(delta)
	_proccess_bursting(delta)
	_proccess_cooldown(delta)
	_proccess_boosting(delta)
	_proccess_drift(delta)
	
	
	#if $Armature/Board/RayCast3D.is_colliding():
		#var ground_normal = $Armature/Board/RayCast3D.get_collision_normal()
		#armature.basis.y = ground_normal
		
	if $Armature/Board/RayCast3D.is_colliding():
		var ground_normal = $Armature/Board/RayCast3D.get_collision_normal()
		armature.basis.y = ground_normal
		
		
		
	if Input.is_action_just_pressed("mouse_left"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	sprinting = Input.is_action_pressed("move_sprint")
	dodging = Input.is_action_pressed("move_dodge")
	jumping = Input.is_action_pressed("move_jump")


	if is_on_floor():
		if sprinting && jumping:
			velocity.y = JUMP_VELOCITY * RUNJUMP_MULTIPLIER

	move_and_slide()


func _on_refill_cooldown_timeout():
	pass # Replace with function body.
