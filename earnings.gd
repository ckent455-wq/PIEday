extends RefCounted

const PRICES := {"Burger": 8, "Cheeseburger": 9, "Deluxe burger": 10, "Meat pie": 8, "Apple pie": 6, "Cherry pie": 6, "Donut": 2, "Strawberry donut": 2, "Chocolate donut": 2, "Glazed donut": 2, "Coffee": 3, "Soda": 2, "Cola": 2, "Lemon Fizz": 2, "Dr. Paw Paw": 2, "2-liter Cola": 4, "2-liter Lemon Fizz": 4, "2-liter Dr. Paw Paw": 4, "2-liter Orange Soda": 4, "Basket of fries": 3}
const SAVE_PATH := "user://earnings.cfg"
const TREATMENT_GOAL := 15000
const SERVICE_REWARD := 80
const CLOSING_BONUS := 300
var cash := 0
var sales := 0
var tips := 0
var service_rewards := 0
var streak_rewards := 0
var streak := 0
var correct_orders := 0
var closing_bonus := 0
var day_completed := false
var shift_takings := 0
var robbery_losses := 0
var save_enabled := true
var save_path := SAVE_PATH
var rng := RandomNumberGenerator.new()
var grandpa := preload("res://grandpa_progress.gd").new()
var equipment := {"broken":{},"roll_day":-1,"pending":false,"break_at":100.0,"seed":0,"spent":0}

func _init(persist := true, path := SAVE_PATH) -> void:
	save_path = path
	save_enabled = persist
	rng.randomize()
	if persist:
		var config := ConfigFile.new()
		if config.load(save_path) == OK:
			cash = maxi(0, int(config.get_value("earnings", "cash", 0)))
			shift_takings = maxi(0,int(config.get_value("earnings","shift_takings",0)))
			robbery_losses = maxi(0,int(config.get_value("earnings","robbery_losses",0)))
			grandpa.read_config(config)
			var saved = config.get_value("earnings","equipment",{})
			if saved is Dictionary: equipment.merge(saved,true)

func health_status() -> String:
	if grandpa.is_dead(): return "Grandpa: 0% · Deceased"
	if grandpa.campaign_won: return "Grandpa: Recovered · Back at the diner"
	if cash >= TREATMENT_GOAL: return "Grandpa: Surgery funded · Stable"
	var condition: String = grandpa.condition()
	if grandpa.last_setback_day == grandpa.days: condition = "Recent setback"
	return "Grandpa: %d%% · %s" % [grandpa.health, condition]

func start_day() -> void:
	if grandpa.is_dead() or grandpa.campaign_won: return
	sales = 0
	tips = 0
	service_rewards = 0
	streak_rewards = 0
	streak = 0
	correct_orders = 0
	closing_bonus = 0
	day_completed = false
	shift_takings = 0
	robbery_losses = 0

func tip_chance(seconds: float, perfect_pie: bool) -> float:
	var chance := 0.50
	if seconds <= 60.0: chance += 0.15
	elif seconds > 120.0: chance -= 0.20
	if perfect_pie: chance += 0.15
	return clampf(chance, 0.0, 0.80)

func payout(items: Array, correct: bool, seconds: float, perfect_pie: bool, extra_tip := 0) -> Dictionary:
	if grandpa.is_dead() or grandpa.campaign_won: return {"sale":0,"tip":0,"service":0,"streak_bonus":0,"total":0}
	if not correct:
		streak = 0
		return {"sale": 0, "tip": 0, "service": 0, "streak_bonus": 0, "total": 0}
	var sale := 0
	for item in items: sale += int(PRICES.get(item, 0))
	if sale <= 0 or day_completed: return {"sale": 0, "tip": 0, "service": 0, "streak_bonus": 0, "total": 0}
	var tip := rng.randi_range(3, 8) if rng.randf() < tip_chance(seconds, perfect_pie) else 0
	tip += extra_tip
	streak += 1
	correct_orders += 1
	var service := SERVICE_REWARD
	var streak_bonus := mini(streak - 1, 3) * 5
	sales += sale
	tips += tip
	service_rewards += service
	streak_rewards += streak_bonus
	cash += sale + tip + service + streak_bonus
	shift_takings += sale + tip + service + streak_bonus
	_save()
	return {"sale": sale, "tip": tip, "service": service, "streak_bonus": streak_bonus, "total": sale + tip + service + streak_bonus}

func finish_day() -> int:
	if day_completed or grandpa.is_dead() or grandpa.campaign_won: return 0
	day_completed = true
	closing_bonus = CLOSING_BONUS if correct_orders > 0 else 0
	cash += closing_bonus
	grandpa.advance_day(cash >= TREATMENT_GOAL)
	_save()
	return closing_bonus

func day_total() -> int:
	return maxi(0,sales + tips + service_rewards + streak_rewards + closing_bonus - robbery_losses)

func lose_shift_takings() -> int:
	var stolen := mini(cash,shift_takings)
	cash -= stolen
	shift_takings = 0
	robbery_losses += stolen
	_save()
	return stolen

func complete_campaign() -> bool:
	if grandpa.is_dead() or cash < TREATMENT_GOAL: return false
	if grandpa.campaign_won: return true
	grandpa.campaign_won = true
	grandpa.victory_day = grandpa.days
	grandpa.health = 100
	grandpa.evening_pending = false
	grandpa.visit_in_progress = false
	_save()
	return true

func _save() -> void:
	if save_enabled:
		var config := ConfigFile.new()
		config.set_value("earnings", "cash", cash)
		config.set_value("earnings", "shift_takings", shift_takings)
		config.set_value("earnings", "robbery_losses", robbery_losses)
		config.set_value("earnings", "equipment", equipment)
		grandpa.write_config(config)
		if config.save(save_path) != OK: push_warning("Could not save game progress.")
