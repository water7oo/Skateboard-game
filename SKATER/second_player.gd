extends VehicleBody3D

var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
var playerLook = camera.get_node("SpringArmPivot/Marker3D")
@onready var board = $Board
@onready var rwheel = $VehicleWheel3D
@onready var lwheel = $VehicleWheel3D2
@onready var rwheel2 = $VehicleWheel3D3
@onready var lwheel2 = $VehicleWheel3D4
@onready var Raycast = $Board/RayCast3D
var raycast_timer = 0.0
@export var MAX_STEER = .3
@export var ENGINE_POWER = 20

@export var mouse_sensitivity = .005
@export var spring_arm_influence = 0.2
@export var joystick_sensitivity = .005
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
	_proccess_jump(delta)
	var right_input = Input.get_action_strength("move_right")
	var left_input = Input.get_action_strength("move_left")
	var control_r = Input.is_action_pressed("cam_right")
	var control_l = Input.is_action_pressed("cam_left")
	
	var right_pivot_input = 0.0
	var left_pivot_input = 0.0
	
	if Input.is_action_pressed("cam_right"):
		right_pivot_input += 4.0 * joystick_sensitivity
	if Input.is_action_pressed("cam_left"):
		left_pivot_input += 4.0 * joystick_sensitivity

	#var combined_input = ((left_input - right_input) * 2 + (left_pivot_input - right_pivot_input)/1.5) / 4.0  # Calculate the average
	var combined_input = ((left_input + right_input)) # Calculate the average
	var control_combined = ((left_pivot_input + right_input))

	steering = move_toward(steering, (spring_arm_pivot.rotation.y * spring_arm_influence) - Input.get_axis("move_left", "move_right") * MAX_STEER, delta * 1)
	engine_force = Input.get_axis("move_back", "move_forward") * ENGINE_POWER 
	
	#var Raycast_collision = Raycast.is_colliding()
	#
	#Fixes players orientation when upside down or when raycast timer goes off
	#if !Raycast_collision || rotation.y == 45:
		#raycast_timer += delta
		#print(raycast_timer)
		#
		#if raycast_timer >= 3:
			#rotation.y = Vector3.UP
		#else:
			#print("fix playered")
	
func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
		

	if event is InputEventMouseMotion:
		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-8), deg_to_rad(2))
		rotation_y = clamp(rotation_y, deg_to_rad(-8), deg_to_rad(2))
		spring_arm_pivot.rotation.x = rotation_x 
		spring_arm_pivot.rotation.y = rotation_y
		
		var rotation_degrees = deg_to_rad(spring_arm_pivot.rotation.y)
		print("Spring Arm Rot (Degrees): " + str(rotation_degrees))



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


