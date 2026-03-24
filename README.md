# Another Serializer
A Serializer and file management system made for Godot, built upon Cretezy's Godot-Object-Serializer to add file-saving, encrypting, decrypting and loading functionality.

# Attribution

Cretezy's work: [Godot Object Serializer](https://github.com/Cretezy/godot-object-serializer?tab=readme-ov-file, "Godot Object Serializer") (I wouldn't have a clue how to do this without this project. It's all thanks to this guy!)

This does **NOT** support Cretezy's JSON-Related functions. This was initially made to aid in a personal project so I cut out code that wasn't personally necessary. It shouldn't be too hard to import the JSON code from his project - though you may need to change some variable names.

---

# Description

Save safely anywhere, with encryption. Using a mix of Cretezy's serialization system and Godot's `FileAccess.store_var()`, easily access this saved data from anywhere. Built upon the idea of Godot's ResourceFormatSaver, adjusted to not require resources.
Why don't you just save a variable as is using `FileAccess.store_var()`? Cretezy went into this, but it's something even the Godot Documentation covers:

- The remote execution of malicious code: `Stores any Variant value in the file. If full_objects is true, encoding objects is allowed (and can potentially include code)`

We don't want that. Any security vulnerability that we can control, we should! So lets limit our attack vector here and store objects as plain dictionaries!

Not to worry, though. I went through the work of understanding the pure wizardry of Cretezy's work so you don't have to! I'll explain it as best as I can. If I'm wrong, please raise it in the issues tab!

---

# Example

