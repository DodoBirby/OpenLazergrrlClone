class_name Grid
extends Resource

const TILE_SIZE = 64
const HALF_SIZE = TILE_SIZE / 2

func map_to_grid(pos: Vector2i) -> Vector2i:
	return Vector2i(pos.x / TILE_SIZE, pos.y / TILE_SIZE)

func grid_to_map(pos: Vector2i) -> Vector2i:
	return Vector2i(pos.x * TILE_SIZE + HALF_SIZE, pos.y * TILE_SIZE + HALF_SIZE)
