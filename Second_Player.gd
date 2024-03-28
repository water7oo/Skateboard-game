extends RigidBody3D

var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")

@onready var armature = $Armature
@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 0.1
@export var baseSpeed = 20
@export var maxSpeed = 50
@export var angularAcceleration = 25
@export var jumpPower = 10
@export var custom_gravity = 25
@export var rotationSpeed = 5
@export var turnAngle = 45
var is_moving = false

func _ready():
	pass

func _input(event):
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

func _physics_process(delta):
	var direction = Vector3.ZERO
	var spring_arm_rotation = spring_arm_pivot.rotation.y

	if Input.is_action_pressed("move_right"):
		direction += -spring_arm_pivot.transform.basis.x
	if Input.is_action_pressed("move_left"):
		direction += spring_arm_pivot.transform.basis.x
	if Input.is_action_pressed("move_back"):
		direction += -spring_arm_pivot.transform.basis.z
	if Input.is_action_pressed("move_forward"):
		direction += spring_arm_pivot.transform.basis.z


	apply_impulse(Vector3(direction.x, 0, direction.z) * baseSpeed, Vector3.ZERO)

	var velocity_magnitude = get_linear_velocity().length()
	if velocity_magnitude > maxSpeed:
		set_linear_velocity(get_linear_velocity().normalized() * maxSpeed)

	var gravity = Vector3(0, -custom_gravity, 0)
	apply_central_force(gravity)
