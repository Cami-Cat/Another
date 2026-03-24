@tool
class_name YesterdaySaver extends Node

static func save_data(resource: Resource, path: String) -> Error:
	if not resource :
		return ERR_INVALID_PARAMETER
	
	var serialized_data = AnotherSerializer.serialize_var(resource)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if !file:
		var err = FileAccess.get_open_error()
		if err != OK:
			push_error("Could not save data to path: %s" % path)
			return err
	
	var encrypted_data = YesterdayEncryption.encrypt_data(AnotherSerializer.serialize_bytes(serialized_data))
	file.store_var(encrypted_data, false)
	
	if file.get_error() != OK and file.get_error() != ERR_FILE_EOF:
		return ERR_CANT_CREATE
	
	return OK
