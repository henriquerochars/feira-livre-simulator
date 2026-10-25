class_name FruitCatalog
extends RefCounted

const IDS: Array[String] = ["banana", "maca", "laranja"]
const ITEMS: Dictionary = {
	"banana": {"name": "Banana", "plural": "bananas", "price": 5, "cost": 12, "color": Color("f9ce45")},
	"maca": {"name": "Maçã", "plural": "maçãs", "price": 7, "cost": 18, "color": Color("ef6057")},
	"laranja": {"name": "Laranja", "plural": "laranjas", "price": 6, "cost": 15, "color": Color("ff962f")},
}
const PACK_SIZE: int = 6

static func money(value: int) -> String:
	return "R$ %d,00" % value

static func order_text(fruit: String, quantity: int) -> String:
	return "%d %s" % [quantity, ITEMS[fruit]["name"].to_lower() if quantity == 1 else ITEMS[fruit]["plural"]]
