extends SceneTree

const UPDATER := preload("res://game_updater.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	assert(UPDATER.newer("0.11.0", "0.10.9"))
	assert(UPDATER.newer("v0.11.10", "0.11.2"))
	assert(not UPDATER.newer("0.11.0", "0.11.0"))
	assert(not UPDATER.newer("../bad", "0.11.0"))
	var version := "0.12.0"
	var folder := "user://updater-test-" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(folder)
	var root_name := "PIEday-v%s-Windows-x64" % version
	assert(UPDATER.safe_entry(root_name + "/PIEday.exe", root_name))
	for path in ["../PIEday.exe", "/PIEday.exe", root_name + "/../outside", "C:/PIEday.exe", root_name + "/..\\outside"]:
		assert(not UPDATER.safe_entry(path, root_name))
	var updater := UPDATER.new()
	root.add_child(updater)
	var archive := folder.path_join("fixture.zip")
	var zip := ZIPPacker.new()
	assert(zip.open(archive) == OK)
	for name in ["PIEday.exe", "PIEday.pck"]:
		assert(zip.start_file(root_name + "/" + name) == OK)
		assert(zip.write_file(("verified fixture " + name).to_utf8_buffer()) == OK)
		zip.close_file()
	zip.close()
	var file := FileAccess.open(archive, FileAccess.READ)
	var size := file.get_length()
	file.close()
	var digest := "sha256:" + FileAccess.get_sha256(archive)
	assert(UPDATER.verify_package(archive, digest, size))
	assert(not UPDATER.verify_package(archive, digest, size + 1))
	assert(not UPDATER.verify_package(archive, "sha256:" + "0".repeat(64), size))
	var asset := {"name": root_name + ".zip", "browser_download_url": UPDATER.DOWNLOADS + "v%s/%s.zip" % [version, root_name], "digest": digest, "size": size}
	assert(UPDATER.valid_asset(asset, version))
	asset.digest = "sha256:" + "z".repeat(64)
	assert(not UPDATER.valid_asset(asset, version))
	var destination := folder.path_join("installed")
	var executable: String = await updater.extract_package(archive, destination, version)
	assert(FileAccess.get_file_as_string(executable) == "verified fixture PIEday.exe")
	assert(FileAccess.file_exists(executable.get_base_dir().path_join("PIEday.pck")))
	var unsafe_zip := folder.path_join("unsafe.zip")
	assert(zip.open(unsafe_zip) == OK)
	for path in [root_name + "/PIEday.exe", root_name + "/PIEday.pck", root_name + "/../outside.txt"]:
		zip.start_file(path)
		zip.write_file("unsafe".to_utf8_buffer())
		zip.close_file()
	zip.close()
	assert((await updater.extract_package(unsafe_zip, folder.path_join("rejected"), version)).is_empty())
	assert(not FileAccess.file_exists(folder.path_join("outside.txt")))
	print("PASS: update version ordering, trusted asset selection, SHA-256 verification, ZIP extraction and traversal rejection")
	quit()
