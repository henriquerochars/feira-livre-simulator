class_name EconomyManager
extends Node

signal changed
const STARTING_CASH: int = 50
var cash: int = STARTING_CASH
var revenue: int = 0
var expenses: int = 0

func reset() -> void:
	cash = STARTING_CASH
	revenue = 0
	expenses = 0
	changed.emit()

func receive(amount: int) -> bool:
	if amount <= 0:
		return false
	cash += amount
	revenue += amount
	changed.emit()
	return true

func spend(amount: int) -> bool:
	if amount <= 0 or cash < amount:
		return false
	cash -= amount
	expenses += amount
	changed.emit()
	return true

func profit() -> int:
	return revenue - expenses
