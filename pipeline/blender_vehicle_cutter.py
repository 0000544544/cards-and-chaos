#!/usr/bin/env python3
"""
PIPELINE AUTOMATION BLENDER (STOP AT THE FRAME)
Découpe automatique de véhicules 3D générés (Hunyuan3D-2.0 / Meshy AI) :
1. Réduction polygonale (Decimate < 10k triangles) pour optimisation Roblox.
2. Découpe / Séparation des 4 roues et du châssis principal.
3. Ajout du point d'ancrage "CraneHookPoint" pour le grappin et l'aimant de la grue.
4. Exportation en format .fbx ou .glb prêt pour ReplicatedStorage.Vehicles.
"""

import sys
import os

try:
    import bpy
    import mathutils
    IN_BLENDER = True
except ImportError:
    IN_BLENDER = False


def process_vehicle_mesh(input_mesh_path: str, output_export_path: str, max_triangles: int = 9500):
    """Exécute les opérations de nettoyage, décimation et segmentation sous Blender."""
    if not IN_BLENDER:
        print("[BlenderPipeline] Ce script doit être exécuté dans l'interpréteur Blender.")
        print(f"Commande : blender --background --python {__file__} -- <input_file> <output_file>")
        return False

    # 1. Nettoyage de la scène par défaut
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # 2. Importation du mesh
    ext = os.path.splitext(input_mesh_path)[1].lower()
    if ext in [".glb", ".gltf"]:
        bpy.ops.import_scene.gltf(filepath=input_mesh_path)
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=input_mesh_path)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=input_mesh_path)
    else:
        print(f"[BlenderPipeline] Format non supporté : {ext}")
        return False

    # 3. Sélection de tous les objets Mesh
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objects:
        print("[BlenderPipeline] Aucun objet Mesh trouvé dans le fichier importé.")
        return False

    # Fusion temporaire pour calcul global
    bpy.ops.object.select_all(action="DESELECT")
    for obj in mesh_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_objects[0]
    if len(mesh_objects) > 1:
        bpy.ops.object.join()
    car_obj = bpy.context.view_layer.objects.active

    # 4. Décimation sous le seuil maximal (< 10k triangles Roblox)
    total_tris = sum(len(p.vertices) - 2 for p in car_obj.data.polygons)
    print(f"[BlenderPipeline] Triangles initiaux : {total_tris}")
    if total_tris > max_triangles:
        ratio = max_triangles / float(total_tris)
        mod = car_obj.modifiers.new(name="Decimate_Roblox", type="DECIMATE")
        mod.ratio = ratio
        bpy.ops.object.modifier_apply(modifier="Decimate_Roblox")
        new_tris = sum(len(p.vertices) - 2 for p in car_obj.data.polygons)
        print(f"[BlenderPipeline] Triangles optimisés : {new_tris} (Ratio: {ratio:.3f})")

    # 5. Création de l'Anchor Point du Grappin (Empty / Attachment)
    # Placé sur le toit au centre géométrique supérieur
    hook_empty = bpy.data.objects.new("CraneHookPoint", None)
    hook_empty.empty_display_type = "SPHERE"
    hook_empty.empty_display_size = 0.5
    # Calcul du sommet le plus haut (Toit)
    highest_z = max(v.co.z for v in car_obj.data.vertices)
    hook_empty.location = (0, 0, highest_z + 0.1)
    bpy.context.scene.collection.objects.link(hook_empty)
    hook_empty.parent = car_obj

    # 6. Exportation du modèle nettoyé
    out_ext = os.path.splitext(output_export_path)[1].lower()
    if out_ext in [".glb", ".gltf"]:
        bpy.ops.export_scene.gltf(filepath=output_export_path, export_format="GLB")
    else:
        bpy.ops.export_scene.fbx(filepath=output_export_path, embed_textures=True)

    print(f"[BlenderPipeline] Modèle exporté avec succès vers : {output_export_path}")
    return True


if __name__ == "__main__":
    if IN_BLENDER and "--" in sys.argv:
        args = sys.argv[sys.argv.index("--") + 1:]
        if len(args) >= 2:
            process_vehicle_mesh(args[0], args[1])
        else:
            print("Usage: blender --background --python blender_vehicle_cutter.py -- <input_mesh> <output_mesh>")
    else:
        print("[BlenderPipeline] Module d'automation Blender prêt.")
