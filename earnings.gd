extends RefCounted

const PRICES := {"Meat pie": 8, "Apple pie": 6, "Cherry pie": 6, "Donut": 2, "Coffee": 3, "Soda": 2}
const SAVE_PATH := "user://earnings.cfg"
const TREATMENT_GOAL := 15000
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
var rng := RandomNumberGenerator.new()

func _init(persist := true) -> void:
	save_enabled = persist
	rng.randomize()
	if persist:
		var config := ConfigFile.new()
		if config.load(SAVE_PATH) == OK:
			cash = maxi(0, int(config.get_value("earnings", "cash", 0)))

func start_day() -> void:
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
	if not correct:
		streak = 0
		return {"sale": 0, "tip": 0, "service": 0, "streak_bonus": 0, "total": 0}
	var sale := 0
	for item in items: sale += int(PRICES.get(item, 0))
	if sale <= 0 or day_completed: return {"sale": 0, "tip": 0, "service": 0, "streak_bonus": 0, "total": 0}
	var tip := rng.randi_range(3, 8) if rng.randf() < tip_chance(seconds, perfect_pie) else 0
	streak += 1
	correct_orders += 1
	var service := 35
	var streak_bonus := mini(streak - 1, 3) * 5
	sales += sale
	tips += tip
	service_rewards += service
	streak_rewards += streak_bonus
	cash += sale + tip + service + streak_bonus
	_save()
	return {"sale": sale, "tip": tip, "service": service, "streak_bonus": streak_bonus, "total": sale + tip + service + streak_bonus}

func finish_day() -> int:
	if day_completed: return 0
	day_completed = true
	closing_bonus = 100 if correct_orders > 0 else 0
	cash += closing_bonus
	_save()
	return closing_bonus

func day_total() -> int:
	return sales + tips + service_rewards + streak_rewards + closing_bonus

func _save() -> void:
	if save_enabled:
		var config := ConfigFile.new()
		config.set_value("earnings", "cash", cash)
		if config.save(SAVE_PATH) != OK: push_warning("Could not save earnings.")
