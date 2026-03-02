class_name MathUtils
## Contains custom math methods.

## To get the n of the n*quantum clother number from number
## Ex: number = 1.666 => 7*0.25 = 1.75 => returns 7
static func clother_xquantum(quantum: float, number_to_round: float)->int:
	if number_to_round - int(number_to_round/quantum)*quantum < (int(number_to_round/quantum)+1)*quantum - number_to_round:
		return int(number_to_round/quantum)
	else:
		return int(number_to_round/quantum)+1

##Get the clother number from a quanted list. 
##ex: number = 1.75 => get 1.666
static func clother_number(list: Array, y: float)->float:
	var min_dif := INF
	var number: float
	for x in list:
		if abs(y-x) < min_dif:
			min_dif = abs(y-x)
			number = x
	return number

## Take a random key between the differents keys that matches with the given [param value].
## It also works if [param dict] have arrays as values.
static func find_random_key(dict: Dictionary, value: float, rng: RandomNumberGenerator) -> Variant:
	var matches: Array = []
	
	for k in dict:
		if dict[k] is Array:
			for i in dict[k]:
				if i == value and not k in matches:
					matches.append(k)
		elif is_equal_approx(dict[k], value):
			matches.append(k)
	
	if matches.is_empty():
		return null
	
	return matches[rng.randi_range(0, matches.size() - 1)]
