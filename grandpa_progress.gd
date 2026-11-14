extends RefCounted

const DAILY_DECLINE := 2
const SETBACKS := ["mistreatment", "fall", "setback", "chemo", "wrong_meds"]
const NURSE_EVENT_WEIGHT := 2
var days := 0
var health := 100
var death_day := 0
var setback_seed := 193733
var last_setback_day := -100
var last_setback_id := ""
var setback_history: Array = []
var last_discussed_setback_day := -100
var last_witnessed_mistreatment_day := -100
var evening_pending := false
var visit_in_progress := false
var next_visit_day := 1
var last_visit_day := 0
var last_visit_choice_day := 0
var campaign_won := false
var victory_day := 0
const PLEAS := [
 ["No pressure, kiddo. Just keep the place running. If anybody complains about the pie, tell them I made it. I'm conveniently unavailable for feedback.", "Take your time learning the ropes. Well, a reasonable amount of time. The doctor used the word 'soon' and then looked at a clipboard."],
 ["Quick question. How many pies does a man have to sell to purchase one functioning grandpa? Could we put that number on the specials board?", "I've been counting the ceiling tiles between visits. There are forty-eight. I've asked them to stop charging me rent for the ones I don't look at."],
 ["I've designed a combo called SAVE GRANDPA. Pie, coffee, and the crushing responsibility of keeping me alive. Make the name bigger than the price.", "What if we charged extra for napkins? People need napkins, kiddo. I've seen what cherry filling does to a good pair of pants."],
 ["I tried applying for a job at your diner. Apparently 'currently in a hospital bed' is a scheduling conflict. I said I could handle complaints over the phone.", "Could we ring the bell twice for tips? Once means the order is ready. Twice means an old man has begun negotiating with the ceiling."],
 ["I asked whether the surgery has a punch card. Ten visits, one free organ situation. The doctor said he was going to give me a minute to calm down.", "I've named every ceiling tile after a potential investor. Gary above the television seems interested. Don't embarrass me when Gary comes in."],
 ["Kiddo. Please. Put my face on the pie box. Make the eyes follow people. I want a man buying a donut to feel PERSONALLY SELECTED to save me.", "I've prepared a sales pitch. 'Would you like to make that a combo, or would you prefer to explain yourself to my grandfather?' We can workshop the threatening part AFTER the surgery."],
]
const GREETINGS := [
 "Hey, kiddo. Pull up a chair. Tell me about the diner. I want to hear about something besides hospital food for a change.",
 "There you are. Any news from the diner? I'm asking casually. This is my casual voice. I've been practicing it since breakfast.",
 "Kiddo! Great to see you. Did you bring good news? A wealthy customer? A pie with an unusually high resale value?",
 "Please tell me the diner is busy. I've started hearing the cash register in my dreams. It keeps asking ME for money.",
 "You're here. Good. I've got some business ideas. The nurse has asked me to stop pitching them to people during their blood tests.",
 "Kiddo, thank goodness. Close the door. Not because it's private. I just need everyone walking past to stop hearing me say 'please' this much.",
]

func advance_day(funded: bool) -> void:
	if campaign_won: return
	if is_dead(): return
	days += 1
	evening_pending = true
	if funded: return
	var before := health
	health = maxi(0,health-DAILY_DECLINE)
	_setback(before)
	if is_dead():
		death_day = days
		evening_pending = false
		visit_in_progress = false

func is_dead() -> bool:
	return health <= 0

func _setback(before: int) -> bool:
	if days < 3 or days-last_setback_day < 6 or health <= 0: return false
	var event_rng := RandomNumberGenerator.new()
	event_rng.seed = setback_seed + days * 104729
	if event_rng.randf() >= .12: return false
	var choices: Array = []
	for event in SETBACKS:
		if event == last_setback_id: continue
		for ticket in range(NURSE_EVENT_WEIGHT if event == "mistreatment" else 1):
			choices.append(event)
	last_setback_id = choices[event_rng.randi_range(0,choices.size()-1)]
	var incident_damage := 20 if last_setback_id == "mistreatment" else event_rng.randi_range(8,12)
	health = maxi(0,health-incident_damage)
	last_setback_day = days
	setback_history.append({"day":days,"event_id":last_setback_id,"health_before":before,"health_after":health,"health_loss":before-health})
	return true

