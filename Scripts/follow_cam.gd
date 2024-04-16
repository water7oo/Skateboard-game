extends Node3D

@export var target: NodePath
@export var speed := 1.0
@export var enabled: bool
@export var spring_arm_pivot: Node3D
@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 0.005 

@export var randomStrength: float = .4
@export var shakeFade: float = .7
var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0
var original_global_transform: Transform3D
var target_node: Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_as_top_level(true)
	target_node = get_node(target) as Node3D
	original_global_transform = target_node.global_transform

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-80), deg_to_rad(-1))

		spring_arm_pivot.rotation.x = rotation_x
		spring_arm_pivot.rotation.y = rotation_y

func apply_shake():
	shake_strength = randomStrength

func _process(delta: float) -> void:
	_unhandled_input(delta)
	
	if Input.is_action_just_pressed("move_jump"):
		apply_shake()

	if not enabled or not target_node:
		return

	var new_global_transform = global_transform.interpolate_with(target_node.global_transform, speed * delta)
	global_transform.origin = new_global_transform.origin

	if shake_strength > 0:
		shake_strength = max(0, shake_strength - delta * shakeFade)
		global_transform.origin += randomOffset()
		# Apply the remaining shake to the camera


func randomOffset() -> Vector3:
	return Vector3(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength), 0)
