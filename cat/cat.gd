extends CharacterBody2D
class_name Cat

const SPEED = 400.0
const JOIN_DISTANCE_THRESHOLD = 100.0  # Distance threshold for joining
const join_point_radius: float = 50.0
const SIT_TIME = 3.0  # Time to sit before going back to sit state
const HOP_TIME = 0.6  # Time to calculate hop target

@export var player: CharacterBody2D

# Enum for states
enum State { SIT, MOVE, JOIN }

# State and timer variables
var current_state: State = State.SIT
var sit_timer: float = 0.0

# Join target point
var join_target: Vector2
var move_target: Vector2
var start_point: Vector2

func _ready():
    # Set the initial state
    current_state = State.SIT
    start_point = position

func _physics_process(delta):
    match current_state:
        State.SIT:
            _sit_state(delta)
        State.MOVE:
            _move_state(delta)
        State.JOIN:
            _join_state(delta)

# SIT state logic
func _sit_state(delta: float) -> void:
    velocity = Vector2.ZERO  # No movement
    
    # Increment sit timer
    sit_timer -= delta
    
    # Check if distance to player is too large to start JOIN state
    if player and position.distance_to(player.position) > JOIN_DISTANCE_THRESHOLD:
        _enter_join_state()
    # Transition from MOVE to SIT after a set amount of time
    elif sit_timer <= 0:
        _enter_move_state()

# MOVE state logic
func _move_state(delta: float) -> void:
    velocity = move_target.normalized() * SPEED
    move_target -= velocity * delta

    move_and_collide(velocity * delta)

    # Check if we're close enough to sit again
    if move_target.length() < delta * SPEED:
        sit_timer = 0.6
        _enter_sit_state()

    # Check for if the cat is bugged out - go to sit state
    sit_timer -= delta
    if sit_timer <= 0:
        print("Cat is bugged out, going to sit state")
        _enter_sit_state()

# JOIN state logic
func _join_state(delta: float) -> void:
    # Move towards the join target point
    var direction_to_target = (join_target - position).normalized()
    velocity = direction_to_target * SPEED * 1.5  # Run faster in join state

    var collision = move_and_collide(velocity * delta)

    # Check if the NPC has reached the join point
    if position.distance_to(join_target) < 10.0:  # Consider the target reached
        _enter_move_state()
    
    # If there is a collision, bounce away from it
    if collision:
        var normal = collision.get_normal()
        velocity = velocity.bounce(normal)
        # if the velocity vector and the normal vector are less than 10° away from each other
        # than change the velocity vector so it is 45° away from the normal vector
        var angle = velocity.angle_to(normal)
        if abs(angle) < deg_to_rad(10):
            #velocity = velocity.rotated(deg_to_rad(45))
            if angle > 0:
                velocity = velocity.rotated(deg_to_rad(45) - angle)
                #print("Deep bounce. Original angle: ", rad_to_deg(angle), "New angle: ", rad_to_deg(velocity.angle_to(normal)))
            else:
                velocity = velocity.rotated(deg_to_rad(-45) + angle)
                #print("Deep bounce. Original angle: ", rad_to_deg(angle), "New angle: ", rad_to_deg(velocity.angle_to(normal)))
        move_and_collide(velocity * delta)
        # Complete botch fallback
        if sit_timer <= 0.0:
            sit_timer = 4.0
        else:
            sit_timer -= 1.0
            if sit_timer <= 0.0:
                _enter_sit_state()

# Transition functions
func _enter_sit_state() -> void:
    current_state = State.SIT
    velocity = Vector2.ZERO
    if sit_timer <= 0.0:
        sit_timer = SIT_TIME

func _enter_move_state() -> void:
    current_state = State.MOVE
    sit_timer = 3.0
    if player:
        var direction_to_player = (player.position - position)
        var direction_of_player = player.velocity
        # is 0.0 when distance < 30, 0.8 when distance > 60
        var to_player_fraction = clamp((direction_to_player.length() - join_point_radius) / 100.0, 0.0, 0.8)
        move_target = direction_to_player * to_player_fraction + direction_of_player * HOP_TIME
    else:
        var pos_target = start_point + Vector2(randf_range(-join_point_radius, join_point_radius), randf_range(-join_point_radius, join_point_radius))
        move_target = pos_target - position

func _enter_join_state() -> void:
    current_state = State.JOIN
    join_target = player.position + Vector2(randf_range(-join_point_radius, join_point_radius), randf_range(-join_point_radius, join_point_radius))