func condition() -> String:
	if is_dead(): return "Deceased"
	if health > 75: return "Holding steady"
	if health > 50: return "Tired"
	if health > 25: return "Weak"
	return "Critical"

func visit_available() -> bool:
	return not is_dead() and evening_pending and days >= next_visit_day and last_visit_choice_day != days

func start_visit() -> bool:
	if not visit_available(): return false
	visit_in_progress = true
	last_visit_day = days
	last_visit_choice_day = days
	next_visit_day = days+3
	return true

func finish_evening() -> void:
	if visit_available():
		last_visit_choice_day = days
		next_visit_day = days+3
	evening_pending = false
	visit_in_progress = false

func desperation_stage() -> int:
	var stage := 0
	for threshold in [4,7,10,13,19]:
		if days >= threshold: stage += 1
	if health <= 25: stage = maxi(stage,5)
	elif health <= 50: stage = maxi(stage,3)
	elif health <= 75: stage = maxi(stage,1)
	return stage

func visit_dialogue(cash: int) -> Array[String]:
	var lines: Array[String] = []
	if is_dead(): return lines
	var funded := cash >= 15000
	var stage := desperation_stage()
	if funded:
		lines.append("There you are, kiddo. They told me the surgery money is there. I asked them to say it again. Then I asked whether saying it twice cost extra.")
	elif days <= 1:
		lines.append("There you are, kiddo. I was starting to think the coffee machine had taken you hostage. How was your first day running the place?")
		lines.append("Oh, and if you hear little footsteps in the diner, that's probably the pie. It gets up and walks around sometimes. Last I saw, it was headed for the kitchen.")
		lines.append("It's a very gassy pie, kiddo. Every step sounds like a little fart. That's how you know it's coming.")
		lines.append("Listen, kiddo. After you flip the sign off, you might hear the bell ring out front. I used to go check. There was never anyone at the counter.")
		lines.append("One night I heard the back door open while I was standing right beside it. I could still feel the key in my pocket. Finish up and come home, all right?")
	else:
		lines.append(GREETINGS[stage])
	# Incidents wait for a complete conversation, including after skipped visits.
	if last_setback_day > last_discussed_setback_day:
		match last_setback_id:
			"mistreatment": lines.append("A nurse hit me when I asked for help getting up. Another staff member stopped it and reported what happened. They've moved me away from that nurse. I'm sore and shaken, kiddo. I'm glad you're here.")
			"fall": lines.append("I fell trying to get out of bed. Someone found me and helped me back. They've arranged more help now, but I'm still sore. I didn't want you finding out from someone else.")
			"setback": lines.append("I had a bad night. They had to keep a closer watch on me, and I've been weaker since. I don't want to pretend everything is fine. I needed to tell you myself.")
			"chemo": lines.append("Chemo went bad today, kiddo. I think they overdid the chemo part. I asked for less cancer, not less Grandpa. I feel terrible. Please tell me you sold some pies.")
			"wrong_meds": lines.append("Grandpa's in a lot of pain, boy! They gave me the wrong meds and now my blood is on fire! ooooOOOOooooOOOO! They accidentally gave me more cancer, my boy! Please sell more pies, and quickly, so I can get out of this place!")
	if health > 75:
		lines.append("I'm holding steady. A little tired, but I've still got enough energy to complain about the pudding. That's got to count for something.")
	elif health > 50:
		lines.append("I'm getting tired more easily. Even walking across the room takes a while. I keep picturing the two of us back at our booth.")
	elif health > 25:
		lines.append("I've been spending most of the day in bed. Some days I don't feel like talking much. Today I saved what energy I had for you.")
	else:
		lines.append("Come a little closer, kiddo. My voice isn't what it was. I'm weak, and I'm scared. Please don't make me pretend I'm being brave about it.")
	if funded:
		lines.append("You did it. After all those shifts... thank you. I'm retiring the business ideas. Especially the napkin surcharge. Apparently that one was 'deeply unpopular.'")
		lines.append("When I'm out of here, we're having breakfast together. I'm buying. I love you, kiddo.")
	else:
		lines.append(PLEAS[stage][int(maxi(days-1,0)/3)%2])
		var urgency: String = ["Keep at it. I believe in you.","That number's moving, right? Please tell me it's moving.","Could we move that last part a little faster?","Please. I'm running out of ways to sound relaxed about this.","I need that surgery, kiddo. I'm counting on you.","Please, kiddo. I'm begging. Sell the pies. Ring the bell. Bring me some good news."][stage]
		lines.append("You've saved $%d. We still need $%d for the surgery. %s" % [cash,maxi(0,15000-cash),urgency])
	return lines

