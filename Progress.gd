extends Control

const TRAKT_API_WATCHED_SHOW = Auto.TRAKT_API_URL + "/shows/{id}/progress/watched"
const PROGRESS_SHOW_MIN_SIZE = 180.0
const PROGRESS_SHOW_MAX_SIZE = 200.0


# populated in Main.gd
var main


func _ready():
	OS.window_borderless = false
	OS.window_size = Vector2(ProjectSettings.get_setting("display/window/size/width"),
							 ProjectSettings.get_setting("display/window/size/height"))
	OS.window_resizable = true
	OS.center_window()

	update_grid_container_columns()
	var headers = [
		"Accept: application/json",
		"Authorization: Bearer " + main.auth.access_token,
		"trakt-api-version: " + str(Auto.TRAKT_API_VERSION),
		"trakt-api-key: " + Auto.DEVICE_CLIENT_ID,
	]
	$APIAccess.request(TRAKT_API_WATCHED_SHOW.format({"id": 123}), headers, true,
					   HTTPClient.METHOD_GET)


func _on_api_access_request_completed(result, response_code, headers, body):
	pass # Replace with function body.


func _on_scroll_container_resized():
	update_grid_container_columns()


func update_grid_container_columns():
	var x = $ScrollContainer.rect_size.x
	if x <= 0:
		x = OS.window_size.x
	if x >= PROGRESS_SHOW_MIN_SIZE:
		$ScrollContainer/GridContainer.columns = int(floor(x / PROGRESS_SHOW_MIN_SIZE))
	else:
		$ScrollContainer/GridContainer.columns = 1
