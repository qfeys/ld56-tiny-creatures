extends Camera2D

@export var player: Node2D

func _process(delta):
    # Update the camera to follow the player
    global_position = player.global_position
