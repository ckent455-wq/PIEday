extends Node

const API := "https://api.github.com/repos/ckent455-wq/PIEday/releases/latest"
const DOWNLOADS := "https://github.com/ckent455-wq/PIEday/releases/download/"
const STORAGE := "user://updates"
const MAX_DOWNLOAD := 250 * 1024 * 1024
const MAX_EXTRACTED := 512 * 1024 * 1024
var status: Label
var button: Button
var menu: VBoxContainer
var request: HTTPRequest
var asset := {}
var target_version := ""
var downloading := false
var busy := false
var package := STORAGE.path_join("download.zip")
var pending_executable := ""
var storage := STORAGE

static func enabled() -> bool:
	return OS.get_name() == "Windows" and OS.get_executable_path().get_file().to_lower() == "pieday.exe" and not OS.has_feature("playable_demo")

static func version_parts(version: String) -> PackedInt32Array:
	var parts := version.trim_prefix("v").split(".")
	if parts.size() != 3: return PackedInt32Array()
	var result := PackedInt32Array()
	for part in parts:
		if not part.is_valid_int() or part.to_int() < 0: return PackedInt32Array()
		result.append(part.to_int())
	return result

static func newer(candidate: String, current: String) -> bool:
	var a := version_parts(candidate)
	var b := version_parts(current)
	if a.size() != 3 or b.size() != 3: return false
	for i in range(3):
		if a[i] != b[i]: return a[i] > b[i]
	return false

static func redirect_to_installed(tree: SceneTree) -> bool:
	if not enabled(): return false
	var config := ConfigFile.new()
	if config.load(STORAGE.path_join("installed.cfg")) != OK: return false
	var version := str(config.get_value("update", "version", ""))
	if not newer(version, str(ProjectSettings.get_setting("application/config/version"))): return false
	var executable := ProjectSettings.globalize_path(STORAGE.path_join(version).path_join("PIEday-v%s-Windows-x64/PIEday.exe" % version))
	if not FileAccess.file_exists(executable) or not FileAccess.file_exists(executable.get_base_dir().path_join("PIEday.pck")): return false
	if executable.replace("\\", "/").to_lower() == OS.get_executable_path().replace("\\", "/").to_lower(): return false
	if OS.create_process(executable, OS.get_cmdline_user_args()) < 0: return false
	tree.quit()
	return true

