extends Area2D

# When the player enteres the gate, the game is over.
# All the cats in the tree who have the player attached should be counted, and the end screen should be shown.
var end_screen = preload("res://UI/end_screen.tscn").instantiate()

func _on_body_entered(body):
    print("body entered")
    if body.name == "player":
        call_deferred("scene_swap")

func scene_swap():
    var cats = get_tree().get_nodes_in_group("cat")
    var cats_in_tree = 0
    for cat in cats:
        if cat.player:
            cats_in_tree += 1
    var tree = get_tree()
    print("step 1")
    if not end_screen:
        printerr("End screen not available")
        return
    print("step 2")
    tree.root.add_child(end_screen)
    print("step 3")
    end_screen.set_score(cats_in_tree)
    print("step 4")
    get_node("/root/Main").free()
    print("step 5")
