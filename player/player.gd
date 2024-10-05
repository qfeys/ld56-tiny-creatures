extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -400.0

var is_crawling: bool = false


func _physics_process(delta):

    if( Input.is_action_pressed("action_crawl")):
        is_crawling = true
    else:
        is_crawling = false

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var direction = Vector2( Input.get_axis("action_left", "action_right"), Input.get_axis("action_up", "action_down"))
    if direction:
        velocity = direction.normalized() * SPEED * ( 0.4 if is_crawling else 1.0)
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.y = move_toward(velocity.y, 0, SPEED)

    move_and_slide()
