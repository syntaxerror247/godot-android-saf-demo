extends Control

@onready var uri_edit: LineEdit = $VBoxContainer/uri
@onready var logs: RichTextLabel = $VBoxContainer/Logs

var current_uri: String = ""
var tree_file_path: String = ""

const PASSWORD := "password"
const TREE_URI := "content://com.android.externalstorage.documents/tree/"

func pick_file() -> void:
	DisplayServer.file_dialog_show("", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, [], _on_file_picked)


func pick_directory() -> void:
	DisplayServer.file_dialog_show("", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_DIR, [], _on_directory_picked)


func _on_file_picked(selected: bool, uris: PackedStringArray, _filter_index: int) -> void:
	if not selected or uris.is_empty():
		log_print("Picker cancelled")
		return
	set_uri(uris[0])
	print_metadata(uris[0])


func _on_directory_picked(selected: bool, uris: PackedStringArray, _filter_index: int) -> void:
	if not selected or uris.is_empty():
		log_print("Picker cancelled")
		return
	set_uri(uris[0])


func set_uri(uri: String) -> void:
	current_uri = uri
	uri_edit.text = uri
	log_print("URI selected: %s" % uri)


func print_metadata(uri: String) -> void:
	log_print("exists: %s" % FileAccess.file_exists(uri))
	log_print("size: %d" % FileAccess.get_size(uri))
	log_print("modified_time: %s" % FileAccess.get_modified_time(uri))
	log_print("md5: %s" % FileAccess.get_md5(uri))


func write_file() -> void:
	var uri = current_uri
	if uri.is_empty():
		log_print("No URI selected")
		return
	
	if uri.begins_with(TREE_URI):
		uri += "#"+tree_file_path

	var f := FileAccess.open(uri, FileAccess.WRITE)
	if not f:
		log_print("Write failed, Error %s" % str(FileAccess.get_open_error()))
		return

	f.store_line("This is an SAF read/write test")
	f.store_line("Stored at %s" % Time.get_datetime_string_from_system())
	f.close()
	log_print("Write completed")


func read_file() -> void:
	var uri = current_uri
	if uri.is_empty():
		log_print("No URI selected")
		return
	
	if uri.begins_with(TREE_URI):
		uri += "#"+tree_file_path

	var f := FileAccess.open(uri, FileAccess.READ)
	if not f:
		log_print("Read failed, Error %s" % str(FileAccess.get_open_error()))
		return

	log_print("--- File content ---")
	log_print(f.get_as_text())
	f.close()


func encrypted_rw() -> void:
	var uri = current_uri
	if uri.is_empty():
		log_print("No URI selected")
		return
	
	if uri.begins_with(TREE_URI):
		uri += "#"+tree_file_path

	var f := FileAccess.open_encrypted_with_pass(uri, FileAccess.WRITE, PASSWORD)
	if not f:
		log_print("Encrypted write failed")
		return

	f.store_line("Encrypted SAF demo success")
	f.close()

	f = FileAccess.open_encrypted_with_pass(uri, FileAccess.READ, PASSWORD)
	if not f:
		log_print("Encrypted read failed")
		return

	log_print(f.get_as_text())
	f.close()


func set_persist(enable: bool) -> void:
	if current_uri.is_empty():
		log_print("No URI selected")
		return

	var android_runtime := Engine.get_singleton("AndroidRuntime")
	if not android_runtime:
		log_print("AndroidRuntime plugin not found")
		return

	var ok: bool = android_runtime.updatePersistableUriPermission(current_uri, enable)
	log_print("Persistable permission: %s" % ok)


func _on_uri_text_submitted(new_text: String) -> void:
	current_uri = new_text
	log_print("Current URI updated")


func _on_tree_file_path_text_submitted(new_text: String) -> void:
	tree_file_path = new_text
	log_print("Tree URI updated")


func _on_copy_uri_pressed() -> void:
	DisplayServer.clipboard_set(current_uri)
	log_print("Copied URI to clipboard")


func _on_paste_pressed() -> void:
	current_uri = DisplayServer.clipboard_get()
	uri_edit.text = current_uri
	log_print("Pasted URI from clipboard")


func log_print(msg) -> void:
	print("[SAF Test] ", msg)
	logs.append_text("%s\n" % msg)


func _ready() -> void:
	get_window().content_scale_factor = DisplayServer.screen_get_dpi() / 160.0
