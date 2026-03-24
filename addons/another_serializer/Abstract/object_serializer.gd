@abstract class_name ObjectSerializer

static var _type : String = "._type"
static var _args : String = "._"
static var _object_type_prefix : String = "Object_"

static var _object_registry : Dictionary[String, _ObjectRegistryEntry] = {}

static func register_script(name : StringName, script : Script) -> void:
	var script_name := _get_script_name(script, name)
	assert(script_name, "Script must have a name\n" + script.source_code)
	var entry : _ObjectRegistryEntry = _ObjectRegistryEntry.new()
	entry._script = script
	entry._type = _object_type_prefix + script_name
	_object_registry[entry._type] = entry
	return

static func register_scripts(scripts : Dictionary[String, Script]) -> void:
	for name in scripts:
		register_script(name, scripts[name])
	return

static func _get_script_name(script : Script = null, name : StringName = "") -> StringName:
	if name : return name
	if script.resource_name : return script.resource_name
	if script.get_global_name() : return script.get_global_name()
	return ""

static func _get_entry(name : StringName = "", script : Script = null) -> _ObjectRegistryEntry:
	if name:
		var entry : _ObjectRegistryEntry = _object_registry.get(name)
		if entry : return entry
	if script:
		for key : String in _object_registry:
			var entry : _ObjectRegistryEntry = _object_registry.get(key)
			if entry && script == entry._script : 
				return entry
	return null

class _ObjectRegistryEntry:
	var _type 	: String
	var _script : Script
	
	func serialize(_var : Variant, next : Callable) -> Variant:
		# If the object has it's own method of serialization, call that instead.
		if _var.has_method("_serialize"):
			# We push the "next" value as a callable for nested data. Required for non-primitive types.
			var result : Dictionary = _var._serialize(next)
			# We then ensure that the type of the object is stored with the key in [member type] and with the value stored in the registry entry.
			result[ObjectSerializer._type] = _type
			return result
		
		# We ensure that the type of the objecft is stored first, as the header key.
		var result := {ObjectSerializer._type : _type}
		
		# Do NOT save these properties. These are transient values that have no need to be saved.
		var excluded_properties : Array[String] = []
		if _var.has_method("_get_excluded_properties"):
			# We'll store properties to skip over here.
			excluded_properties = _var._get_excluded_properties()
		
		# For data that only needs to be partially serialized - for example, Bitmaps or Texture2D. In our case we won't really be using it, but as a future use-case scenario this
		# may prove useful.
		var partial : Dictionary = {}
		if _var.has_method("_serialize_partial"):
			partial = _var._serialize_partial(next)

		# Now we iterate over the property list.
		for property : Dictionary in _var.get_property_list():
			# Ensure that the property is able to be saved.
			if ( 
				property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE
				and !excluded_properties.has(property.name)
				and !partial.has(property.name) 
			):
				# Then store the name of the property and serialize the value
				result[property.name] = next.call(_var.get(property.name))
		
		# For all of our partial variables, we store them as a result as-well.
		for key in partial:
			result[key] = partial[key]

		# We need to store constructor arguments just in-case this is an object that is instantiated through arguments like such. Possibly to store names and other such values.
		if _var.has_method("_get_constructor_args"):
			var args : Array = _var._get_constructor_args()
			result[ObjectSerializer._args] = args

		return result
	
	func deserialize(_var : Variant, next : Callable) -> Variant:
		# If the object has it's own method of deserialization, call that instead.
		if _script.has_method("_deserialize"):
			return _script._deserialize(_var, next)
		
		# We now instantiate the object.
		var instance : Variant
		if _var.has(ObjectSerializer._args):
			# If the object had arguments on construct, we call it with those same arguments
			instance = _script.new.callv(_var[ObjectSerializer._args])
		else:
			# Otherwise, we just create a new one as-is
			instance = _script.new()
		
		# We get the excluded properties as we did with saving them, these ones will be ignored when reconstructing.
		var excluded_properties : Array[String] = []
		if instance.has_method("_get_excluded_properties"):
			excluded_properties = instance._get_excluded_properties()
		
		# Same with partial.
		var partial : Dictionary = {}
		if instance.has_method("_deserialize_partial"):
			partial = instance._deserialize_partial(_var, next)
		
		# Now we'll set the values that were stored in the serialized dictionary.
		for key : String in _var:
			# Properties that we don't currently want to set:
			if (
				key == ObjectSerializer._type
				or key == ObjectSerializer._args
				or excluded_properties.has(key)
				or partial.has(key)
			): continue
		
			# We'll get the value of the key by calling for that to be deserialized.
			var key_value : Variant = next.call(_var[key])
			# Then we'll assign the value as we would to any other object / type.
			match typeof(key_value):
				TYPE_DICTIONARY:
					instance[key].assign(key_value)
				TYPE_ARRAY:
					instance[key].assign(key_value)
				_:
					instance[key] = key_value
		
		# Then we set the partial keys.
		for key in partial:
			instance[key] = partial[key]
	
		# And return a deserialized object.
		return instance
