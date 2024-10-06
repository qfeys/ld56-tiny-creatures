extends CharacterBody2D

@export var main_sprite: Sprite2D
@export var ground_shadow: Sprite2D
@export var footstep_sound: AudioStreamPlayer

const SPEED = 200.0
const CRAWL_SPEED = 80.0
const JUMP_SPEED = 200.0
const ACCELERATION = 1000.0
const JUMP_TIME = 0.5
const JUMP_HEIGHT = 32.0

var is_crawling: bool = false
var is_jumping: bool = false
var jump_timer: float = 0.0
var jump_start: Vector2
var jump_direction: Vector2

var time_until_tutorial: float = 6.0

func _physics_process(delta):
    time_until_tutorial -= delta
    if time_until_tutorial < 0.0:
        get_node("/root/Main/tutorial").call_deferred("open_abilities")

    if is_jumping:
        do_jump(delta)
        return
    if Input.is_action_just_pressed("action_jump"):
        start_jump()
        do_jump(delta)
        return

    if( Input.is_action_pressed("action_crawl")):
        is_crawling = true
    else:
        is_crawling = false

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var direction = Vector2( Input.get_axis("action_left", "action_right"), Input.get_axis("action_up", "action_down")).normalized()
    if direction:
        #velocity = direction * SPEED * ( 0.4 if is_crawling else 1.0)
        velocity.x = move_toward(velocity.x, direction.x * (CRAWL_SPEED if is_crawling else SPEED), ACCELERATION * delta)
        velocity.y = move_toward(velocity.y, direction.y * (CRAWL_SPEED if is_crawling else SPEED), ACCELERATION * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
        velocity.y = move_toward(velocity.y, 0, ACCELERATION * delta)

    var collider = move_and_collide(velocity * delta)
    if velocity != Vector2.ZERO and footstep_sound.playing == false:
        footstep_sound.play()

    if collider:
        collider_handle(collider)

func collider_handle(collider: KinematicCollision2D) -> void:
    var obj = collider.get_collider()
    
    if obj.is_class("CharacterBody2D"):
        var cat: Cat = obj
        cat.player = self

func start_jump() -> void:
    is_jumping = true
    jump_direction = Vector2( Input.get_axis("action_left", "action_right"), Input.get_axis("action_up", "action_down")).normalized()
    collision_mask = 6
    jump_timer = 0.0


func do_jump(delta: float) -> void:
    velocity = jump_direction * JUMP_SPEED
    move_and_collide(velocity * delta)

    var jump_fraction = jump_timer / JUMP_TIME # goes from 0 to 1
    var y_offset = 4 * jump_fraction * (jump_fraction - 1)
    main_sprite.position = Vector2(0, y_offset * JUMP_HEIGHT)

    jump_timer += delta
    if jump_timer > JUMP_TIME:
        is_jumping = false
        collision_mask = 5
        main_sprite.position = Vector2.ZERO
        return
