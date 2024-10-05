extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const JOIN_DISTANCE_THRESHOLD = 500.0  # Distance threshold for joining
const SIT_TIME = 3.0  # Time to sit before going back to sit state

@export var player: CharacterBody2D
@export var join_point_radius: float = 100.0

# Enum for states
enum State { SIT, MOVE, JOIN }

# State and timer variables
var current_state: State = State.SIT
var sit_timer: float = 0.0

# Join target point
var join_target: Vector2

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
    sit_timer += delta
    
    # Check if distance to player is too large to start JOIN state
    if position.distance_to(player.position) > JOIN_DISTANCE_THRESHOLD:
        _enter_join_state()
    # Transition from MOVE to SIT after a set amount of time
    elif sit_timer >= SIT_TIME:
        _enter_move_state()

# MOVE state logic
func _move_state(delta: float) -> void:
    var direction_to_player = (player.position - position).normalized()
    velocity = direction_to_player * SPEED

    move_and_slide()

    # Check if it's time to sit again
    sit_timer += delta
    if sit_timer >= SIT_TIME:
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
    sit_timer = 0.0

func _enter_move_state() -> void:
    current_state = State.MOVE
    sit_timer = 0.0

func _enter_join_state() -> void:
    current_state = State.JOIN
    join_target = player.position + Vector2(randf_range(-join_point_radius, join_point_radius), randf_range(-join_point_radius, join_point_radius))
