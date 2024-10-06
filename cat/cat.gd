extends CharacterBody2D
class_name Cat

const SPEED = 350.0
const CRAWL_SPEED = 100.0
const JOIN_DISTANCE_FAR = 100.0  # Distance threshold for joining
const JOIN_DISTANCE_SHORT = 50.0
const SIT_TIME = 3.0  # Time to sit before going back to sit state
const HOP_TIME = 0.6  # Time to calculate hop target

@export var player: CharacterBody2D
@export var agitation_bar: ProgressBar
@export var warning_lable: Label
@export var audio_manager: Node2D

# Enum for states
enum State { SIT, MOVE, JOIN, CRAWL, ANXIOUS, LEAVE }

# State and timer variables
var current_state: State = State.SIT
var sit_timer: float = 0.0

# Join target point
var join_target: Vector2
var move_target: Vector2
var start_point: Vector2

var agitation: float = 0.0 # goes from 0 to 100
const AGITATION_COOLDOWN_SPEED = 8.0
var was_in_attack_timer: float = 0.0
const ATTACK_COOLDOWN = 1.0

func _ready():
    # Set the initial state
    current_state = State.SIT
    start_point = position

func _physics_process(delta):
    agitation = clamp(agitation, 0.0, 100.0)
    set_ui(delta)
    match current_state:
        State.SIT:
            _sit_state(delta)
        State.MOVE:
            _move_state(delta)
        State.JOIN:
            _join_state(delta)
        State.CRAWL:
            _crawl_state(delta)
        State.ANXIOUS:
            _anxious_state(delta)
        State.LEAVE:
            _leave_state(delta)

func set_ui(delta):
    agitation_bar.value = agitation
    warning_lable.text = ""
    if not player:
        warning_lable.text += "?"
    was_in_attack_timer -= delta
    if was_in_attack_timer > 0.0:
        warning_lable.text += "!"
    if current_state == State.ANXIOUS:
        var ticker : int = sit_timer * 2
        if ticker % 2 == 0:
            warning_lable.text += "?!?"
        else:
            warning_lable.text += "!?!"

# SIT state logic
func _sit_state(delta: float) -> void:
    velocity = Vector2.ZERO  # No movement

    if agitation >= 100.0:
        _enter_anxious_state()
        return
    
    # Increment sit timer
    sit_timer -= delta
    agitation -= AGITATION_COOLDOWN_SPEED * delta
    
    # Check if distance to player is too large to start JOIN state
    if player and position.distance_to(player.position) > JOIN_DISTANCE_FAR:
        _enter_join_state()
    # Transition from MOVE to SIT after a set amount of time
    elif sit_timer <= 0:
        _enter_move_state()

# MOVE state logic
func _move_state(delta: float) -> void:
    if player and player.is_crawling:
        _enter_crawl_state()
        return
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
        agitation += 10
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
        match collision.get_collider().get_class():
            "TileMapLayer":
                get_node("/root/Main/tutorial").call_deferred("open_agitation", self)
                agitation += 5
                var normal = collision.get_normal()
                velocity = velocity.bounce(normal)
                # if the velocity vector and the normal vector are less than 10° away from each other
                # than change the velocity vector so it is 45° away from the normal vector
                var angle = velocity.angle_to(normal)
                if abs(angle) < deg_to_rad(10):
                    agitation += 5
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
                        agitation += 10
                        _enter_sit_state()
            
            "CharacterBody2D":
                if agitation > 10 and collision.get_collider().has_method("get_slashed"):
                    collision.get_collider().get_slashed(agitation / 10.0)
                    was_in_attack_timer = ATTACK_COOLDOWN
                    _enter_sit_state()
                    get_node("/root/Main/tutorial").open_fights(self)
                else: # means it's the player
                    agitation -= 10
                    _enter_sit_state()

func _crawl_state(delta: float) -> void:
    if player.is_crawling == false:
        _enter_move_state()
        return
    agitation -= AGITATION_COOLDOWN_SPEED * delta
    var player_distance = position.distance_to(player.position)
    if player_distance < JOIN_DISTANCE_SHORT:
        velocity = player.velocity.normalized() * CRAWL_SPEED
    elif player_distance < JOIN_DISTANCE_FAR:
        velocity = (player.position - position).normalized() * CRAWL_SPEED
    else:
        _enter_join_state()
    move_and_collide(velocity * delta)

func _anxious_state(delta: float) -> void:
    if position.distance_to(player.position) < JOIN_DISTANCE_SHORT:
        if player.is_crawling:
            agitation -= AGITATION_COOLDOWN_SPEED * 10 * delta
        else:
            agitation -= AGITATION_COOLDOWN_SPEED * delta
    else:
        agitation += AGITATION_COOLDOWN_SPEED * delta
    if agitation <= 0.0:
        _enter_sit_state()
    elif agitation >= 100.0:
        sit_timer -= delta
        if sit_timer <= 0.0:
            _enter_leave_state()

# LEAVE state logic
func _leave_state(delta: float) -> void:
    velocity = move_target.normalized() * SPEED
    move_target -= velocity * delta
    move_and_collide(velocity * delta)
    modulate.a = max(0.0, modulate.a - delta)
    if move_target.length() < delta * SPEED:
        queue_free()

# Transition functions
func _enter_sit_state() -> void:
    current_state = State.SIT
    velocity = Vector2.ZERO
    if sit_timer <= 0.0:
        sit_timer = SIT_TIME
    audio_manager.play_random()

func _enter_move_state() -> void:
    current_state = State.MOVE
    sit_timer = 3.0
    if player:
        var direction_to_player = (player.position - position)
        var direction_of_player = player.velocity
        # is 0.0 when distance < 30, 0.8 when distance > 60
        var to_player_fraction = clamp((direction_to_player.length() - JOIN_DISTANCE_SHORT) / 100.0, 0.0, 0.8)
        move_target = direction_to_player * to_player_fraction + direction_of_player * HOP_TIME
    else:
        var pos_target = start_point + Vector2(randf_range(-JOIN_DISTANCE_SHORT, JOIN_DISTANCE_SHORT), randf_range(-JOIN_DISTANCE_SHORT, JOIN_DISTANCE_SHORT))
        move_target = pos_target - position

func _enter_join_state() -> void:
    current_state = State.JOIN
    join_target = player.position + Vector2(randf_range(-JOIN_DISTANCE_SHORT, JOIN_DISTANCE_SHORT), randf_range(-JOIN_DISTANCE_SHORT, JOIN_DISTANCE_SHORT))

func _enter_crawl_state() -> void:
    current_state = State.CRAWL
    velocity = Vector2.ZERO
    sit_timer = 3.0
    if not player:
        _enter_sit_state()
        printerr("Cat has no player to crawl to")

func _enter_anxious_state() -> void:
    get_node("/root/Main/tutorial").call_deferred("open_anxiety", self)
    current_state = State.ANXIOUS
    velocity = Vector2.ZERO
    sit_timer = 3.0

func _enter_leave_state() -> void:
    current_state = State.LEAVE
    collision_mask = 0
    # move away from the player
    move_target = (position - player.position).normalized() * SPEED * 1.0

func get_slashed(damage: float):
    agitation += damage
    was_in_attack_timer = ATTACK_COOLDOWN
    _enter_move_state()
    audio_manager.play_fight()
