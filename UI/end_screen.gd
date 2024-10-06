extends Control

@export var score_label: Label

func set_score(score: int):
    score_label.text = str(score) + " cats"
    
func open_main_menu():
    get_tree().change_scene_to_file("res://UI/main_menu.tscn")

func restart():
    get_tree().change_scene_to_file("res://main.tscn")

func quit():
    get_tree().quit()
