extends Node
class_name SaveLoad

func save(_filename, _data):
	var file = File.new()
	file.open(_filename, File.WRITE)
	file.store_var(_data, true)
	file.close()

func load_save(_filename):
	var file = File.new()
	if file.file_exists(_filename):
		file.open(_filename, File.READ)
		var _data = file.get_var(true)
		file.close()
		return _data
	return null

func delete_save(_filename):
	var dir = Directory.new()
	dir.remove(_filename)
