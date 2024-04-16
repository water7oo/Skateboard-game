extends VehicleBody3D

var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
var playerLook = camera.get_node("SpringArmPivot/MeshInstance3D")

var rail = preload("res://Game/railings.tscn").instantiate()
var railPlayerGrab = rail.get_node("Path3D/PathFollow3D/playerGrabber")
var grindSnap1 = rail.get_node("RailSnap1")
var grindSnap2 = rail.get_node("RailSnap2")
@onready var GrindCollision = $GrindCollision


@onready var board = $Board
@onready var rwheel = $VehicleWheel3D
@onready var lwheel = $VehicleWheel3D2
@onready var rwheel2 = $VehicleWheel3D3
@onready var lwheel2 = $VehicleWheel3D4
@onready var Raycast = $Board/RayCast3D
@onready var RepositionCast = $Board/RepositionCast
var raycast_timer = 0.0
@export var MAX_STEER = .2
@export var ENGINE_POWER = 30
@export var olliePower = 40
@export var burstForce = 90
@export var torquePower = 100
var jumpUses = 1 


@export var mouse_sensitivity = .005
@export var spring_arm_influence = 0.2
@export var joystick_sensitivity = .005
@export var cam_target : Node3D
@export var cam_l : Node3D
@export var cam_r : Node3D
@onready var mass_center_node = $CenterOfMass


@onready var armature = $Armature

var can_jump = true


func _ready():
	pass # Replace with function body.


func _process(delta: float) -> void:
	_proccess_jump(delta)
	_proccess_grinding(delta)
	_proccess_movement(delta)
	_proccess_bursting(delta)
	_proccess_reposition(delta)
	_proccess_drifting(delta)

	
	var Raycast_collision = Raycast.is_colliding()
	
	if !Raycast_collision:
		raycast_timer += delta
		if Input.is_action_just_pressed("move_right"):
			apply_torque_impulse(Vector3(0, -torquePower, 0))
			axis_lock_angular_x = true
			axis_lock_angular_z = true
		elif Input.is_action_just_pressed("move_left"):
			apply_torque_impulse(Vector3(0, torquePower, 0))
			axis_lock_angular_x = true
			axis_lock_angular_z = true
		else:
			raycast_timer = 0.0
			axis_lock_angular_x = false
			axis_lock_angular_z = false
			
			

func _proccess_movement(delta):
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

	var combined_input = ((left_input + right_input))/2 # Calculate the average
	var control_combined = ((left_pivot_input + right_input))
	var spring_arm_rotation = (spring_arm_pivot.rotation.y)

	steering = rotate_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER + (spring_arm_rotation * spring_arm_influence), delta * 1)
	engine_force = Input.get_axis("move_back", "move_forward") * ENGINE_POWER 
	print((spring_arm_pivot.rotation.y))
	
	if Input.is_action_just_pressed("move_forward"):
		var spring_forward = -spring_arm_pivot.global_transform.basis.z

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
		
		var rotation_degrees = rad_to_deg(spring_arm_pivot.rotation.y)

	if Input.is_action_pressed("cam_down"):
		spring_arm_pivot.rotation.x -= joystick_sensitivity 
	if Input.is_action_pressed("cam_up"):
		spring_arm_pivot.rotation.x += joystick_sensitivity 
	if Input.is_action_pressed("cam_right"):
		spring_arm_pivot.rotation.y -= joystick_sensitivity 
	if Input.is_action_pressed("cam_left"):
		spring_arm_pivot.rotation.y += joystick_sensitivity 
	

func _proccess_jump(delta):
	var Raycast_collision = Raycast.is_colliding()
	
	if Input.is_action_just_pressed("move_jump") && jumpUses == 1 && Raycast_collision:
		jumpUses -= 1
		apply_central_impulse(Vector3(0,olliePower,0))
		
	if Raycast_collision:
		jumpUses = 1


func _proccess_grinding(delta):
#might add effects with this function 
	pass

func _proccess_bursting(delta):
	#Bursting can only be done if player fills trick guage 
	if Input.is_action_just_pressed("move_dodge"):
		var forward_direction = -global_transform.basis.z
		hit_stop(0.5, 1.5)
		apply_central_impulse(forward_direction.normalized() * burstForce)
		
func _proccess_reposition(delta):
	
	#Flips player over depending on the normal on the ground
	#Player cannot move until after leaving the reposition state
	#If players currently rotation is 180 degrees and repo raycast is colliding -> flip the player 180 degrees
	pass
	
	
func _proccess_drifting(delta):
	#If player is going at a certain speed and is pressing the drift button -> change settings so player drifts 
	#(make a drift state?)
	if Input.is_action_just_pressed("move_drift"):
		print("Drifting")


func hit_stop(timeScale, duration):
		Engine.time_scale = timeScale
		var timer = get_tree().create_timer(timeScale * duration)
		await timer.timeout
		Engine.time_scale = 1
		

func _on_area_3d_area_entered(area):
#For grinding have the player land on the grind rail and parent to the path, the paths progress with 
#interpolate to the other side until the player hits the exit for the rail and will be popped off/un parented
	
	if area.name == "RailSnap2":
		apply_central_impulse(Vector3(50,50,0))
		pass
	pass # Replace with function body.
