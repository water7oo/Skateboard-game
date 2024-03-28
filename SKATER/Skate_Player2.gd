extends RigidBody3D

@export var speed: float = 100.0  # Speed of the vehicle
@export var turn_speed: float = 100.0  # Turning speed of the vehicle
var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")


func _physics_process(delta: float) -> void:
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Calculate movement direction
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Rotate direction based on spring arm pivot's rotation
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

	# Apply movement force
	var forward_force = direction * speed
	apply_central_impulse(forward_force * delta)

	# Calculate rotation based on input
	var target_rotation = -input_dir.x

	# Apply rotation
	var current_rotation = rotation_degrees
	current_rotation.y += target_rotation * turn_speed * delta

	rotation_degrees = current_rotation
