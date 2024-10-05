extends TileMapLayer


@export var displayTilemap: TileMapLayer
@export var grass_placeholder_atlas_coord: Vector2i
@export var forrest_placeholder_atlas_coord: Vector2i
@export var water_placeholder_atlas_coord: Vector2i
enum TileType {NONE, GRASS, FORREST, WATER}
@export var dual_map_grass_forrest_atlas_start: Vector2i
@export var dual_map_grass_water_atlas_start: Vector2i
@export var dual_map_forrest_water_atlas_start: Vector2i

const NEIGHBOURS = [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]
var neighbours_to_atlas_coord = {
    [true, true, true, true]: Vector2i(2, 1),   # All corners
    [false, false, false, true]: Vector2i(1, 3),  # Outer bottom-right corner
    [false, false, true, false]: Vector2i(0, 0),  # Outer bottom-left corner
    [false, true, false, false]: Vector2i(0, 2),  # Outer top-right corner
    [true, false, false, false]: Vector2i(3, 3),  # Outer top-left corner
    [false, true, false, true]: Vector2i(1, 0),   # Right edge
    [true, false, true, false]: Vector2i(3, 2),   # Left edge
    [false, false, true, true]: Vector2i(3, 0),   # Bottom edge
    [true, true, false, false]: Vector2i(1, 2),   # Top edge
    [false, true, true, true]: Vector2i(1, 1),    # Inner bottom-right corner
    [true, false, true, true]: Vector2i(2, 0),    # Inner bottom-left corner
    [true, true, false, true]: Vector2i(2, 2),    # Inner top-right corner
    [true, true, true, false]: Vector2i(3, 1),    # Inner top-left corner
    [false, true, true, false]: Vector2i(2, 3),   # Bottom-left top-right corners
    [true, false, false, true]: Vector2i(0, 1),   # Top-left down-right corners
    [false, false, false, false]: Vector2i(0, 3)  # No corners
}

func _process(delta):
    if( Input.is_action_pressed("action_crawl")):
        displayTilemap.visible = false
    else:
        displayTilemap.visible = true


# Called when the node enters the scene tree for the first time.
func _ready():
    # refresh all display tiles
    for coord in get_used_cells():
        set_display_tile(coord)

func set_tile(coords: Vector2i, atlas_coords: Vector2i):
    set_cell(coords, 0, atlas_coords)
    set_display_tile(coords)
    
func set_display_tile(pos: Vector2i):
    # loop through 4 neighbours
    for i in range(0,4):
        var new_pos: Vector2i = pos + NEIGHBOURS[i];
        displayTilemap.set_cell(new_pos, 0, calculate_display_tile(new_pos))

func calculate_display_tile(coords: Vector2i) -> Vector2i:
    # Get 4 world tile neighbors
    var bot_right = get_world_tile(coords - NEIGHBOURS[0])
    var bot_left = get_world_tile(coords - NEIGHBOURS[1])
    var top_right = get_world_tile(coords - NEIGHBOURS[2])
    var top_left = get_world_tile(coords - NEIGHBOURS[3])
    
    # Collect all neighbor types into an array
    var neighbor_tiles = [bot_right, bot_left, top_right, top_left]

    # Filter out TileType.NONE and get unique tile types
    var unique_tiles = []
    for tile in neighbor_tiles:
        if tile != TileType.NONE and tile not in unique_tiles:
            unique_tiles.append(tile)

    # Now unique_tiles contains the distinct tile types (1, 2, or 3)
    var type_1: TileType = TileType.NONE
    var type_2: TileType = TileType.NONE
    var type_3: TileType = TileType.NONE

    if unique_tiles.size() >= 1:
        type_1 = unique_tiles[0]
    if unique_tiles.size() >= 2:
        type_2 = unique_tiles[1]
    if unique_tiles.size() == 3:
        type_3 = unique_tiles[2]
        
    match unique_tiles.size():
        1:
            match type_1:
                TileType.GRASS:
                    return neighbours_to_atlas_coord[[true, true, true, true]] + dual_map_grass_forrest_atlas_start
                TileType.FORREST:
                    return neighbours_to_atlas_coord[[false, false, false, false]] + dual_map_grass_forrest_atlas_start
                TileType.WATER:
                    return neighbours_to_atlas_coord[[true, true, true, true]] + dual_map_grass_water_atlas_start
        2:
            var tileset_offset: Vector2i
            if (type_1 == TileType.GRASS and type_2 == TileType.FORREST) or (type_2 == TileType.GRASS and type_1 == TileType.FORREST):
                tileset_offset = dual_map_grass_forrest_atlas_start
                var tl = top_left == TileType.GRASS
                var tr = top_right == TileType.GRASS
                var bl = bot_left == TileType.GRASS
                var br = bot_right == TileType.GRASS
                return neighbours_to_atlas_coord[[tl, tr, bl, br]] + tileset_offset
            elif (type_1 == TileType.GRASS and type_2 == TileType.WATER) or (type_2 == TileType.GRASS and type_1 == TileType.WATER):
                tileset_offset = dual_map_grass_water_atlas_start
                var tl = top_left == TileType.WATER
                var tr = top_right == TileType.WATER
                var bl = bot_left == TileType.WATER
                var br = bot_right == TileType.WATER
                return neighbours_to_atlas_coord[[tl, tr, bl, br]] + tileset_offset
            elif (type_1 == TileType.FORREST and type_2 == TileType.WATER) or (type_2 == TileType.FORREST and type_1 == TileType.WATER):
                tileset_offset = dual_map_forrest_water_atlas_start
                var tl = top_left == TileType.WATER
                var tr = top_right == TileType.WATER
                var bl = bot_left == TileType.WATER
                var br = bot_right == TileType.WATER
                return neighbours_to_atlas_coord[[tl, tr, bl, br]] + tileset_offset

    # printerr("invalid tile type combo or something: type 1 ", type_1, " type 2: ", type_2)
    return Vector2i(-1,-1)

func get_world_tile(coords: Vector2i) -> TileType:
    var atlas_coord = get_cell_atlas_coords(coords)
    match atlas_coord:
        grass_placeholder_atlas_coord:
            return TileType.GRASS
        forrest_placeholder_atlas_coord:
            return TileType.FORREST
        water_placeholder_atlas_coord:
            return TileType.WATER
        _:
            return TileType.NONE
