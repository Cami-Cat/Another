@tool
class_name YesterdaySaver extends Node

static func save_data(data : Variant, path: String) -> Error:
	if not data :
		return ERR_INVALID_PARAMETER
	
	var serialized_data = AnotherSerializer.serialize_var(data)
	print(serialized_data)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if !file:
		var err = FileAccess.get_open_error()
		if err != OK:
			push_error("Could not save data to path: %s" % path)
			return err
	
	var encrypted_data = YesterdayEncryption.encrypt_data(AnotherSerializer.serialize_bytes(serialized_data))
	print(AnotherSerializer.serialize_bytes(serialized_data))
	print(encrypted_data)
	file.store_var(encrypted_data, false)
	
	if file.get_error() != OK and file.get_error() != ERR_FILE_EOF:
		return ERR_CANT_CREATE
	
	return OK
