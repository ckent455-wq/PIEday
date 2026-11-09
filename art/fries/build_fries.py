"""Build the diner serving basket and the frozen portion for the fryer."""

from math import cos, pi, sin, sqrt
from pathlib import Path
from random import Random

import bpy
from mathutils import Euler, Vector


ART = Path(__file__).resolve().parent
ASSETS = ART.parents[1] / "assets" / "fries"
ASSETS.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, color, roughness):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = result.diffuse_color
    shader.inputs["Roughness"].default_value = roughness
    return result


def mesh_object(name, vertices, faces, materials, indices=None):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for entry in materials:
        mesh.materials.append(entry)
    if indices is not None:
        for face, index in zip(mesh.polygons, indices):
            face.material_index = index
    return obj


red = material("Tomato red basket", (0.44, 0.029, 0.018), 0.37)
ivory = material("Wax paper", (0.81, 0.75, 0.60), 0.78)
printed = material("Red checker print", (0.51, 0.062, 0.039), 0.78)
gold = [
    material("Fry gold", (0.91, 0.54, 0.11), 0.71),
    material("Potato yellow", (0.94, 0.67, 0.22), 0.74),
    material("Toasted edges", (0.67, 0.32, 0.062), 0.73),
    material("Browned bevel outline", (0.54, 0.26, 0.047), 0.76),
]
frozen = [
    material("Pale frozen potato", (0.84, 0.76, 0.54), 0.87),
    material("Frozen cut faces", (0.92, 0.85, 0.65), 0.88),
    material("Frozen edges", (0.70, 0.63, 0.45), 0.86),
]


def serving_basket():
    # Cross sections of the lip, open lattice and solid base.
    sections = [
        (0.081, 0.051, 0.000), (0.087, 0.056, 0.004),
        (0.090, 0.059, 0.010), (0.100, 0.067, 0.039),
        (0.108, 0.073, 0.043), (0.110, 0.075, 0.049),
        (0.105, 0.070, 0.053), (0.098, 0.063, 0.049),
        (0.096, 0.062, 0.039), (0.086, 0.055, 0.010),
        (0.082, 0.050, 0.006),
    ]
    segments = 48
    vertices = []
    for row, (rx, ry, height) in enumerate(sections):
        for i in range(segments):
            # Offset the tops of the ribs for the slanted slots of a diner basket.
            angle = 2 * pi * (i + (0.65 if 3 <= row <= 8 else 0)) / segments
            vertices.append((rx * cos(angle), ry * sin(angle), height))
    faces = [tuple(reversed(range(segments)))]
    for row in range(len(sections) - 1):
        for i in range(segments):
            if row in (2, 8) and i % 2:
                continue
            j = (i + 1) % segments
            faces.append((row * segments + i, row * segments + j,
                          (row + 1) * segments + j, (row + 1) * segments + i))
    for i in range(0, segments, 2):
        j = i + 1
        faces.extend([
            (2 * segments + i, 3 * segments + i, 8 * segments + i, 9 * segments + i),
            (2 * segments + j, 9 * segments + j, 8 * segments + j, 3 * segments + j),
        ])
    faces.append(tuple(range(10 * segments, 11 * segments)))
    return mesh_object("Oval lattice basket", vertices, faces, [red])


def liner():
    columns, rows = 14, 10
    vertices = []
    for row in range(rows + 1):
        v = 2 * row / rows - 1
        for col in range(columns + 1):
            u = 2 * col / columns - 1
            x = 0.100 * u * sqrt(1 - v * v / 2)
            y = 0.065 * v * sqrt(1 - u * u / 2)
            edge = max(abs(u), abs(v))
            height = 0.013 + 0.036 * edge ** 5
            height += edge ** 4 * (0.0025 * sin(row * 2.3 + col * 1.7))
            vertices.append((x, y, height))
    faces, colors = [], []
    for row in range(rows):
        for col in range(columns):
            i = row * (columns + 1) + col
            faces.append((i, i + 1, i + columns + 2, i + columns + 1))
            colors.append((row + col) % 2)
    return mesh_object("Folded checker paper", vertices, faces, [ivory, printed], colors)


def fries(name, is_frozen=False):
    rng = Random(182)
    vertices, faces, colors = [], [], []
    portions = (12, 11, 9) if is_frozen else (17, 15, 12)
    spread_x, spread_y = (0.065, 0.037) if is_frozen else (0.073, 0.045)
    for layer, count in enumerate(portions):
        for _ in range(count):
            angle = rng.uniform(-pi, pi)
            distance = sqrt(rng.random())
            x = cos(angle) * distance * (spread_x - 0.013 * layer)
            y = sin(angle) * distance * (spread_y - 0.005 * layer)
            center = Vector((x, y, (0.008 if is_frozen else 0.027) + layer * 0.014))
            rotation = Euler((rng.uniform(-0.3, 0.3), rng.uniform(-0.30, 0.30),
                              angle + rng.uniform(-1.5, 1.5))).to_matrix()
            length = rng.uniform(0.052, 0.101)
            half_width = rng.uniform(0.004, 0.006)
            if not is_frozen:
                # Keep the ends inside the narrower lower part of the basket.
                tip = rotation @ Vector((length * 0.5, 0, 0))
                radius_x, radius_y = 0.082 + layer * 0.005, 0.048 + layer * 0.004
                extent = max(
                    sqrt(((center.x + side * tip.x) / radius_x) ** 2
                         + ((center.y + side * tip.y) / radius_y) ** 2)
                    for side in (-1, 1)
                )
                shrink = 1 / max(1, extent)
                center.x *= shrink
                center.y *= shrink
                length *= shrink
            bevel = 0.72 if is_frozen else 0.62
            outline = [(1, bevel), (bevel, 1), (-bevel, 1), (-1, bevel),
                       (-1, -bevel), (-bevel, -1), (bevel, -1), (1, -bevel)]
            face_colors = (1, 1, 1, 2, 0, 2, 0, 2) if is_frozen else (3, 1, 3, 0, 3, 2, 3, 0)
            start = len(vertices)
            for section, taper, bend in [(-0.5, 0.83, 0), (-0.04, 1, 0.002), (0.5, 0.78, -0.001)]:
                for a, b in outline:
                    point = Vector((length * section, a * half_width * taper + bend,
                                    b * half_width * taper))
                    vertices.append(center + rotation @ point)
            for ring in range(2):
                for side in range(8):
                    a = start + ring * 8 + side
                    b = start + ring * 8 + (side + 1) % 8
                    faces.append((a, b, b + 8, a + 8))
                    colors.append(face_colors[side])
            faces.extend([tuple(reversed(range(start, start + 8))),
                          tuple(range(start + 16, start + 24))])
            colors.extend([0, 1])
    return mesh_object(name, vertices, faces, frozen if is_frozen else gold, colors)


def export(filename, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(ASSETS / filename), export_format="GLB", use_selection=True)


basket = serving_basket()
paper = liner()
cooked = fries("Hand-cut golden fries")
raw = fries("Frozen fries for the fryer", is_frozen=True)
export("serving_basket.glb", [basket, paper, cooked])
export("frozen_fries.glb", [raw])
raw.location.x = 0.30
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ART / "fries_and_basket.blend"))