func finish_visit_conversation() -> void:
	last_discussed_setback_day = last_setback_day

func read_config(config: ConfigFile) -> void:
	days = maxi(0,int(config.get_value("grandpa","days",0)))
	health = clampi(int(config.get_value("grandpa","health",100)),0,100)
	death_day = maxi(0,int(config.get_value("grandpa","death_day",days if is_dead() else 0)))
	setback_seed = int(config.get_value("grandpa","setback_seed",193733))
	last_setback_day = int(config.get_value("grandpa","last_setback_day",-100))
	last_setback_id = str(config.get_value("grandpa","last_setback_id",""))
	last_discussed_setback_day = int(config.get_value("grandpa","last_discussed_setback_day",-100))
	last_witnessed_mistreatment_day = int(config.get_value("grandpa","last_witnessed_mistreatment_day",-100))
	evening_pending = bool(config.get_value("grandpa","evening_pending",false))
	visit_in_progress = bool(config.get_value("grandpa","visit_in_progress",false))
	next_visit_day = maxi(1,int(config.get_value("grandpa","next_visit_day",1)))
	last_visit_day = maxi(0,int(config.get_value("grandpa","last_visit_day",0)))
	last_visit_choice_day = maxi(0,int(config.get_value("grandpa","last_visit_choice_day",0)))
	campaign_won = bool(config.get_value("grandpa","campaign_won",false)) and not is_dead()
	victory_day = maxi(0,int(config.get_value("grandpa","victory_day",0)))
	if is_dead():
		evening_pending = false
		visit_in_progress = false
	setback_history.clear()
	var stored = config.get_value("grandpa","setback_history",[])
	if stored is Array:
		for event in stored:
			if event is Dictionary and event.has_all(["day","event_id"]): setback_history.append(event.duplicate())
	# Import old incident metadata, but retire the letter archive.
	if not config.has_section_key("grandpa","setback_history"):
		var legacy = config.get_value("grandpa","letters",[])
		if legacy is Array:
			for entry in legacy:
				if entry is Dictionary and entry.get("kind","") == "setback":
					setback_history.append({"day":entry.day,"event_id":entry.event_id,"health_before":entry.get("health_before",health),"health_after":entry.get("health_after",health),"health_loss":entry.get("health_loss",0)})

func write_config(config: ConfigFile) -> void:
	config.set_value("grandpa","campaign_won",campaign_won)
	config.set_value("grandpa","victory_day",victory_day)
	for key in ["days","health","death_day","setback_seed","last_setback_day","last_setback_id","last_discussed_setback_day","last_witnessed_mistreatment_day","evening_pending","visit_in_progress","next_visit_day","last_visit_day","last_visit_choice_day","setback_history"]:
		config.set_value("grandpa",key,get(key))
	for retired in ["letters","next_letter_day","funded_announced"]:
		if config.has_section_key("grandpa",retired): config.erase_section_key("grandpa",retired)
