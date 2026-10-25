class_name GameSessionManager
extends Node

signal started
signal closing
signal finished(results: Dictionary)
signal feedback(message: String, success: bool)
const DURATION: float = 180.0
var inventory: InventoryManager
var economy: EconomyManager
var active: bool = false
var remaining: float = DURATION
var served: int = 0
var missed: int = 0

func _init() -> void:
	inventory = InventoryManager.new()
	inventory.name = "InventoryManager"
	add_child(inventory)
	economy = EconomyManager.new()
	economy.name = "EconomyManager"
	add_child(economy)

func start_session() -> void:
	active = false
	inventory.reset()
	economy.reset()
	remaining = DURATION
	served = 0
	missed = 0
	active = true
	started.emit()

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not active:
		return
	remaining = maxf(0.0, remaining - maxf(delta, 0.0))
	if remaining <= 0.0:
		finish_session()

func sell(fruit: String, quantity: int) -> bool:
	if not active or not FruitCatalog.ITEMS.has(fruit) or quantity <= 0:
		return false
	if not inventory.remove(fruit, quantity):
		feedback.emit("Faltou fruta! Reponha nas caixas atrás da banca.", false)
		return false
	var amount: int = int(FruitCatalog.ITEMS[fruit]["price"]) * quantity
	economy.receive(amount)
	served += 1
	feedback.emit("Venda feita! +%s • %s" % [FruitCatalog.money(amount), FruitCatalog.order_text(fruit, quantity)], true)
	return true

func restock(fruit: String) -> bool:
	if not active or not FruitCatalog.ITEMS.has(fruit):
		return false
	var cost: int = int(FruitCatalog.ITEMS[fruit]["cost"])
	if not economy.spend(cost):
		feedback.emit("Dinheiro insuficiente para esta caixa.", false)
		return false
	inventory.add(fruit, FruitCatalog.PACK_SIZE)
	feedback.emit("Chegou reposição! +6 %s • −%s" % [FruitCatalog.ITEMS[fruit]["plural"], FruitCatalog.money(cost)], true)
	return true

func record_missed() -> void:
	if active:
		missed += 1
		feedback.emit("Um cliente foi embora. Bora agilizar!", false)

func results() -> Dictionary:
	var net: int = economy.profit()
	var rating: String = "Aprendiz da feira"
	if net >= 180 and served >= 15:
		rating = "Lenda da feira!"
	elif net >= 100 and served >= 9:
		rating = "Feirante de primeira!"
	elif net >= 40:
		rating = "Tá pegando o jeito!"
	return {"revenue": economy.revenue, "expenses": economy.expenses, "profit": net,
		"cash": economy.cash, "served": served, "missed": missed, "rating": rating}

func finish_session() -> void:
	if not active:
		return
	closing.emit()
	active = false
	remaining = 0.0
	finished.emit(results())
