@abstract class_name YesterdayEncryption extends Node

static var _crypto : Crypto = Crypto.new()

func _ready() -> void:
	_validate_key()
	return

static func _validate_key() -> CryptoKey:
	var key : CryptoKey = CryptoKey.new()
	if key.load("res://cryptokey.key", false) != OK:
		key = _crypto.generate_rsa(4096)
		key.save("res://cryptokey.key")
	if !key:
		return null
	return key

static func encrypt_data(data_in : Variant) -> Variant:
	var key : CryptoKey = _validate_key()
	if !key : return
	return _crypto.encrypt(key, data_in)

static func decrypt_data(data_in : Variant) -> Variant:
	var key : CryptoKey = _validate_key()
	if !key : return
	return _crypto.decrypt(key, data_in)
