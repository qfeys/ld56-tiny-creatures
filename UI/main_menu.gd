extends Control


func start():
    get_tree().change_scene_to_file("res://main.tscn")

func quit():
    get_tree().quit()
