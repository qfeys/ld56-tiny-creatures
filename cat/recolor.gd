extends Sprite2D

@export var black: Color = Color(0, 0, 0, 1)
@export var white: Color = Color(1, 1, 1, 1)
@export var red: Color = Color(1, 0, 0, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
    # pick random variables
    var blackness = randf()
    var redness = randf()**2
    var mix_color = (black * blackness + white * (1 - blackness)) * (1 - redness) + red * redness
    modulate = mix_color
