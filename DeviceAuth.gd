extends Node2D

const TRAKT_DEVICE_CODE_URL = "https://private-anon-edc3e21df5-trakt.apiary-mock.com/oauth/device/code"
const DEVICE_CLIENT_ID = "ca99b720a40e4a57f2f7178165c35737aef40632ccd84ce20a0f4be360362c87"

onready var api_access = get_node("APIAccess")
onready var poll_timer = get_node("PollTimer")
onready var expiry_timer = get_node("ExpiryTimer")
onready var label = get_node("VBoxContainer/HBoxContainer/Label")
onready var link = get_node("VBoxContainer/Link")

var device_code
var user_code
var verification_url
var expires_in
var interval

# Called when the node enters the scene tree for the first time.
func _ready():
	link.hide()
	label.text = ""


func _on_auth_pressed():
	var data = {"client_id": DEVICE_CLIENT_ID}
	var error = api_access.request(TRAKT_DEVICE_CODE_URL, [], true,
		HTTPClient.METHOD_POST, to_json(data))
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _on_api_access_request_completed(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		if response_code == 200:
			var response = parse_json(body.get_string_from_utf8())
			device_code = response["device_code"]
			user_code = response["user_code"]
			verification_url = response["verification_url"]
			expires_in = response["expires_in"]
			interval = response["interval"]
			self._device_poll_start(interval)
		else:
			printerr("Error in api access response with code:", response_code)
	else:
		printerr("Error in api access response with result:", result)


func _device_poll_start(intervalIn):
	poll_timer.wait_time = intervalIn
	poll_timer.one_shot = false
	poll_timer.start()
	expiry_timer.wait_time = expires_in
	expiry_timer.one_shot = true
	expiry_timer.start()
	link.text = verification_url
	link.show()
	label.text = user_code


func _on_link_pressed():
	if verification_url:
		OS.shell_open(verification_url)


func _on_poll_timer_timeout():
	pass # Replace with function body.


func _on_expiry_timer_timeout():
	pass # Replace with function body.
