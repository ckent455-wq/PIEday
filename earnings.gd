extends RefCounted

const PRICES := {"Meat pie": 8, "Apple pie": 6, "Cherry pie": 6, "Donut": 2, "Strawberry donut": 2, "Chocolate donut": 2, "Glazed donut": 2, "Coffee": 3, "Soda": 2, "Cola": 2, "Lemon Fizz": 2, "Dr. Paw Paw": 2}
const SAVE_PATH := "user://earnings.cfg"
const TREATMENT_GOAL := 15000
const SERVICE_REWARD := 145
const CLOSING_BONUS := 275
var cash := 0
var sales := 0
var tips := 0
var service_rewards := 0
var streak_rewards := 0
var streak := 0
var correct_orders := 0
var closing_bonus := 0
var day_completed := false
var save_enabled := true
var save_path := SAVE_PATH
var rng := RandomNumberGenerator.new()
var grandpa := preload("res://grandpa_progress.gd").new()

func _init(persist := true, path := SAVE_PATH) -> void:
	save_path = path
	save_enabled = persist
	rng.randomize()
	if persist:
		var config := ConfigFile.new()
		if config.load(save_path) == OK:
			cash = maxi(0, int(config.get_value("earnings", "cash", 0)))
			grandpa.read_config(config)

func health_status() -> String:
	if grandpa.is_dead(): return "Grandpa: 0% · Deceased"
	if cash >= TREATMENT_GOAL: return "Grandpa: Surgery funded · Stable"
	var condition: String = grandpa.condition()
	if grandpa.last_setback_day == grandpa.days: condition = "Recent setback"
	return "Grandpa: %d%% · %s" % [grandpa.health, condition]

func start_day() -> void:
	if grandpa.is_dead(): return
	sales = 0
	tips = 0
	service_rewards = 0
	streak_rewards = 0
	streak = 0
	correct_orders = 0
	closing_bonus = 0
	day_completed = false

func tip_chance(seconds: float, perfect_pie: bool) -> float:
	var chance := 0.50
	if seconds <= 60.0: chance += 0.15
	elif seconds > 120.0: chance -= 0.20
	if perfect_pie: chance += 0.15
	return clampf(chance, 0.0, 0.80)

func payout(items: Array, correct: bool, seconds: float, perfect_pie: bool) -> Dictionary:
	if grandpa.is_dead(): return {"sale":0,"tip":0,"service":0,"streak_bonus":0,"total":0}
	if not correct:
		streak = 0
		return {"sale": 0, "tip": 0, "service": 0, "streak_bonus": 0, "total": 0}
	var sale := 0
	for item in items: sale += int(PRICES.get(item, 0))
	if sale <= 0 or day_completed: return {"sale": 0, "tip": 0, "service": 0, "streak_bonus": 0, "total": 0}
	var tip := rng.randi_range(3, 8) if rng.randf() < tip_chance(seconds, perfect_pie) else 0
	streak += 1
	correct_orders += 1
	var service := SERVICE_REWARD
	var streak_bonus := mini(streak - 1, 3) * 5
	sales += sale
	tips += tip
	service_rewards += service
	streak_rewards += streak_bonus
	cash += sale + tip + service + streak_bonus
	_save()
	return {"sale": sale, "tip": tip, "service": service, "streak_bonus": streak_bonus, "total": sale + tip + service + streak_bonus}

func finish_day() -> int:
	if day_completed or grandpa.is_dead(): return 0
	day_completed = true
	closing_bonus = CLOSING_BONUS if correct_orders > 0 else 0
	cash += closing_bonus
	grandpa.advance_day(cash >= TREATMENT_GOAL)
	_save()
	return closing_bonus

func day_total() -> int:
	return sales + tips + service_rewards + streak_rewards + closing_bonus

func _save() -> void:
	if save_enabled:
		var config := ConfigFile.new()
		config.set_value("earnings", "cash", cash)
		grandpa.write_config(config)
		if config.save(save_path) != OK: push_warning("Could not save game progress.")
