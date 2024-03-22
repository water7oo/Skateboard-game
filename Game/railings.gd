extends StaticBody3D

const playerGroup = "player"
@export var player = preload("res://SKATER/second_player.tscn").instantiate()
@onready var grindBox = player.get_node("GrindBox")
@onready var playerGrindPivot = player.get_node("PlayerGrindPivot")
@onready var RailSnap1 = $Path3D/RailSnap1
@onready var RailSnap2 = $Path3D/RailSnap2
@onready var PathFollow = $Path3D/PathFollow3D
@onready var playerGrabber = $Path3D/PathFollow3D/playerGrabber

var current_progress = 1
var target_progress = 0
var interpolation_speed = 0.002
var currently_grinding = false

func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
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
	#if area.name == "GrindBox":
		#current_progress = current_progress - 1
		#playerGrabber.remote_path = player.get_path()
		#currently_grinding = true
	pass # Replace with function body.


func _on_rail_snap_1_area_exited(area):
	#if area.name == "GrindBox":
		#print("Object has left")
		#current_progress = 0
	pass # Replace with function body.
