class_name MarketManager
extends Node3D

var session: GameSessionManager
var stock_visuals: Dictionary = {}

func build(game_session: GameSessionManager) -> void:
	session = game_session
	_lighting()
	_street()
	_player_stand()
	for side in [-1, 1]:
		for i in range(4):
			_building(Vector3(side * 13, 0, 5 - i * 8), i, side)
		for i in range(3):
			_decorative_stall(Vector3(side * 7.5, 0, -5 - i * 6.5), i, side)
		for z in [6, -9, -24]:
			_tree(Vector3(side * 10.5, 0.2, z))
		for z in [2, -14, -26]:
			_lamp(Vector3(side * 10, 0.2, z))
	_bunting()
	session.inventory.changed.connect(update_stock)
	update_stock()

func _lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("3985b6")
	sky_mat.sky_horizon_color = Color("b5e3ea")
	sky_mat.ground_horizon_color = Color("b5e3ea")
	sky_mat.ground_bottom_color = Color("c9bc99")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e4f1ff")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("fff0d1")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	add_child(sun)

func _street() -> void:
	MarketArt.box(self, Vector3(0, -0.22, -9), Vector3(36, 0.4, 47), Color("a39d89"), true)
	MarketArt.box(self, Vector3(0, -0.01, -11), Vector3(20, 0.03, 43), Color("647c7d"))
	for side in [-1, 1]:
		MarketArt.box(self, Vector3(side * 10.7, 0.08, -11), Vector3(2, 0.22, 43), Color("d9c9ad"), true)
		for i in range(22):
			MarketArt.box(self, Vector3(side * 9.72, 0.19, 10 - i * 2), Vector3(0.13, 0.05, 1.85), Color("f8ebca"))
	for i in range(9):
		MarketArt.box(self, Vector3(0, 0.015, -7 - i * 2.5), Vector3(0.12, 0.015, 1), Color("edcf6a"))
	for x in range(-4, 5):
		MarketArt.box(self, Vector3(x * 1.1, 0.02, -23), Vector3(0.65, 0.02, 2.3), Color("e9e3cb"))
	# Physical perimeter keeps exploration inside the neighborhood.
	for x in [-18, 18]:
		MarketArt.box(self, Vector3(x, 2, -9), Vector3(0.4, 4, 47), Color("dab98c"), true)
	for z in [-32, 14]:
		MarketArt.box(self, Vector3(0, 1.1, z), Vector3(36, 2.2, 0.4), Color("ead0a1"), true)
	MarketArt.label(self, "VILA ESPERANÇA", Vector3(0, 3.8, -31.7), 90, Color("ffe09a"))
	MarketArt.label(self, "Todo domingo tem feira!", Vector3(0, 3.15, -31.7), 40)

