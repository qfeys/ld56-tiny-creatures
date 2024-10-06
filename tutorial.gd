extends Node2D

@export var camera: Camera2D

@export var movement: PanelContainer
@export var abilities: PanelContainer
@export var agitation: PanelContainer
@export var fights: PanelContainer
@export var anxiety: PanelContainer

var abilities_has_been_opened: bool = false
var agitation_has_been_opened: bool = false
var fights_has_been_opened: bool = false
var anxiety_has_been_opened: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("open_movement")



func close_all():
    movement.visible = false
    abilities.visible = false
    agitation.visible = false
    fights.visible = false
    anxiety.visible = false
    get_tree().paused = false

func open_movement():
    movement.visible = true
    get_tree().paused = true

func open_abilities():
    if abilities_has_been_opened:
        return
    abilities_has_been_opened = true
    abilities.visible = true
    get_tree().paused = true

func open_agitation(cat: Node2D):
    if agitation_has_been_opened:
        return
    agitation_has_been_opened = true
    camera.position = cat.position
    agitation.visible = true
    get_tree().paused = true

func open_fights(cat: Node2D):
    if fights_has_been_opened:
        return
    fights_has_been_opened = true
    camera.position = cat.position
    fights.visible = true
    get_tree().paused = true

func open_anxiety(cat: Node2D):
    if anxiety_has_been_opened:
        return
    anxiety_has_been_opened = true
    camera.position = cat.position
    anxiety.visible = true
    get_tree().paused = true
