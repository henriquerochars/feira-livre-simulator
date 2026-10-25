class_name InventoryManager
extends Node

signal changed
var stock: Dictionary = {}

func reset() -> void:
	for fruit in FruitCatalog.IDS:
		stock[fruit] = 6
	changed.emit()

func count(fruit: String) -> int:
	return int(stock.get(fruit, 0))

func has_stock(fruit: String, quantity: int) -> bool:
	return FruitCatalog.ITEMS.has(fruit) and quantity > 0 and count(fruit) >= quantity

func remove(fruit: String, quantity: int) -> bool:
	if not has_stock(fruit, quantity):
		return false
	stock[fruit] -= quantity
	changed.emit()
	return true

func add(fruit: String, quantity: int) -> bool:
	if not FruitCatalog.ITEMS.has(fruit) or quantity <= 0:
		return false
	stock[fruit] = count(fruit) + quantity
	changed.emit()
	return true
