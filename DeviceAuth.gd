extends Control

const TRAKT_DEVICE_CODE_URL = Global.TRAKT_API_URL + "/oauth/device/code"
const TRAKT_DEVICE_POLL_URL = Global.TRAKT_API_URL + "/oauth/device/token"

onready var label = get_node("MarginContainer/VBoxContainer/Label")
onready var spinner = get_node("MarginContainer/VBoxContainer/SpinnerCenter")
onready var link = get_node("MarginContainer/VBoxContainer/LinkCenter/Link")

# populated in Main.gd
var main

# populated in this script
var device_code
var user_code
var verification_url
var expires_in
var interval
var polling


func reset():
	polling = false
	$PollTimer.stop()
	$ExpiryTimer.stop()
	link.hide()
	spinner.hide()
	label.text = ""


func home():
	reset()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	get_tree().root.remove_child(self)
	self.queue_free()
	main.initialize()


# Called when the node enters the scene tree for the first time.
func _ready():
	assert(main != null)
	var max_x = 0
	var max_y = 0
	for child in get_children():
		if child is Control:
			max_x = max(max_x, child.rect_size.x + child.margin_left)
			max_y = max(max_y, child.rect_size.y + child.margin_top)
	OS.window_borderless = false
	OS.window_size = Vector2(max_x + $MarginContainer.margin_left,
							 max_y + $MarginContainer.margin_top)
	OS.window_resizable = false
	OS.center_window()
	reset()


func _on_auth_pressed():
	reset()
	var data = {"client_id": Global.DEVICE_CLIENT_ID}
	var headers = ["Content-Type: application/json"]
	var status = $APIAccess.request(TRAKT_DEVICE_CODE_URL, headers, true,
									HTTPClient.METHOD_POST, to_json(data))
	if status == OK:
		spinner.show()
	else:
		push_error("An error occurred in the HTTP request: {0}".format([status]))


func _on_api_access_request_completed(result, response_code, _headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		if polling:
			if response_code == 400:
				# no access yet
				pass
			elif response_code == 200:
				var response = parse_json(body.get_string_from_utf8())
				var main_auth = main.get("auth")
				main_auth.access_token = response["access_token"]
				main_auth.token_type = response["token_type"]
				main_auth.expires_in = response["expires_in"]
				main_auth.refresh_token = response["refresh_token"]
				main_auth.scope = response["scope"]
				main_auth.created_at = response["created_at"]
				main.save_data()
				home()
			else:
				push_error(
					"Error in api access poll response with code: {0}".format([response_code]))
		else:
			if response_code == 200:
				var response = parse_json(body.get_string_from_utf8())
				device_code = response["device_code"]
				user_code = response["user_code"]
				verification_url = response["verification_url"]
				expires_in = response["expires_in"]
				interval = response["interval"]
				self._device_poll_start(interval)
			else:
				push_error(
					"Error in api access token response with code: {0}".format([response_code]))
	else:
		push_error("Error in api access response with http result: {0}".format([result]))


func _device_poll_start(intervalIn):
	polling = true
	$PollTimer.wait_time = intervalIn
	$PollTimer.one_shot = false
	$PollTimer.start()
	$ExpiryTimer.wait_time = expires_in
	$ExpiryTimer.one_shot = true
	$ExpiryTimer.start()
	link.text = verification_url
	link.show()
	label.text = user_code


func _on_link_pressed():
	if verification_url:
		var status = OS.shell_open(verification_url)
		if status != OK:
			push_error("Error when opening verification url: {0}".format([status]))


func _on_poll_timer_timeout():
	var data = {
		"code": device_code,
		"client_id": Global.DEVICE_CLIENT_ID,
		"client_secret": Global.DEVICE_CLIENT_SECRET,
	}
	var headers = ["Content-Type: application/json"]
	var status = $APIAccess.request(TRAKT_DEVICE_POLL_URL, headers, true,
									HTTPClient.METHOD_POST, to_json(data))
	if status != OK:
		push_error("An error occurred in the HTTP request: {0}".format([status]))


func _on_expiry_timer_timeout():
	reset()
	label.text = "Authentication timed out.\nPress the button again."
	label.show()
