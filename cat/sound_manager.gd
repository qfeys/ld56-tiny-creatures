extends Node2D

@export var rand_1: AudioStreamPlayer2D
@export var rand_2: AudioStreamPlayer2D
@export var rand_3: AudioStreamPlayer2D
@export var rand_4: AudioStreamPlayer2D
@export var fight_1: AudioStreamPlayer2D
@export var fight_2: AudioStreamPlayer2D

var time_since_last_rand: float = 0.0
const MAX_TIME_BETWEEN_RANDS = 3.0

func play_random():
    if time_since_last_rand > MAX_TIME_BETWEEN_RANDS:
        time_since_last_rand = 0.0
        match randi() % 4:
            0:
                rand_1.play()
            1:
                rand_2.play()
            2:
                rand_3.play()
            3:
                rand_4.play()


func play_fight():
    match randi() % 2:
        0:
            fight_1.play()
        1:
            fight_2.play()

func _process(delta):
    time_since_last_rand += delta
