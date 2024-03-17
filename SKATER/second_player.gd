extends VehicleBody3D

var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
@onready var Raycast = $Armature/Board/RayCast3D
@export var MAX_STEER = .4
@export var ENGINE_POWER = 20

@export var mouse_sensitivity = 0.004
@export var joystick_sensitivity = 0.005 
@export var cam_target : Node3D
@export var cam_l : Node3D
@export var cam_r : Node3D

@onready var armature = $Armature

var can_jump = true

#NOTES
#This code rotates the player with the spring_arm_pivots y rotation, this is improted from COWBOY.gd
	#var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

func _ready():
	pass # Replace with function body.


func _process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER, delta * 2.5)
	engine_force = Input.get_axis("move_back", "move_forward") * ENGINE_POWER 
	
	_proccess_jump(delta)
	#if Input.is_action_pressed("move_right"):
		#spring_arm_pivot.global_transform = cam_r.global_transform
	#elif Input.is_action_pressed("move_left"):
		#spring_arm_pivot.global_transform = cam_l.global_transform
	#else:
		#spring_arm_pivot.global_transform = cam_target.global_transform
		


func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:

		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y =  move_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER, 2.5)

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
	


func _proccess_jump(delta):
	if Input.is_action_just_pressed("move_jump") && can_jump == true:
		can_jump = false
		apply_impulse(Vector3(0,30,0))
	else:
		can_jump = true
