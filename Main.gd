extends Control

const CONFIG_URI = "user://config.json"
const HISTORY_DATA_URI = "user://history.ndjson"
const TRAKT_API_SYNC_HISTORY = Auto.TRAKT_API_URL + "/sync/history"

# config variables
var auth
var default_screen
var last_sync

# history data
var history

# script local variables
var history_synced


func _ready():
	self.load_data()
	if auth:
		sync_history()
	self.hide()
	self.initialize()


func sync_history():
	var params = ""
	if last_sync:
		params = "?start_at=" + last_sync.percent_encode()
	last_sync = iso_timestamp()
	var headers = [
		"Accept: application/json",
		"Authorization: Bearer " + auth.access_token,
		"trakt-api-version: " + str(Auto.TRAKT_API_VERSION),
		"trakt-api-key: " + Auto.DEVICE_CLIENT_ID,
	]
	$SyncHistoryAccess.request(TRAKT_API_SYNC_HISTORY + params, headers, true,
							   HTTPClient.METHOD_GET)
	history_synced = true


func _on_sync_history_request_completed(result, response_code, headers, body):
	pass


func iso_timestamp():
	var now = OS.get_datetime(true)
	now.year = str(now.year).pad_zeros(4)
	now.month = str(now.month).pad_zeros(2)
	now.day = str(now.day).pad_zeros(2)
	now.hour = str(now.hour).pad_zeros(2)
	now.minute = str(now.minute).pad_zeros(2)
	now.second = str(now.second).pad_zeros(2).pad_decimals(3)
	return "{year}-{month}-{day}T{hour}:{minute}:{second}Z".format(now)


func initialize():
	if not "access_token" in auth:
		var auth_control = load("res://DeviceAuth.tscn").instance()
		auth_control.set("main", self)
		call_deferred("switch_scene", auth_control)
	else:
		if not history_synced:
			sync_history()

		# switch to default screen
		var home_screen = load(default_screen).instance()
		home_screen.set("main", self)
		call_deferred("switch_scene", home_screen)


func switch_scene(node):
	get_tree().root.add_child(node)
	get_tree().current_scene = node
	get_tree().root.remove_child(self)


func load_data():
	# initialize variables
	auth = {}
	default_screen = "res://Progress.tscn"
	last_sync = null
	history = []

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
		last_sync = data.get("last_sync", last_sync)

	if data_file.file_exists(HISTORY_DATA_URI):
		data_file.open(HISTORY_DATA_URI, File.READ)
		while not data_file.eof_reached():
			var line = data_file.get_line()
			if line:
				history.append(parse_json(line))
		data_file.close()


func save_data():
	var data_file = File.new()
	var data = {
		"auth": auth,
		"default_screen": default_screen,
		"last_sync": last_sync,
	}
	data_file.open(CONFIG_URI, File.WRITE)
	if OS.get_name() == "X11":
		OS.execute("chmod", ["-R", "go-rwx", OS.get_user_data_dir()])
	data_file.store_line(to_json(data))
	data_file.close()

	data_file.open(HISTORY_DATA_URI, File.WRITE)
	for obj in history:
		data_file.store_line(to_json(obj))
	data_file.close()