func setup(column: VBoxContainer) -> void:
	menu = column
	status = preload("res://diner_ui.gd").label("", 14, preload("res://diner_ui.gd").MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = 340
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(status)
	button = Button.new()
	button.text = "Check for Updates"
	button.custom_minimum_size.y = 42
	menu.add_child(button)
	button.pressed.connect(_pressed)
	request = HTTPRequest.new()
	request.timeout = 15
	request.body_size_limit = 2 * 1024 * 1024
	request.use_threads = true
	request.request_completed.connect(_completed)
	add_child(request)
	check.call_deferred()

func check() -> void:
	if busy: return
	busy = true
	button.disabled = true
	status.text = "Checking for updates…"
	var error := request.request(API, ["User-Agent: PIEday-Updater", "Accept: application/vnd.github+json"])
	if error != OK: _failed("Could not check for updates. Try again.")

func _pressed() -> void:
	if not pending_executable.is_empty():
		_launch(pending_executable)
	elif not asset.is_empty():
		_download()
	else:
		check()

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_failed("Update check unavailable." if not downloading else "Download failed. Your current game is ready to play.")
		return
	if downloading:
		await _install_download()
		return
	busy = false
	button.disabled = false
	var release = JSON.parse_string(body.get_string_from_utf8())
	if not release is Dictionary:
		_failed("Could not read the release information.")
		return
	target_version = str(release.get("tag_name", "")).trim_prefix("v")
	var current := str(ProjectSettings.get_setting("application/config/version"))
	if not newer(target_version, current):
		status.text = "You have the latest version."
		button.text = "Check for Updates"
		return
	for candidate in release.get("assets", []):
		if valid_asset(candidate, target_version):
			asset = candidate
			status.text = "Version %s is available." % target_version
			button.text = "Update to v" + target_version
			return
	_failed("The latest Windows update is not ready yet.")

static func valid_asset(candidate: Dictionary, version: String) -> bool:
	if version_parts(version).size() != 3: return false
	var name := "PIEday-v%s-Windows-x64.zip" % version
	var url := DOWNLOADS + "v%s/%s" % [version, name]
	var digest := str(candidate.get("digest", ""))
	if candidate.get("name", "") != name or candidate.get("browser_download_url", "") != url: return false
	if int(candidate.get("size", 0)) <= 0 or int(candidate.get("size", 0)) > MAX_DOWNLOAD: return false
	if not digest.begins_with("sha256:") or digest.length() != 71: return false
	for character in digest.substr(7).to_lower():
		if character not in "0123456789abcdef": return false
	return true

func _download() -> void:
	if busy: return
	if DirAccess.make_dir_recursive_absolute(storage) != OK:
		_failed("Could not create the update folder.")
		return
	busy = true
	downloading = true
	_lock_menu(true)
	status.text = "Downloading update…"
	request.timeout = 300
	request.body_size_limit = MAX_DOWNLOAD
	package = storage.path_join("download.zip")
	request.download_file = package
	var error := request.request(str(asset.browser_download_url), ["User-Agent: PIEday-Updater"])
	if error != OK: _failed("Could not start the download.")

func _process(_delta: float) -> void:
	if not downloading or not busy: return
	var megabytes := request.get_downloaded_bytes() / 1048576.0
	status.text = "Downloading %.1f / %.1f MB" % [megabytes, int(asset.get("size", 0)) / 1048576.0]

func _install_download() -> void:
	downloading = false
	status.text = "Verifying update…"
	await get_tree().process_frame
	if not verify_package(package, str(asset.digest), int(asset["size"])):
		_failed("Download verification failed. Please retry.")
		return
	status.text = "Installing update…"
	await get_tree().process_frame
	var destination := storage.path_join(target_version)
	var installed := await extract_package(package, destination, target_version)
	if installed.is_empty():
		_failed("Could not install the update. Please retry.")
		return
	var config := ConfigFile.new()
	config.set_value("update", "version", target_version)
	var config_path := storage.path_join("installed.cfg")
	var error := config.save(config_path + ".tmp")
	if error == OK: error = DirAccess.rename_absolute(config_path + ".tmp", config_path)
	if error != OK:
		_failed("Could not finish installing the update.")
		return
	pending_executable = ProjectSettings.globalize_path(installed)
	_launch(pending_executable)

static func verify_package(path: String, digest: String, expected_size: int) -> bool:
	if not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() != expected_size: return false
	file.close()
	return "sha256:" + FileAccess.get_sha256(path) == digest.to_lower()

static func safe_entry(path: String, root: String) -> bool:
	return not path.is_absolute_path() and "\\" not in path and ":" not in path and not path.split("/").has("..") and path.begins_with(root + "/")

func extract_package(path: String, destination: String, version: String) -> String:
	if version_parts(version).size() != 3: return ""
	var reader := ZIPReader.new()
	if reader.open(path) != OK: return ""
	var root := "PIEday-v%s-Windows-x64" % version
	var executable := root.path_join("PIEday.exe")
	if not reader.file_exists(executable) or not reader.file_exists(root.path_join("PIEday.pck")):
		reader.close()
		return ""
	var files := reader.get_files()
	for entry in files:
		if not safe_entry(entry, root):
			reader.close()
			return ""
	var total := 0
	for entry in files:
		if entry.ends_with("/"): continue
		var contents := reader.read_file(entry)
		total += contents.size()
		if total > MAX_EXTRACTED or (entry in [executable, root.path_join("PIEday.pck")] and contents.is_empty()):
			reader.close()
			return ""
		var output := destination.path_join(entry)
		if DirAccess.make_dir_recursive_absolute(output.get_base_dir()) != OK:
			reader.close()
			return ""
		var file := FileAccess.open(output, FileAccess.WRITE)
		if file == null:
			reader.close()
			return ""
		file.store_buffer(contents)
		file.close()
		await get_tree().process_frame
	reader.close()
	return destination.path_join(executable)

func _launch(executable: String) -> void:
	if OS.create_process(executable, PackedStringArray()) >= 0:
		get_tree().quit()
	else:
		_failed("Update installed. Click to open the new version.")
		button.text = "Open Updated Game"

func _failed(message: String) -> void:
	busy = false
	downloading = false
	if request != null:
		request.download_file = ""
		request.body_size_limit = 2 * 1024 * 1024
		request.timeout = 15
	status.text = message
	_lock_menu(false)

func _lock_menu(locked: bool) -> void:
	for child in menu.get_children():
		if child is Button: child.disabled = locked
