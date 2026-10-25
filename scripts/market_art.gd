class_name MarketArt
extends RefCounted

static var materials: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.9
		materials[key] = mat
	return materials[key]

static func mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = pos
	parent.add_child(node)
	return node

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := mesh_node(parent, mesh, pos, color)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
		node.add_child(body)
	return node

static func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, stretch: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var node := mesh_node(parent, mesh, pos, color)
	node.scale = stretch
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return mesh_node(parent, mesh, pos, color)

static func label(parent: Node3D, text: String, pos: Vector3, size: int = 40, color: Color = Color.WHITE) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.position = pos
	node.font_size = size
	node.pixel_size = 0.006
	node.modulate = color
	node.outline_size = 5
	node.outline_modulate = Color("263a3c")
	parent.add_child(node)
	return node

static func fruit(parent: Node3D, id: String, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var color: Color = FruitCatalog.ITEMS[id]["color"]
	if id == "banana":
		for i in range(3):
			var banana := sphere(root, Vector3((i - 1) * 0.085, 0, 0), 0.1, color, Vector3(0.55, 0.65, 2.0))
			banana.rotation.y = (i - 1) * 0.23
		box(root, Vector3(0, 0.01, -0.18), Vector3(0.07, 0.06, 0.06), Color("745c35"))
	else:
		sphere(root, Vector3.ZERO, 0.13, color)
		cylinder(root, Vector3(0, 0.14, 0), 0.018, 0.09, Color("79543c"))
		if id == "maca":
			var leaf := sphere(root, Vector3(0.055, 0.17, 0), 0.05, Color("568648"), Vector3(1.5, 0.25, 0.7))
			leaf.rotation.z = 0.3
	return root

static func crate(parent: Node3D, pos: Vector3, size: Vector3 = Vector3(1.3, 0.36, 0.85)) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	box(root, Vector3(0, 0.035, 0), Vector3(size.x, 0.07, size.z), Color("956438"))
	for y in [size.y * 0.3, size.y * 0.78]:
		for z in [-size.z * 0.5, size.z * 0.5]:
			box(root, Vector3(0, y, z), Vector3(size.x, size.y * 0.3, 0.06), Color("c49155"))
		for x in [-size.x * 0.5, size.x * 0.5]:
			box(root, Vector3(x, y, 0), Vector3(0.06, size.y * 0.3, size.z), Color("bd864b"))
	return root

static func canopy(parent: Node3D, width: float, depth: float, color: Color) -> void:
	for x in [-width * 0.48, width * 0.48]:
		for z in [-depth * 0.46, depth * 0.46]:
			box(parent, Vector3(x, 1.5, z), Vector3(0.09, 3, 0.09), Color("eee4c9"), true)
	var stripes: int = int(width / 0.48)
	for i in range(stripes):
		var tint: Color = color if i % 2 == 0 else Color("fff3d4")
		var x: float = -width * 0.5 + (i + 0.5) * width / stripes
		for side in [-1, 1]:
			var roof := box(parent, Vector3(x, 3.13, side * depth * 0.25), Vector3(width / stripes + 0.01, 0.07, depth * 0.54), tint)
			roof.rotation.x = side * 0.22
			box(parent, Vector3(x, 2.86, side * depth * 0.5), Vector3(width / stripes + 0.01, 0.28, 0.06), tint)

static func humanoid(parent: Node3D, shirt: Color, skin: Color) -> Node3D:
	var body := Node3D.new()
	parent.add_child(body)
	box(body, Vector3(0, 1.13, 0), Vector3(0.55, 0.64, 0.31), shirt)
	for side in [-1, 1]:
		var leg := box(body, Vector3(side * 0.16, 0.43, 0), Vector3(0.2, 0.73, 0.24), Color("344c64"))
		leg.name = "LegL" if side == -1 else "LegR"
		box(leg, Vector3(0, -0.33, 0.07), Vector3(0.23, 0.13, 0.38), Color("f4e5ca"))
		var arm := box(body, Vector3(side * 0.37, 1.08, 0), Vector3(0.18, 0.56, 0.22), skin)
		arm.rotation.z = side * 0.12
		box(body, Vector3(side * 0.33, 1.31, 0), Vector3(0.23, 0.24, 0.28), shirt)
	sphere(body, Vector3(0, 1.69, 0), 0.265, skin, Vector3(0.88, 1.08, 0.92))
	sphere(body, Vector3(0, 1.85, -0.04), 0.24, Color("45382f"), Vector3(1, 0.65, 0.85))
	for side in [-1, 1]:
		box(body, Vector3(side * 0.085, 1.72, 0.223), Vector3(0.035, 0.045, 0.025), Color("293c3b"))
	box(body, Vector3(0, 1.59, 0.232), Vector3(0.1, 0.025, 0.02), Color("fff1d4"))
	return body
