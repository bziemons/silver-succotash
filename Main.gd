extends Control

const DATA_URI = "user://traktui.data"

var auth

onready var label = get_node("Label")


func _ready():
	self.load_data()
	self.hide()
	self.initialize()


func initialize():
	if not "access_token" in auth:
		var auth_scene = load("res://DeviceAuth.tscn")
		var auth_control = auth_scene.instance()
		auth_control.set("main", self)
		call_deferred("switch_scene", auth_control)
	else:
		self.show()
		label.text = str(auth)
		label.show()


func switch_scene(node):
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	get_tree().root.remove_child(self)


func load_data():
	auth = {}
	var data_file = File.new()
	if not data_file.file_exists(DATA_URI):
		return
	data_file.open(DATA_URI, File.READ)
	var data = parse_json(data_file.get_line())
	data_file.close()
	auth = data.auth


func save_data():
	var data_file = File.new()
	var data = {
		"auth": auth,
	}
	data_file.open(DATA_URI, File.WRITE)
	if OS.get_name() == "X11":
		OS.execute("chmod", ["-R", "go-rwx", OS.get_user_data_dir()])
	data_file.store_line(to_json(data))
	data_file.close()
