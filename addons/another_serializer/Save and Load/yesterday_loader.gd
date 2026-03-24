@tool
class_name YesterdayLoader extends Node

static func load_data(path : String, data_type : Script) -> Variant:
	if !data_type.can_instantiate():
		assert(false, "Cannot instantiate type: %s\n%s" % [data_type.get_global_name(), data_type.source_code])
	
	var file = FileAccess.open(path, FileAccess.READ)
	if !file:
		var err = FileAccess.get_open_error()
		if err != OK:
			return null

	var serialized_data : PackedByteArray = file.get_var(false)
	var decrypted_data  : PackedByteArray = YesterdayEncryption.decrypt_data(serialized_data)
	var data = AnotherSerializer.deserialize_bytes(decrypted_data)
	return data
