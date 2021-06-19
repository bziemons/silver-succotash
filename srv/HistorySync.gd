extends Control

const HISTORY_DATA_URI := "user://history.ndjson"
const TRAKT_API_SYNC_HISTORY := Global.TRAKT_API_URL + "/sync/history"

# populated in Main.gd
var main

# history data
var history: Array

# script local variables
var history_state: int = 0
var history_sync_params: String
var current_history_sync := ""


func sync_history():
	history_state = 1
	if main.last_history_sync:
		history_sync_params = "?start_at=" + main.last_history_sync.percent_encode()
	else:
		history_sync_params = ""
	current_history_sync = Global.iso_timestamp()
	request_more_history(history_sync_params)


func request_more_history(params):
	assert(len(params) == 0 or params.startswith("?"))
	var headers = [
		"Accept: application/json",
		"Authorization: Bearer " + main.auth.access_token,
		"trakt-api-version: " + str(Global.TRAKT_API_VERSION),
		"trakt-api-key: " + Global.DEVICE_CLIENT_ID,
	]
	$SyncHistoryAccess.request(TRAKT_API_SYNC_HISTORY + params, headers, true,
							   HTTPClient.METHOD_GET)


func _on_sync_history_request_completed(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		if response_code == 200:
			assert(history_state == 1)
			# headers is an Array with Strings: "X-Pagination-Page: 1"
			if headers['X-Pagination-Page'] == headers['X-Pagination-Page-Count']:
				history_state = 2  # the history sync end
			else:
				history_state = 1

			assert(history is Array)
			var response = parse_json(body.get_string_from_utf8())
			assert(response is Array)
			history.append_array(response)

			if history_state == 1:
				# request more
				var params = "page={0}&limit={1}".format(
					[headers['X-Pagination-Page'] + 1, headers['X-Pagination-Limit']]
				)
				if len(history_sync_params) > 0:
					params = history_sync_params + "&" + params
				else:
					params = "?" + params

				request_more_history(params)
			elif history_state == 2:
				save_data()
				main.last_history_sync = current_history_sync
				main.save_data()
		elif response_code == HTTPClient.RESPONSE_UNAUTHORIZED:
			main.report_authentication_failure(get_tree())
		else:
			push_error(
				"Error in history sync response with http code: {0}".format([response_code])
			)
	else:
		push_error("Error in history sync api request with result code: {0}".format([result]))


func load_data():
	history = []

	var data_file := File.new()

	if data_file.file_exists(HISTORY_DATA_URI):
		data_file.open(HISTORY_DATA_URI, File.READ)
		while not data_file.eof_reached():
			var line = data_file.get_line()
			if line:
				history.append(parse_json(line))
		data_file.close()


func save_data():
	var data_file := File.new()

	data_file.open(HISTORY_DATA_URI, File.WRITE)
	for obj in history:
		data_file.store_line(to_json(obj))
	data_file.close()
