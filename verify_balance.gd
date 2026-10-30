extends SceneTree
func _initialize():
	var economy = preload("res://earnings.gd").new(false)
	economy.rng.seed = 3030
	assert(economy.finish_day() == 0, "Empty days cannot farm a closing bonus")
	economy.start_day()
	for i in range(7):
		var result = economy.payout(["Meat pie"],true,45,true)
		assert(result.service == 35 and result.streak_bonus == mini(i,3)*5)
	var cash: int = economy.cash
	economy.payout(["Meat pie"],false,45,true)
	assert(economy.streak == 0 and economy.cash == cash, "Mistakes reset the streak without deducting savings")
	assert(economy.payout(["Meat pie"],true,45,true).streak_bonus == 0)
	for count in [6,8]:
		var total := 0
		for day in range(1000):
			economy.start_day()
			for i in range(count):
				var recipe: Array = [["Meat pie","Donut","Coffee"],["Apple pie","Soda"],["Cherry pie","Donut","Coffee"],["Meat pie","Soda"]][i%4]
				economy.payout(recipe,true,45,true)
			assert(economy.finish_day() == 100)
			cash = economy.cash
			assert(economy.finish_day() == 0 and economy.cash == cash)
			total += economy.day_total()
		var average := total / 1000.0
		print("BALANCE ",count," correct orders/day: average $",average,"; goal in approximately ",ceil(15000/average)," days")
		assert(average > 440 and average < 610)
	print("PASS: service reward, capped streak, forgiving mistakes, no empty-day or duplicate bonuses, 6/8-order daily simulations")
	quit()
