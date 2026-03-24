@abstract class_name AnotherSerializer

static func serialize_var(_var : Variant) -> Variant:
	# Behave differently depending on the type of variable.
	match typeof(_var):
		# With an object we need to store the specific object type as a name and ensure that it is a registered (safe) type.
		TYPE_OBJECT:
			# Get the name of the object's script.
			var name : StringName = _var.get_script().get_global_name()
			# Try to find that object within the registry.
			var object_entry : ObjectSerializer._ObjectRegistryEntry = ObjectSerializer._get_entry(name, _var.get_script())
			if !object_entry:
				# If we couldn't find the object in the registry, leave it there.
				assert(false, "Could not find registered type: %s\nWas it correctly registered or is it an alien script?\n%s" % \
				[name if name else "no name", _var.get_script().source_code])
			
			# Begin serializing the object and call this function recursively to serialize nested values.
			return object_entry.serialize(_var, serialize_var)
		# With an array, we just want to use this function on all values, so we'll recursively call this function to apply that data and that will be re-stored in the array.
		TYPE_ARRAY:
			return _var.map(serialize_var)
		TYPE_DICTIONARY:
			var result := {}
			for key : Variant in _var:
				result[key] = serialize_var(_var[key])
			return result
	# If nothing else, return the variable as it already is, it's likely already in a readable state.
	return _var

static func deserialize_var(_var : Variant) -> Variant:
	match typeof(_var):
		TYPE_DICTIONARY:
			if _var.has(ObjectSerializer._type):
				var type : String = _var.get(ObjectSerializer._type)
				if type.begins_with(ObjectSerializer._object_type_prefix):
					var entry : ObjectSerializer._ObjectRegistryEntry = ObjectSerializer._get_entry(type)
					if !entry:
						assert(false, "Could not find registered type: %s\nWas it correctly registered or is it an alien script?" % \
						[type if type else "no type"])
					return entry.deserialize(_var, deserialize_var)
			
			var result : Dictionary = {}
			for key : Variant in _var:
				result[key] = deserialize_var(_var[key])
			return result
		TYPE_ARRAY:
			return _var.map(deserialize_var)
	return _var

static func serialize_bytes(_var : Variant) -> PackedByteArray:
	return var_to_bytes(serialize_var(_var))

static func deserialize_bytes(_var : PackedByteArray) -> Variant:
	return deserialize_var(bytes_to_var(_var))
