extends VehicleBody3D

#NOTES
#Let player have small influence when in the air
#Fix player and camera controller orientation
#Add grinding on rails by having player snap to the normal of the parent object of the grind rail detector


var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
var playerLook = camera.get_node("SpringArmPivot/Marker3D")

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
@export var MAX_STEER = .6
@export var ENGINE_POWER = 45
@export var olliePower = 40
@export var burstForce = 90
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

#NOTES
#This code rotates the player with the spring_arm_pivots y rotation, this is improted from COWBOY.gd
	#var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

func _ready():
	pass # Replace with function body.


func _process(delta: float) -> void:
	_proccess_jump(delta)
	_proccess_grinding(delta)
	_proccess_movement(delta)
	_proccess_bursting(delta)
	_proccess_reposition(delta)

	
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

	#var combined_input = ((left_input - right_input) * 2 + (left_pivot_input - right_pivot_input)/1.5) / 4.0  # Calculate the average
	var combined_input = ((left_input + right_input))/2 # Calculate the average
	var control_combined = ((left_pivot_input + right_input))
	var spring_arm_rotation = (spring_arm_pivot.rotation.y)

	steering = rotate_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER + (spring_arm_rotation * spring_arm_influence), delta * 1)
	#steering = rotate_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER, delta * 1)
	engine_force = Input.get_axis("move_back", "move_forward") * ENGINE_POWER 
	#print("Spring Arm Rot (Degrees): " + str(spring_arm_rotation))
	

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
	#var GrindCollision_collision = GrindCollision.is_colliding()
	#if GrindCollision_collision:
		#var colliding_object = GrindCollision.get_collider()
		#if colliding_object && colliding_object.name == "RailSnap1":
			#print("WORKING")
	pass

func _proccess_bursting(delta):
	if Input.is_action_just_pressed("move_dodge"):
		var forward_direction = -global_transform.basis.z
		apply_central_impulse(forward_direction.normalized() * burstForce)
		
func _proccess_reposition(delta):
	
	#Flips player over depending on the normal on the ground
	#Player cannot move until after leaving the reposition state
	var player_flipped_over = RepositionCast.is_colliding()
	var playerfliptimer = 0.0
	if player_flipped_over:
		#print(playerfliptimer)
		playerfliptimer += delta
		#if playerfliptimer > 0.2:
			##print("Player needs to be flipped")



func _on_area_3d_area_entered(area):
	if area.name == "RailSnap1":
		railPlayerGrab.position = position 
		print("Player collided with rail point")
		pass
	pass # Replace with function body.