func _player_stand() -> void:
	var stand := Node3D.new()
	stand.name = "BancaDoJogador"
	add_child(stand)
	MarketArt.canopy(stand, 7.0, 3.8, Color("e98b43"))
	MarketArt.box(stand, Vector3(0, 0.5, 0), Vector3(6.3, 1, 1), Color("2a7974"), true)
	MarketArt.box(stand, Vector3(0, 1.02, 0), Vector3(6.5, 0.12, 1.2), Color("e9bf7d"), true)
	MarketArt.box(stand, Vector3(0, 0.45, -0.516), Vector3(6.2, 0.09, 0.02), Color("f6cd7a"))
	var title := MarketArt.label(stand, "BANCA DO CAPRICHO", Vector3(0, 3.38, -1.96), 67, Color("fff4d4"))
	title.rotation.y = PI
	MarketArt.label(stand, "BANCA DO CAPRICHO", Vector3(0, 3.38, 1.96), 67, Color("fff4d4"))
	for i in range(3):
		var id: String = FruitCatalog.IDS[i]
		var x: float = (i - 1) * 2.0
		MarketArt.crate(stand, Vector3(x, 1.08, 0), Vector3(1.65, 0.3, 0.85))
		var pile := Node3D.new()
		pile.position = Vector3(x, 1.27, 0)
		stand.add_child(pile)
		for j in range(12):
			MarketArt.fruit(pile, id, Vector3((j % 4 - 1.5) * 0.34, (j / 8) * 0.14, (j / 4 % 2 - 0.5) * 0.37))
		stock_visuals[id] = pile
		var price := MarketArt.label(stand, "%s  •  R$ %d" % [FruitCatalog.ITEMS[id]["name"], FruitCatalog.ITEMS[id]["price"]], Vector3(x, 0.83, 0.62), 28, Color("fff4d4"))
		price.outline_size = 9
		var point := RestockPoint.new()
		point.fruit = id
		point.session = session
		point.position = Vector3(x, 0, 5.1)
		add_child(point)
		MarketArt.crate(point, Vector3.ZERO, Vector3(1.5, 0.65, 1.1))
		MarketArt.crate(point, Vector3(0, 0.65, 0), Vector3(1.5, 0.65, 1.1))
		for j in range(6):
			MarketArt.fruit(point, id, Vector3((j % 3 - 1) * 0.35, 1.19, (j / 3 - 0.5) * 0.4))
		var sign := MarketArt.label(point, "+6 %s\nR$ %d  •  [E]" % [FruitCatalog.ITEMS[id]["plural"], FruitCatalog.ITEMS[id]["cost"]], Vector3(0, 1.8, -0.1), 31, Color("fff2c0"))
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var depot_sign := MarketArt.label(self, "REPOSIÇÃO  •  CAIXAS COM 6 FRUTAS", Vector3(0, 2.75, 5.7), 43, Color("fff0b8"))
	depot_sign.rotation.y = PI
	MarketArt.box(self, Vector3(-4.2, 0.75, 0.5), Vector3(0.85, 1.5, 0.12), Color("34534b"), true)
	MarketArt.label(self, "É SUA\nBANCA!\n\nAtenda com E", Vector3(-4.2, 1.0, 0.58), 26, Color("fff0bc"))
	# Floor marks guide the three customers to the counter.
	for x in [-2, 0, 2]:
		MarketArt.cylinder(self, Vector3(x, 0.025, -1.65), 0.5, 0.02, Color("eac771"))

func update_stock() -> void:
	for id in stock_visuals:
		var pile: Node3D = stock_visuals[id]
		var count: int = session.inventory.count(id)
		for i in range(pile.get_child_count()):
			pile.get_child(i).visible = i < mini(count, 12)

func _building(pos: Vector3, index: int, side: int) -> void:
	var colors: Array[Color] = [Color("e4aa77"), Color("63b5b5"), Color("edc768"), Color("d98d8b")]
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = PI * 0.5 if side == -1 else -PI * 0.5
	add_child(root)
	var height: float = 5.8 + (index % 2) * 1.8
	MarketArt.box(root, Vector3(0, height * 0.5, 0), Vector3(7.3, height, 4), colors[index], true)
	MarketArt.box(root, Vector3(0, height, 0), Vector3(7.6, 0.3, 4.4), Color("bb6b4c"))
	MarketArt.box(root, Vector3(0, 0.3, 2.04), Vector3(7.3, 0.6, 0.1), Color("eeddbd"))
	for x in [-2.3, 0, 2.3]:
		MarketArt.box(root, Vector3(x, 4.3, 2.06), Vector3(1.4, 1.6, 0.1), Color("f9e9c9"))
		MarketArt.box(root, Vector3(x, 4.3, 2.13), Vector3(1.12, 1.3, 0.05), Color("406b7a"))
		MarketArt.box(root, Vector3(x, 4.3, 2.18), Vector3(0.08, 1.3, 0.04), Color("f9e9c9"))
	MarketArt.box(root, Vector3(0, 1.3, 2.06), Vector3(1.5, 2.6, 0.1), Color("42696a"))
	MarketArt.sphere(root, Vector3(0.5, 1.2, 2.16), 0.055, Color("f4d270"))
	var names: Array[String] = ["PADARIA BOM DIA", "BAR DO ZÉ", "MERCADINHO", "CASA DA DONA CIDA"]
	MarketArt.box(root, Vector3(0, 3, 2.16), Vector3(6.8, 0.6, 0.14), Color("355b58"))
	MarketArt.label(root, names[index], Vector3(0, 3, 2.25), 42, Color("fff0c9"))

