extends RefCounted

const FIRST := ["Alex", "Jordan", "Morgan", "Casey", "Riley", "Jamie", "Taylor", "Sam", "Cameron", "Quinn", "Robin", "Avery", "Drew", "Reese", "Charlie", "Jessie", "Frankie", "Blair", "Lane", "Shawn", "Leslie", "Dana", "Devon", "Emerson", "Hayden", "Parker", "Rory", "Skyler", "Marley", "Logan"]
const LAST := ["Hensley", "Morrow", "Dobbins", "Cobb", "Pruitt", "Finch", "Kessler", "Mooney", "Quigley", "Knox", "Delaney", "Patton", "Dunlap", "Baxter", "Wiggins", "Holt", "Mercer", "Bellamy", "Sutton", "Caldwell", "Beasley", "Prescott", "Webb", "Malloy", "Bishop", "Sawyer", "Pike", "Whitaker", "Moss", "Bennett"]
static var previous := ""

static func generate() -> String:
	var first := randi_range(0, FIRST.size() - 1)
	var last := randi_range(0, LAST.size() - 1)
	var full_name: String = FIRST[first] + " " + LAST[last]
	if full_name == previous:
		full_name = FIRST[first] + " " + LAST[(last + 1) % LAST.size()]
	previous = full_name
	return full_name
