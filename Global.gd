extends Node

const DEVICE_CLIENT_ID := "ca99b720a40e4a57f2f7178165c35737aef40632ccd84ce20a0f4be360362c87"
const DEVICE_CLIENT_SECRET := "935d83556b6c3f4c0dacd1d04723b7d59d66ec698a07d9c30da0f1f79a86408a"
const TRAKT_API_URL := "https://api.trakt.tv"
const TRAKT_API_VERSION := 2

var history_sync


func iso_timestamp() -> String:
	var now = OS.get_datetime(true)
	now.year = str(now.year).pad_zeros(4)
	now.month = str(now.month).pad_zeros(2)
	now.day = str(now.day).pad_zeros(2)
	now.hour = str(now.hour).pad_zeros(2)
	now.minute = str(now.minute).pad_zeros(2)
	now.second = str(now.second).pad_zeros(2).pad_decimals(3)
	return "{year}-{month}-{day}T{hour}:{minute}:{second}Z".format(now)
