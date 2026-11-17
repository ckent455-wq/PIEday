extends RefCounted

const PORT := 27842
const REQUEST := "PIEDAY_FIND "
const RESPONSE := "PIEDAY_HOST "
const SCAN_SECONDS := 2.0

var socket := PacketPeerUDP.new()
var host_name := ""
var version := str(ProjectSettings.get_setting("application/config/version"))
var hosting := false
var next_query := 0.0
var seconds_left := 0.0

func host(display_name: String) -> Error:
	var error := socket.bind(PORT, "0.0.0.0")
	if error != OK: return error
	host_name = display_name
	hosting = true
	return OK

func find_hosts() -> Error:
	var error := socket.bind(0, "0.0.0.0")
	if error != OK: return error
	socket.set_broadcast_enabled(true)
	seconds_left = SCAN_SECONDS
	return OK

func tick(delta: float) -> Dictionary:
	var found := {}
	var response_prefix := RESPONSE + version + " "
	while socket.get_available_packet_count() > 0:
		var message := socket.get_packet().get_string_from_utf8()
		var address := socket.get_packet_ip()
		if hosting and message == REQUEST + version:
			socket.set_dest_address(address, socket.get_packet_port())
			socket.put_packet((response_prefix + host_name).to_utf8_buffer())
		elif not hosting and message.begins_with(response_prefix):
			var name := message.substr(response_prefix.length()).strip_escapes().strip_edges().left(20)
			if not name.is_empty(): found[address] = name
	if not hosting and seconds_left > 0.0:
		seconds_left -= delta
		next_query -= delta
		if next_query <= 0.0:
			next_query = 0.35
			socket.set_dest_address("255.255.255.255", PORT)
			socket.put_packet((REQUEST + version).to_utf8_buffer())
	return found

func close() -> void:
	socket.close()
