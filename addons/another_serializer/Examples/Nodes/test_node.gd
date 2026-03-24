class_name SNode extends SerializableNode

@export var player_dat : PlayerData

func _init() -> void:
	return

func _ready() -> void:
	ObjectSerializer.register_script(player_dat.resource_name, player_dat.get_script())
	YesterdaySaver.save_data(player_dat, "res://player_data.yesterday")
	player_dat = YesterdayLoader.load_data("res://player_data.yesterday", PlayerData)
	print(player_dat)
	print(player_dat.player_name)
	print(player_dat.player_title)
	return
