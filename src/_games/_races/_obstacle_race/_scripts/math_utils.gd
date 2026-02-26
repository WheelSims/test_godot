class_name MathUtils

##to get n*quantum clother number from number
##ex: number = 1.666 => return 1.75 with quantum = 0.25
static func clother_xquantum(quantum: float, number_to_round: float)->int:
	if number_to_round - int(number_to_round/quantum)*quantum < (int(number_to_round/quantum)+1)*quantum - number_to_round:
		return int(number_to_round/quantum)
	else:
		return int(number_to_round/quantum)+1

##to make the inverse operation. Get the clother number from the list
##ex: number = 1.75 => get 1.666
static func clother_number(list: Array, y: float)->float:
	var min_dif := INF
	var number: float
	for x in list:
		if abs(y-x) < min_dif:
			min_dif = abs(y-x)
			number = x
	return number


static func find_random_key(dict: Dictionary, value: Variant, rng: RandomNumberGenerator) -> Variant:
	var matches: Array = []
	
	for k in dict:
		if dict[k] is Array:
			for i in dict[k]:
				if i == value:
					matches.append(k)
		elif dict[k] == value:
			matches.append(k)
	
	if matches.is_empty():
		return null
	
	return matches[rng.randi_range(0, matches.size() - 1)]
