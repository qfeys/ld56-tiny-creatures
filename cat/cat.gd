extends CharacterBody2D

const SPEED = 400.0
const JOIN_DISTANCE_THRESHOLD = 100.0  # Distance threshold for joining
const SIT_TIME = 3.0  # Time to sit before going back to sit state
const HOP_TIME = 0.6  # Time to calculate hop target

@export var player: CharacterBody2D
@export var join_point_radius: float = 30.0

# Enum for states
enum State { SIT, MOVE, JOIN }

# State and timer variables
var current_state: State = State.SIT
var sit_timer: float = 0.0

# Join target point
var join_target: Vector2
var move_target: Vector2

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
    if position.distance_to(player.position) > JOIN_DISTANCE_THRESHOLD:
        _enter_join_state()
    # Transition from MOVE to SIT after a set amount of time
    elif sit_timer <= 0:
        _enter_move_state()

# MOVE state logic
func _move_state(delta: float) -> void:
    velocity = move_target.normalized() * SPEED
    move_target -= velocity * delta

    move_and_slide()

    # Check if it's time to sit again
    if move_target.length() < delta * SPEED:
        sit_timer = 0.6
        _enter_sit_state()

# JOIN state logic
func _join_state(delta: float) -> void:
    # Move towards the join target point
    var direction_to_target = (join_target - position).normalized()
    velocity = direction_to_target * SPEED * 1.5  # Run faster in join state

    move_and_slide()

    # Check if the NPC has reached the join point
    if position.distance_to(join_target) < 10.0:  # Consider the target reached
        _enter_move_state()

# Transition functions
func _enter_sit_state() -> void:
    current_state = State.SIT
    velocity = Vector2.ZERO
    if sit_timer <= 0.0:
        sit_timer = SIT_TIME

func _enter_move_state() -> void:
    current_state = State.MOVE
    sit_timer = 0.0
    var direction_to_player = (player.position - position)
    var direction_of_player = player.velocity
    # is 0.0 when distance < 30, 0.8 when distance > 60
    var to_player_fraction = clamp((direction_to_player.length() + 10) / 100.0, 0.0, 0.8)
    move_target = direction_to_player * to_player_fraction + direction_of_player * HOP_TIME
    print("New move target: ", move_target)

func _enter_join_state() -> void:
    current_state = State.JOIN
    join_target = player.position + Vector2(randf_range(-join_point_radius, join_point_radius), randf_range(-join_point_radius, join_point_radius))
