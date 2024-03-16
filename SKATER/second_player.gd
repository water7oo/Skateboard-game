extends VehicleBody3D

var camera = preload("res://SKATER/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
const MAX_STEER = 0.3
const ENGINE_POWER = 75

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER, delta * 2.5)
	engine_force = Input.get_axis("move_back", "move_forward") * ENGINE_POWER 
	spring_arm_pivot.global_position = spring_arm_pivot.global_position.lerp(global_position, delta * 20)
	spring_arm_pivot.transform = spring_arm_pivot.transform.interpolate_with(transform, delta * 5.0)
