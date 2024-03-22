extends RigidBody3D

@export var speed: float = 100.0  # Speed of the vehicle
@export var turn_speed: float = 1.0  # Turning speed of the vehicle

func _physics_process(delta: float) -> void:
	# Calculate movement based on input
	var movement = Vector3(0, 0, 0)
	movement.z = -Input.get_action_strength("move_forward") + Input.get_action_strength("move_back")

	# Apply movement force
	var forward_force = transform.basis.z * movement.z * speed
	apply_central_impulse(forward_force * delta)

	# Calculate rotation based on input
	var target_rotation = Vector3(0, 0, 0)
	target_rotation.y = -Input.get_action_strength("move_right") + Input.get_action_strength("move_left")

	# Apply rotation
	var current_rotation = rotation_degrees
	current_rotation.y += target_rotation.y * turn_speed * delta
	rotation_degrees = current_rotation
