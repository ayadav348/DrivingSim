extends Node3D

var tunnel_scene = preload("res://tunnel.tscn")

func _ready():
	# Spawn the very first tunnel at position (0,0,0)
	spawn_tunnel(Vector3.ZERO)
	
func spawn_tunnel(spawn_location: Vector3):
	var new_tunnel = tunnel_scene.instantiate()
	new_tunnel.position = spawn_location
	add_child(new_tunnel)
	

	var threshold = new_tunnel.find_child("Threshold")
	
	var next_location = spawn_location + Vector3(0, 0, -500)
	
	
	threshold.body_entered.connect(_on_threshold_entered.bind(next_location, threshold))


func _on_threshold_entered(body, next_pos, trigger_zone):

	spawn_tunnel(next_pos)
		
		# preventing infinite loops if the player drives back and forth
	trigger_zone.queue_free()
