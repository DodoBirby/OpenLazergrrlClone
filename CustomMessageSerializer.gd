extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

var path_mapping = {
	"/root/Arena/GameMaster/ServerPlayer": 1,
	"/root/Arena/GameMaster/ClientPlayer": 2,
}

var direction_mapping = {
	Vector2i.LEFT : 0,
	Vector2i.UP : 1,
	Vector2i.DOWN : 2,
	Vector2i.RIGHT : 3,
	Vector2i.ZERO : 4
}

var reverse_path_mapping = {}

var reverse_direction_mapping = {}

func _init() -> void:
	for key in path_mapping:
		reverse_path_mapping[path_mapping[key]] = key
	for key in direction_mapping:
		reverse_direction_mapping[direction_mapping[key]] = key

func serialize_input(input: Dictionary) -> PackedByteArray:
	var buffer = StreamPeerBuffer.new()
	buffer.resize(6)
	
	buffer.put_u32(input["$"])
	assert(input.size() == 2)
	for path in input:
		if path == '$':
			continue
		var path_mapped = path_mapping[path]
		buffer.put_u8(path_mapped)
		var inputs: Dictionary = input[path]
		var input_byte: int = 0
		var move_vector_mapped = direction_mapping[inputs["move_vector"]]
		var turn_vector_mapped = direction_mapping[inputs["turn_vector"]]
		var action_bit = int(inputs["action"])
		input_byte |= move_vector_mapped
		input_byte |= (turn_vector_mapped << 3)
		input_byte |= (action_bit << 6)
		buffer.put_u8(input_byte)
	return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer = StreamPeerBuffer.new()
	buffer.data_array = serialized
	var input: Dictionary = {}
	input["$"] = buffer.get_u32()
	var path = reverse_path_mapping[buffer.get_u8()]
	var input_byte = buffer.get_u8()
	var move_vector_mask = 0x7
	var turn_vector_mask = 0x7 << 3
	var action_bit_mask = 0x1 << 6
	var move_vector_mapped = input_byte & move_vector_mask
	var move_vector = reverse_direction_mapping[move_vector_mapped]
	var turn_vector_mapped = (input_byte & turn_vector_mask) >> 3
	var turn_vector = reverse_direction_mapping[turn_vector_mapped]
	var action_bit = (input_byte & action_bit_mask) != 0
	input[path] = { "move_vector": move_vector, "turn_vector": turn_vector, "action": action_bit }
	return input
