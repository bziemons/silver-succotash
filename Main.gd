extends Control

const CONFIG_URI := "user://config.json"

# config variables
var auth: Dictionary
var default_screen: String
var last_history_sync


func load_history_sync():
	var history_sync := load("res://srv/HistorySync.tscn").instance() as Control
	history_sync.name = "HistorySync"
	Global.add_child(history_sync)
	Global.set("history_sync", history_sync)
	history_sync.set("main", self)
	history_sync.load_data()


func _ready():
	self.load_data()
	if not Global.get("history_sync"):
		load_history_sync()
	if auth:
		Global.history_sync.sync_history()
	self.hide()
	self.initialize()


func initialize():
	if not "access_token" in auth:
		var auth_control = load("res://DeviceAuth.tscn").instance()
		auth_control.set("main", self)
		call_deferred("switch_scene", auth_control)
	else:
		if Global.history_sync.history_state == 0:
			Global.history_sync.sync_history()

		# switch to default screen
		var home_screen = load(default_screen).instance()
		home_screen.set("main", self)
		call_deferred("switch_scene", home_screen)


func report_authentication_failure(tree: SceneTree):
	auth = {}
	save_data()
	if tree.current_scene == self:
		initialize()
	else:
		tree.current_scene.home()


func switch_scene(node):
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	get_tree().root.remove_child(self)


func load_data():
	# initialize variables
	auth = {}
	default_screen = "res://Progress.tscn"
	last_history_sync = null

	var data_file = File.new()
	if data_file.file_exists(CONFIG_URI):
		data_file.open(CONFIG_URI, File.READ)
		var line = data_file.get_line()
		var data = {}
		if line:
			data = parse_json(line)
		data_file.close()

		auth = data.get("auth", auth)
		default_screen = data.get("default_screen", default_screen)
		last_history_sync = data.get("last_history_sync", last_history_sync)


func save_data():
	var data_file = File.new()
	var data = {
		"auth": auth,
		"default_screen": default_screen,
		"last_history_sync": last_history_sync,
	}
	data_file.open(CONFIG_URI, File.WRITE)
	if OS.get_name() == "X11":
		OS.execute("chmod", ["-R", "go-rwx", OS.get_user_data_dir()])
	data_file.store_line(to_json(data))
	data_file.close()