func _decorative_stall(pos: Vector3, index: int, side: int) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = PI * 0.5 if side == -1 else -PI * 0.5
	add_child(root)
	var colors: Array[Color] = [Color("5ca56a"), Color("d95c66"), Color("589ab5")]
	MarketArt.canopy(root, 4.4, 2.8, colors[index])
	MarketArt.box(root, Vector3(0, 0.55, 0.4), Vector3(3.9, 1.1, 1), colors[index], true)
	MarketArt.box(root, Vector3(0, 1.12, 0.4), Vector3(4.1, 0.1, 1.2), Color("deb17c"))
	var names: Array[String] = ["HORTA DA TIA", "FRUTA BONITA", "PASTEL & CALDO"]
	MarketArt.label(root, names[index], Vector3(0, 2.8, 1.46), 39, Color("fff1cc"))
	for x in [-1.3, 0, 1.3]:
		MarketArt.crate(root, Vector3(x, 1.17, 0.4), Vector3(1.13, 0.25, 0.8))
		for j in range(6):
			var p := Vector3(x + (j % 3 - 1) * 0.28, 1.38, 0.4 + (j / 3 - 0.5) * 0.3)
			if index == 0:
				MarketArt.sphere(root, p, 0.18, Color("83ae52"))
			elif index == 1:
				MarketArt.fruit(root, FruitCatalog.IDS[int(x + 1.3) % 3], p)
			else:
				MarketArt.box(root, p, Vector3(0.22, 0.09, 0.24), Color("edbc66"))
	var vendor := MarketArt.humanoid(root, Color("f4ead2"), Color("ac7752"))
	vendor.position = Vector3(0.2, 0, -0.8)
	MarketArt.cylinder(vendor, Vector3(0, 2, 0), 0.36, 0.09, Color("e9ce8d"))
	MarketArt.crate(root, Vector3(2.25, 0, 0), Vector3(0.65, 0.7, 0.65))

func _tree(pos: Vector3) -> void:
	MarketArt.box(self, pos + Vector3(0, 0.13, 0), Vector3(1.3, 0.26, 1.3), Color("c49a70"), true)
	MarketArt.cylinder(self, pos + Vector3(0, 1.45, 0), 0.17, 2.9, Color("876645"))
	MarketArt.sphere(self, pos + Vector3(0, 3.3, 0), 1.15, Color("639768"), Vector3(1, 1.2, 1))
	MarketArt.sphere(self, pos + Vector3(0.6, 3, 0.2), 0.8, Color("80ad62"))

func _lamp(pos: Vector3) -> void:
	MarketArt.cylinder(self, pos + Vector3(0, 2.15, 0), 0.065, 4.3, Color("395c5b"))
	MarketArt.box(self, pos + Vector3(0, 4.25, 0), Vector3(0.45, 0.16, 0.45), Color("eae4bb"))
	MarketArt.box(self, pos + Vector3(0, 4.04, 0), Vector3(0.25, 0.35, 0.25), Color("fff3b5"))

func _bunting() -> void:
	var colors: Array[Color] = [Color("ef785a"), Color("f6d45b"), Color("68ac95"), Color("71b2cf")]
	for z in [-4, -12, -21]:
		MarketArt.box(self, Vector3(0, 4.8, z), Vector3(22, 0.025, 0.025), Color("675c47"))
		for i in range(24):
			var vertices := PackedVector3Array([Vector3(-0.3, 0, 0), Vector3(0, -0.55, 0), Vector3(0.3, 0, 0)])
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD])
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var flag := MarketArt.mesh_node(self, mesh, Vector3(-10.5 + i * 0.9, 4.79, z), colors[i % 4])
			var mat := MarketArt.material(colors[i % 4]).duplicate() as StandardMaterial3D
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			flag.material_override = mat