But before the explanation, lets give a quick example. You can find the code here: [Example Folder](https://github.com/Cami-Cat/Another/tree/main/addons/another_serializer/Examples/Nodes)

You'll find in that link above an object called `test_node.gd`; You'll find that it also inherits from an object called `SerializableNode`. This has an example of "necessary" functions for if you want to serialize the node itself. In this case, we just want to serialize PlayerData. Below, you'll find out why.

# Explanation and Documentation

To register data that we want to serialize, we can call our ObjectSerializer abstract class:

```gdscript

@export var player_dat : PlayerData

func _ready() -> void:
  ObjectSerializer.register_script(player_dat.resource_name, player_dat.get_script())
```

This function has a signature that looks like this:

```gdscript

func register_script(script_name : StringName, script : Script) -> void:
```

You *can* pass in the `script_name` as an empty `String` or `StringName`, like so:

```gdscript
func _ready() -> void:
  ObjectSerializer.register_script(&"", player_dat.get_script())
```

And ObjectSerializer will try to get a name through either the scripts `resource_name` parameter or its `get_global_name()` class name. 

There's a reason we register a type of Resource, Node or Script here. This is so we have full control over the scripts that we save and load. If you try to load from a script that isn't registered, `AnotherSerializer` isn't going to be able to deserialize it, because it cannot trust it. Therefore, it's imperative that in either `_ready()`, `_init()` or `_static_init()` that you register the script that you want to save.

Once we've registered our object, we can begin saving it. Adding onto our code before to save it, it would look like this:

```gdscript

@export var player_dat : PlayerData

func _ready() -> void:
  ObjectSerializer.register_script(player_dat.resource_name, player_dat.get_script())
  YesterdaySaver.save_data(player_dat, "res://player_data.yesterday")
```

You'll notice that we're specifying the file extension, this is `.yesterday`. You can change this as you wish, and I plan to make it a constant function with a boolean to toggle whether you use the global file extension or not, so you can save multiple.

Otherwise, you'll see that it's incredibly simple to now save this data, and if you were to run this as it is, it should save a new file in your Godot project (you cannot see this in Godot, you'll see it in your file manager). This should be encrypted and you shouldn't be able to tell what at all is stored in there. Here's an example of how it goes through the system and the outputs from each step:

## Code:

```gdscript

class_name YesterdaySaver extends Node

static func save_data(data : Variant, path : String) -> Error:
  if not data:
    return ERR_INVALID_PARAMETER

  var serialized_data = AnotherSerializer.serialize_var(data)
  print(serialized_data)
```

## Output

```
{ "._type": "Object_PlayerData", "player_name": "Player Name", "player_title": "The Stupid" }
```

## What Happens?

When you call `serialize_var()` on a variable, it takes into account a few things:

- What the variable type is
- If it's an Object, is it registered?

We use a match inside `AnotherSerializer.serialize_var()` because we only have three `Variant.Type`s that we need to check:

- `TYPE_OBJECT`
- `TYPE_DICTIONARY`
- `TYPE_ARRAY`

If the variable is a dictionary, it will iterate over each value and store the name of it and it's now serialized value as `Key` and `Value`
If the variable is an array, it will use Map to create a new array with each member of the array serialized into a dictionary.

If the variable, which we'll just call "var" in this case, is an object, it has to first be validated as a registered object. If it is not found, then we just completely ignore it.
If it is however fine, we call serialize on the `Object Entry` with the variable being saved. What's an `Object Entry?`.

`Object Entry` or in our case, the actual class name: `_ObjectRegistryEntry` is a class that stores type, script and variables that we ask it to save. This is ONLY called for non-primitive types like Vector2.

### _ObjectRegistryEntry

It first checks whether the object has it's own custom serialize function. If so, it calls that and returns the value. Here's why Cretezy does that: (Shamelessly using their example)

```gdscript
class Data:
	# No need to call `serialize`/`deserialize` for primitive
	var name: String
	# Must call `serialize`/`deserialize` for non-primitive
	var position: Vector2

	func _serialize(serialize: Callable) -> Dictionary:
		return {
			"key": name,
			"pos": serialize.call(position)
		}
```

In his example of a custom object serializer, you can see him use `serialize.call(position)`. You'll also notice that we pass through a callable as a function argument, this allows the system to work in a nested, recursive way without infinite recursion and for-loops.

He calls `serialize` on `position` because you cannot - by default, serialize a Vector2. Usually because of JSON requirements. So instead, we store it as a custom type like so:

```gdscript
{
	"._type": "Object_Data",
	"key": "hello world",
	"pos": {
		"._type": "Vector2",
		"._": [1.0, 2.0]
	}
}
```

This isn't too dissimilar to how we store Objects using this method! You'll see `"._type"` above, this is the key that defines what type an object is, this is how we can reconstruct objects using our deserializer. If; however, it is a primitive type, it can just be stored as-is. Such as in the example above with `"key"` not being prefixed with another dictionary and another `"._type"`.

moving on from this example, we're still not finished exploring `_ObjectRegistryEntry`

If the object is recognised to not have it's own built-in `_serialize` function, we can begin storing it in the default manner.

Firstly; We define the object's type. This is stored in _ObjectRegistry as `_type` and refers typically to the name passed in as an argument when registering a script.
Secondly; We need to store which arguments are excluded from serialization. Not everything has to be saved. This is implemented once again using a function that the object does not need to have: `_get_excluded_properties() -> Array[String]:`
Thirdly; We then store what files need to be partially serialized. These are objects like BitMaps or Textures. Non-Value types. (As Cretezy puts it.)

Now we've done all of the setup to store the data. We can finally begin storing the data:

```gdscript
	for property : Dictionary in _var.get_property_list():
		if ( 
			property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE
			and !excluded_properties.has(property.name)
			and !partial.has(property.name) 
		):
			result[property.name] = next.call(_var.get(property.name))
```

We first check for validity; 
- is the value able to be stored?
- is the value in the exclude list?
- is the value partial?

If none of the above are true, we store the property name in our dictionary and then serialize the variable using `next.call` This happens recursively until every object, primitive types, non-primitive types and non-value types are correctly stored in the dictionary and produce the output seen above.

## Code

```gdscript

class_name YesterdaySaver extends Node

static func save_data(data : Variant, path : String) -> Error:
	if not data:
		return ERR_INVALID_PARAMETER
	
		var serialized_data = AnotherSerializer.serialize_var(data)
		var file = FileAccess.open(path, FileAccess.WRITE)
		if !file:
			var err = FileAccess.get_open_error()
			if error != OK:
				push_error("Could not save data to path: %s" % path)
				return err

		var encrypted_data = YesterdayEncryption.encrypt_data(AnotherSerializer.serialize_bytes(serialized_data))
```

## Output

Before Encryption:

```
[27, 0, 0, 0, 3, 0, 0, 0, 4, 0, 0, 0, 6, 0, 0, 0, 46, 95, 116, 121, 112, 101, 0, 0, 4, 0, 0, 0, 17, 0, 0, 0, 79, 98, 106, 101, 99, 116, 95, 80, 108, 97, 121, 101, 114, 68, 97, 116, 97, 0, 0, 0, 4, 0, 0, 0, 11, 0, 0, 0, 112, 108, 97, 121, 101, 114, 95, 110, 97, 109, 101, 0, 4, 0, 0, 0, 11, 0, 0, 0, 80, 108, 97, 121, 101, 114, 32, 78, 97, 109, 101, 0, 4, 0, 0, 0, 12, 0, 0, 0, 112, 108, 97, 121, 101, 114, 95, 116, 105, 116, 108, 101, 4, 0, 0, 0, 10, 0, 0, 0, 84, 104, 101, 32, 83, 116, 117, 112, 105, 100, 0, 0]

```

After Encryption:

```
[15, 6, 208, 51, 114, 223, 112, 99, 75, 112, 214, 20, 25, 125, 100, 107, 119, 39, 201, 67, 6, 62, 95, 230, 4, 87, 252, 210, 240, 92, 144, 243, 43, 120, 231, 6, 253, 224, 206, 199, 76, 15, 109, 164, 214, 227, 92, 108, 141, 191, 179, 241, 186, 173, 216, 57, 80, 100, 143, 45, 145, 190, 40, 203, 106, 126, 157, 239, 246, 227, 47, 71, 78, 74, 244, 248, 84, 173, 14, 233, 53, 150, 179, 26, 139, 11, 185, 130, 202, 174, 246, 37, 235, 155, 177, 123, 139, 214, 142, 54, 247, 9, 187, 133, 79, 95, 164, 228, 104, 123, 216, 134, 101, 168, 112, 198, 128, 146, 213, 253, 137, 190, 174, 179, 142, 232, 235, 12, 25, 127, 21, 65, 250, 115, 159, 44, 29, 84, 32, 21, 189, 77, 28, 181, 4, 199, 150, 225, 82, 6, 228, 76, 209, 233, 3, 26, 111, 247, 177, 30, 79, 191, 220, 115, 218, 197, 205, 131, 112, 29, 226, 246, 128, 16, 134, 32, 205, 22, 77, 49, 112, 36, 104, 242, 32, 44, 103, 184, 133, 248, 153, 130, 61, 137, 12, 42, 117, 146, 190, 106, 185, 31, 178, 134, 46, 29, 137, 141, 112, 108, 64, 249, 165, 22, 131, 53, 108, 69, 229, 253, 167, 87, 51, 141, 155, 88, 45, 234, 60, 245, 115, 228, 120, 164, 147, 203, 160, 126, 183, 122, 165, 45, 158, 168, 88, 153, 158, 144, 209, 205, 128, 96, 79, 128, 145, 35, 78, 233, 118, 89, 4, 182, 48, 171, 108, 21, 40, 25, 7, 95, 53, 43, 216, 93, 187, 15, 4, 69, 158, 104, 80, 104, 245, 231, 99, 91, 116, 225, 82, 31, 51, 204, 199, 40, 179, 44, 75, 27, 164, 199, 167, 88, 173, 27, 76, 169, 108, 47, 105, 148, 182, 196, 107, 113, 1, 166, 127, 227, 85, 219, 208, 100, 60, 86, 89, 183, 149, 127, 58, 59, 149, 16, 102, 51, 128, 99, 12, 34, 65, 3, 225, 152, 223, 56, 133, 19, 238, 33, 115, 181, 134, 134, 65, 61, 218, 6, 101, 101, 125, 22, 20, 191, 82, 178, 57, 2, 132, 37, 165, 171, 168, 247, 38, 104, 248, 23, 99, 71, 39, 5, 153, 255, 17, 12, 68, 135, 28, 42, 169, 255, 199, 116, 170, 170, 114, 41, 233, 150, 91, 7, 214, 119, 104, 126, 23, 101, 189, 118, 58, 25, 133, 167, 208, 188, 171, 138, 248, 155, 130, 15, 207, 146, 178, 134, 130, 92, 238, 80, 79, 57, 244, 243, 25, 189, 62, 143, 161, 112, 197, 81, 247, 58, 176, 110, 110, 19, 150, 224, 218, 219, 220, 229, 133, 79, 90, 24, 7, 200, 27, 76, 177, 18, 152, 239, 140, 226, 226, 162, 20, 223, 76, 233, 87, 227, 127, 33, 146, 2, 108, 96, 98, 191, 196, 160, 227, 79, 131, 149, 49, 173, 238, 253, 171, 87, 33, 23, 229, 130, 228, 252, 96, 7, 135, 48, 12, 215, 1, 140, 45, 109, 232, 114]
```

`serialize_bytes` is a lot easier to understand now that you understand `serialize_var`, because it just calls `serialize_var` inside `var_to_bytes`:

```gdscript
static func serialize_bytes(_var : Variant) -> PackedByteArray:
	return var_to_bytes(serialize_var(_var))
```

Encrypting is also fairly easy to understand. You'll find this inside the abstract class: `YesterdayEncryption`

This class has one main variable: _crypto. This uses Godot's built-in `Crypto` class to handle all of the encryption and decryption. We just store it inside an abstract class to have something that always exists.

When encrypting data we:
- Validate that the Encryption Key exists. If it doesn't, it will generate a new one. You will USUALLY see an error when running this for the first time, as it tries to load a key that does not exist. If it fails, though, it makes one for you and you shouldn't encounter this error ever again. You can store this inside ://res to export it with the rest of the project or you can store it inside ://user (I suggest) so that each user has a different encryption key.
- It then encrypts using `Crypto.encrypt`.

Here's the function:

```gdscript
static func encrypt_data(data_in : Variant) -> Variant:
	var key : CryptoKey = _validate_key()
	if !key : return
	return _crypto.encrypt(key, data_in)
```

Luckily, decryption is much the same.

## Deserialization

But what about Deserialization? Objects were turned into `Dictionaries`, then a `PackedByteArray`, then an even longer encrypted `PackedByteArray`

YesterdayLoader does much of the same, just in the opposite direction:

```gdscript
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
```

Firstly, we get the variable stored in the file. The reason we pass false as a parameter is because we don't want objects to be loaded. It's just a dictionary, and it should be fine to stay as one.
This is, because we are still encrypted, a PackedByteArray, so we firstly have to decrypt it:

```dscript
	var decrypted_data  : PackedByteArray = YesterdayEncryption.decrypt_data(serialized_data)
```

Now, we have decrypted, serialized data. This is still in a PackedByteArray so we need to turn this back into a variable, and that's where `deserialize_bytes` comes in.

Like `serialize_bytes`, this just calls `deserialize_var` but it returns `(deserialize_var(bytes_to_var(_var))`

Deserializing is almost an easier task, as we're only checking for two types now:

- TYPE_DICTIONARY
and
- TYPE ARRAY

TYPE_ARRAY is nice and easy, just returning _var.map(deserialize_var)
These are no longer bytes, remember, they're returned from Bytes to Variables, so we're clean to just return _var if it does not match any of the types above.

When we deserialize a dictionary, however, we need to check for two things now:
Does the dictionary have a key that reads: `._type`? And if so, is it a registered object?

If it's not a registered object, we cannot do anything with it.
If it doesn't contain `._type`, we iterate over the dictionary with a new dictionary, `result`. We set the [key] of `result` to the returned `deserialized_var(_var[key])` of each value.

If it is an object, however, `_ObjectRegistryEntry` is once again called to duty, with that same recursive method of passing a callable through.

Deserialization is much like serialization.

If the object has it's own `_deserialize` method, we call that and return the result.
We then need to make an instance of the object. So, we create a new Variant called instance.

```gdscript
	var instance : Variant
```

We know it's an object and we know that it's registered so we don't have to perform any checks in this function for those, but we do need to check whether we stored constructor arguments correctly.

```gdscript		
if _var.has(ObjectSerializer._args):
	# If the object had arguments on construct, we call it with those same arguments.
	instance = _script.new.callv(_var[ObjectSerializer._args])
```

This will create a new instance of the scriptable object with the array of arguments passed in. This should construct the object as it was constructed before, or as you stored new construction arguments (position, name, etc).

If; however, you didn't store any arguments it, we just make a new script without any construction arguments:

```gdscript
else:
	instance = _script.new()

```

We then once again check for the excluded properties. This should be stored on the object since it's a function, so we can just call that again and those functions wont be overwritten.
The same for partial variables, where a custom implementation of `_deserialize_partial` will need to be completed for cases like BitMaps and Textures.

Once we've gotten through those steps above, we can iterate over the properties that we need to load into this new object:

```gdscript
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
```

We skip over any keys that specify the type of the object and whether it is an argument, we then need to make sure it's not excluded or partial and we can finally create the value.

To create the value, we need to get the key and call `deserialize_var` on that again, passed through using the `next` callable. We then match the type of that value and assign it to a specific key as it should be. We repeat this recursively, ensuring all nested objects are stored properly, and we can finally return the instance.

To get the player_dat instance back on the player, from when it was saved, we just need to call:

```gdscript
	player_dat = YesterdayLoader.load_data("res://player_data.yesterday", PlayerData)
```

PlayerData is only necessary so long as it's an object that we can instantiate, it is not otherwise checked or used. And we first put in the path, this is usually the same as the path that we used to save it, unless we wanted to load different data from elsewhere.

Otherwise, this loaded data will overwrite the player_dat resource (ref_counted, so the other resource will free itself when it is no longer referenced) and you can read the data as you would before:

```gdscript
	print(player_dat)
	print(player_dat.player_name)
	print(player_dat.player_title)
```

## Conclusion

That should just about cover how to use the plugin, what it does and why we do it in that specific way. For most use-cases, the first three functions in this list should be all they need to ever call:

```gdscript
func _ready() -> void:
	ObjectSerializer.register_script(player_dat.resource_name, player_dat.get_script())
	YesterdaySaver.save_data(player_dat, "res://player_data.yesterday")
	player_dat = YesterdayLoader.load_data("res://player_data.yesterday", PlayerData)
```

but for anyone else that wants to customize the tool, it's great to have a level of customizability, so understanding these essentials is a must.

Please, give all of the credit to Cretezy. All I did was add some simple stuff on-top to make it instantly usable in any system. Hopefully this readme explained things a little better than the documentation, as there were some functions that I couldn't quite understand when reading them myself for the first time. So going through, typing it out and understanding why we did this made it much easier to change and add to it. Not that I changed much!

Like [Godot Object Serializer](https://github.com/Cretezy/godot-object-serializer?tab=readme-ov-file, "Godot Object Serializer") this uses an [MIT license](https://github.com/Cami-Cat/Another/blob/main/LICENSE). But please credit Cretezy before me if you do.
