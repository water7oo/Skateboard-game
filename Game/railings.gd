extends StaticBody3D

#If player touches other rail snap, then unparent player from remote 
#-transform node, same with the other way around

#take the current direction the player is going and move them along the path according to their direction
#In order to do that add a rail whole area and see where the player 
#-lands on the rail and have them continue from there

const playerGroup = "player"
@export var player = preload("res://SKATER/second_player.tscn").instantiate()
@onready var grindBox = player.get_node("GrindBox")
@onready var playerGrindPivot = player.get_node("PlayerGrindPivot")
@onready var RailSnap1 = $Path3D/RailSnap1
@onready var RailSnap2 = $Path3D/RailSnap2
@onready var PathFollow = $Path3D/PathFollow3D
@onready var playerGrabber = $Path3D/PathFollow3D/playerGrabber
@onready var railCollision = $RailCollision

var current_progress = 1
var target_progress = 0
var interpolation_speed = 0.009
var currently_grinding = false

func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_proccess_railProg(delta)
	if Input.is_action_just_pressed("move_jump") && playerGrabber.remote_path == player.get_path():
		playerGrabber.remote_path = NodePath("")
		print("Player has jumped off rail")
		
	

func _proccess_railProg(delta):
	current_progress = move_toward(current_progress, target_progress, interpolation_speed)
	
	if current_progress == target_progress:
		current_progress = 1
		
		
	PathFollow.progress_ratio = current_progress
	pass
	
func _on_rail_snap_1_area_entered(area):
	if area.name == "GrindBox":
		current_progress = 1
		playerGrabber.remote_path = player.get_path()
		currently_grinding = true
	pass # Replace with function body.


func _on_rail_snap_2_area_entered(area):
	if area.name == "GrindBox":
		playerGrabber.remote_path = NodePath("")
	pass # Replace with function body.


func _on_rail_snap_1_area_exited(area):
	#if area.name == "GrindBox":
		#print("Object has left")
		#current_progress = 0
	pass # Replace with function body.
