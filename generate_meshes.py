#!/usr/bin/env python3
"""
STOP AT THE FRAME - 3D MESH & TEXTURE PIPELINE (Roblox FileMesh v2.00)
======================================================================
Convertit les modèles 3D .glb du dossier pipeline/ :
  - lightning_mcqueen_roblox.glb (issu de lightning_mcqueen_smooth.glb)
  - mater_roblox.glb             (issu de mater_smooth.glb)
  - real_truck_chassis.glb       (pickup 3D avec roues séparées)
Et génère des maillages 3D lisses (.mesh v2.00) + textures UV (.png 512x512) pour :
  - satf_supra.mesh / satf_supra.png          (JDM Drift Supra Widebody 3D)
  - satf_police.mesh / satf_police.png        (Police V8 Interceptor 3D)
  - satf_hyperion.mesh / satf_hyperion.png    (Hyperion JetCar 3D)
  - satf_palm_tree.mesh / satf_palm_tree.png  (Palmier tropical 3D courbé)
  - satf_harbor_crane.mesh / satf_crane.png   (Grue portuaire en treillis 3D)
  - satf_magnet_claw.mesh                     (Pince électro-aimant 3D)
  - satf_yacht.mesh / satf_yacht.png          (Yacht / Bateau de plaisance 3D)
  - satf_rock.mesh / satf_rock.png            (Rocher côtier tropical 3D)

Déploie automatiquement tous les fichiers dans :
  - %LOCALAPPDATA%/Roblox/Versions/*/content/meshes/   -> rbxasset://meshes/satf_*.mesh
  - %LOCALAPPDATA%/Roblox/Versions/*/content/textures/ -> rbxasset://textures/satf_*.png
  - ./meshes/ et ./textures/ dans le dépôt
"""

import os
import io
import json
import math
import glob
import shutil
import struct
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PIPELINE_DIR = os.path.join(BASE_DIR, "pipeline")
OUT_MESH_DIR = os.path.join(BASE_DIR, "meshes")
OUT_TEX_DIR = os.path.join(BASE_DIR, "textures")

os.makedirs(OUT_MESH_DIR, exist_ok=True)
os.makedirs(OUT_TEX_DIR, exist_ok=True)


# ==============================================================================
# 1. WRITER ROBLOX .MESH (VERSION 2.00 BINAIRE)
# ==============================================================================
def write_roblox_mesh_v2(filepath: str, positions: np.ndarray, normals: np.ndarray, uvs: np.ndarray, faces: np.ndarray):
    """
    Écrit un fichier binaire Roblox .mesh 'version 2.00'.
    positions : (N, 3) float32
    normals   : (N, 3) float32
    uvs       : (N, 2) float32
    faces     : (M, 3) uint32 (0-indexed triangles)
    """
    num_verts = len(positions)
    num_faces = len(faces)
    assert len(normals) == num_verts and len(uvs) == num_verts

    vertex_dtype = np.dtype([
        ("px", "<f4"), ("py", "<f4"), ("pz", "<f4"),
        ("nx", "<f4"), ("ny", "<f4"), ("nz", "<f4"),
        ("tu", "<f4"), ("tv", "<f4"), ("tw", "<f4"),
    ])
    v_arr = np.zeros(num_verts, dtype=vertex_dtype)
    v_arr["px"] = positions[:, 0]
    v_arr["py"] = positions[:, 1]
    v_arr["pz"] = positions[:, 2]
    v_arr["nx"] = normals[:, 0]
    v_arr["ny"] = normals[:, 1]
    v_arr["nz"] = normals[:, 2]
    v_arr["tu"] = uvs[:, 0]
    v_arr["tv"] = uvs[:, 1]
    v_arr["tw"] = 0.0

    f_arr = np.asarray(faces, dtype="<u4").reshape((-1, 3))

    with open(filepath, "wb") as f:
        f.write(b"version 2.00\n")
        # sizeof_MeshHeader=12 (uint16), sizeof_Vertex=36 (uint8), sizeof_Face=12 (uint8), numVerts (uint32), numFaces (uint32)
        f.write(struct.pack("<HBBII", 12, 36, 12, num_verts, num_faces))
        f.write(v_arr.tobytes())
        f.write(f_arr.tobytes())


def compute_smooth_normals(positions: np.ndarray, faces: np.ndarray) -> np.ndarray:
    """Calcule des normales lissées par sommet à partir des faces."""
    norms = np.zeros_like(positions, dtype=np.float64)
    p0 = positions[faces[:, 0]].astype(np.float64)
    p1 = positions[faces[:, 1]].astype(np.float64)
    p2 = positions[faces[:, 2]].astype(np.float64)
    fn = np.cross(p1 - p0, p2 - p0)
    np.add.at(norms, faces[:, 0], fn)
    np.add.at(norms, faces[:, 1], fn)
    np.add.at(norms, faces[:, 2], fn)
    lens = np.linalg.norm(norms, axis=1, keepdims=True)
    lens[lens < 1e-8] = 1.0
    return (norms / lens).astype(np.float32)


# ==============================================================================
# 2. LECTEUR GLB STANDARD (glTF 2.0)
# ==============================================================================
def parse_glb(glb_path: str):
    with open(glb_path, "rb") as f:
        data = f.read()
    magic, version, total_len = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, f"Invalid GLB magic in {glb_path}"
    json_len, json_type = struct.unpack_from("<II", data, 12)
    gltf = json.loads(data[20:20 + json_len].decode("utf-8"))
    bin_offset = 20 + json_len
    bin_len, bin_type = struct.unpack_from("<II", data, bin_offset)
    bin_data = data[bin_offset + 8:bin_offset + 8 + bin_len]
    return gltf, bin_data


def read_glb_accessor(gltf, bin_data: bytes, acc_idx: int) -> np.ndarray:
    acc = gltf["accessors"][acc_idx]
    bv = gltf["bufferViews"][acc["bufferView"]]
    offset = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    count = acc["count"]
    comp_type = acc["componentType"]
    acc_type = acc["type"]
    num_comp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[acc_type]
    dtype = {
        5120: np.int8,
        5121: np.uint8,
        5122: np.int16,
        5123: np.uint16,
        5125: np.uint32,
        5126: np.float32,
    }[comp_type]
    item_bytes = np.dtype(dtype).itemsize * num_comp
    stride = bv.get("byteStride", item_bytes)
    raw = np.frombuffer(bin_data, dtype=np.uint8, count=count * stride, offset=offset)
    raw = raw.reshape((count, stride))[:, :item_bytes]
    arr = raw.view(dtype).reshape((count, num_comp)).copy()
    if acc.get("normalized", False):
        arr = arr.astype(np.float32)
        if comp_type == 5120:
            arr = np.maximum(arr / 127.0, -1.0)
        elif comp_type == 5121:
            arr = arr / 255.0
        elif comp_type == 5122:
            arr = np.maximum(arr / 32767.0, -1.0)
        elif comp_type == 5123:
            arr = arr / 65535.0
    return arr


def extract_glb_image(gltf, bin_data: bytes, mat_idx: int):
    if "materials" not in gltf or mat_idx >= len(gltf["materials"]):
        return None
    mat = gltf["materials"][mat_idx]
    pbr = mat.get("pbrMetallicRoughness", {})
    tex_info = pbr.get("baseColorTexture")
    if tex_info is None:
        return None
    tex = gltf["textures"][tex_info["index"]]
    src_idx = tex.get("source", 0)
    img_def = gltf["images"][src_idx]
    bv = gltf["bufferViews"][img_def["bufferView"]]
    offset = bv.get("byteOffset", 0)
    img_bytes = bin_data[offset:offset + bv["byteLength"]]
    return Image.open(io.BytesIO(img_bytes)).convert("RGBA")


def orient_and_scale_car_vertices(pos: np.ndarray, norm: np.ndarray, target_length: float = 12.0, bottom_y: float = -2.0, ref_bounds=None):
    """
    Aligne un véhicule GLB (+Z avant, +Y haut) vers la convention Roblox (-Z avant = LookVector, +Y haut).
    Rotation de 180° autour de Y : (x, y, z) -> (-x, y, -z) (préserve l'orientation CCW des triangles).
    Centre X et Z, place le bas des roues à Y = bottom_y, et met la longueur totale à target_length studs.
    """
    p = pos.copy().astype(np.float32)
    n = norm.copy().astype(np.float32)
    # 180 deg around Y so front (+Z in GLB) points toward -Z in Roblox
    p[:, 0] = -p[:, 0]
    p[:, 2] = -p[:, 2]
    n[:, 0] = -n[:, 0]
    n[:, 2] = -n[:, 2]

    if ref_bounds is None:
        min_pt = p.min(axis=0)
        max_pt = p.max(axis=0)
    else:
        min_pt, max_pt = ref_bounds

    cx = 0.5 * (min_pt[0] + max_pt[0])
    cz = 0.5 * (min_pt[2] + max_pt[2])
    min_y = min_pt[1]
    length_z = max(max_pt[2] - min_pt[2], 1e-4)
    scale = target_length / length_z

    p[:, 0] = (p[:, 0] - cx) * scale
    p[:, 1] = (p[:, 1] - min_y) * scale + bottom_y
    p[:, 2] = (p[:, 2] - cz) * scale

    lens = np.linalg.norm(n, axis=1, keepdims=True)
    lens[lens < 1e-8] = 1.0
    n = n / lens
    return p, n


# ==============================================================================
# 3. CONVERSION DES 3 MODÈLES .GLB RÉELS (MCQUEEN, MATER, PICKUP RALLY)
# ==============================================================================
def build_glb_cars():
    # A. FLASH MCQUEEN (lightning_mcqueen_roblox.glb)
    mc_path = os.path.join(PIPELINE_DIR, "lightning_mcqueen_roblox.glb")
    if os.path.exists(mc_path):
        gltf, bin_data = parse_glb(mc_path)
        prim = gltf["meshes"][0]["primitives"][0]
        pos = read_glb_accessor(gltf, bin_data, prim["attributes"]["POSITION"]).astype(np.float32)
        norm = read_glb_accessor(gltf, bin_data, prim["attributes"]["NORMAL"]).astype(np.float32)
        uv = read_glb_accessor(gltf, bin_data, prim["attributes"]["TEXCOORD_0"]).astype(np.float32)
        faces = read_glb_accessor(gltf, bin_data, prim["indices"]).reshape((-1, 3)).astype(np.uint32)

        pos, norm = orient_and_scale_car_vertices(pos, norm, target_length=12.2, bottom_y=-2.0)
        write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_mcqueen.mesh"), pos, norm, uv, faces)

        img = extract_glb_image(gltf, bin_data, prim.get("material", 0))
        if img is not None:
            img.save(os.path.join(OUT_TEX_DIR, "satf_mcqueen.png"))
        print(f"  [OK] Flash McQueen 3D : {len(pos)} sommets, {len(faces)} triangles")

    # B. MARTIN / TOW MATER (mater_roblox.glb - 7 submeshes)
    mater_path = os.path.join(PIPELINE_DIR, "mater_roblox.glb")
    if os.path.exists(mater_path):
        gltf, bin_data = parse_glb(mater_path)
        raw_subs = []
        all_pts = []
        for m_idx, mesh in enumerate(gltf["meshes"]):
            prim = mesh["primitives"][0]
            pos = read_glb_accessor(gltf, bin_data, prim["attributes"]["POSITION"]).astype(np.float32)
            norm = read_glb_accessor(gltf, bin_data, prim["attributes"]["NORMAL"]).astype(np.float32)
            uv = read_glb_accessor(gltf, bin_data, prim["attributes"]["TEXCOORD_0"]).astype(np.float32)
            faces = read_glb_accessor(gltf, bin_data, prim["indices"]).reshape((-1, 3)).astype(np.uint32)
            img = extract_glb_image(gltf, bin_data, prim.get("material", m_idx))
            # Flip X and Z for bounds calculation
            p_rot = pos.copy()
            p_rot[:, 0] = -p_rot[:, 0]
            p_rot[:, 2] = -p_rot[:, 2]
            all_pts.append(p_rot)
            raw_subs.append((pos, norm, uv, faces, img))

        stacked = np.vstack(all_pts)
        ref_bounds = (stacked.min(axis=0), stacked.max(axis=0))
        total_tris = 0
        for idx, (pos, norm, uv, faces, img) in enumerate(raw_subs):
            p_scaled, n_scaled = orient_and_scale_car_vertices(pos, norm, target_length=12.0, bottom_y=-2.0, ref_bounds=ref_bounds)
            write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, f"satf_mater_{idx}.mesh"), p_scaled, n_scaled, uv, faces)
            if img is not None:
                img.save(os.path.join(OUT_TEX_DIR, f"satf_mater_{idx}.png"))
            total_tris += len(faces)
        print(f"  [OK] Martin (Tow Mater) 3D : 7 sous-maillages, {total_tris} triangles")

    # C. PICKUP RALLY (real_truck_chassis.glb)
    truck_path = os.path.join(PIPELINE_DIR, "real_truck_chassis.glb")
    if os.path.exists(truck_path):
        gltf, bin_data = parse_glb(truck_path)
        # Assemble full truck (body + 4 wheels) into a single smooth mesh so it's super easy to use!
        # Let's check node translations in real_truck_chassis.glb
        nodes = gltf["nodes"]
        parents = {}
        for i, nd in enumerate(nodes):
            for c in nd.get("children", []):
                parents[c] = i

        def node_world_pos(idx):
            curr = idx
            t = np.zeros(3, dtype=np.float32)
            while curr is not None:
                nd = nodes[curr]
                if "translation" in nd:
                    t += np.array(nd["translation"], dtype=np.float32)
                curr = parents.get(curr, None)
            return t

        all_pos, all_norm, all_uv, all_faces = [], [], [], []
        v_offset = 0
        for n_idx, nd in enumerate(nodes):
            if "mesh" not in nd:
                continue
            t = node_world_pos(n_idx)
            mesh = gltf["meshes"][nd["mesh"]]
            for prim in mesh["primitives"]:
                pos = read_glb_accessor(gltf, bin_data, prim["attributes"]["POSITION"]).astype(np.float32) + t
                norm = read_glb_accessor(gltf, bin_data, prim["attributes"]["NORMAL"]).astype(np.float32)
                uv = read_glb_accessor(gltf, bin_data, prim["attributes"]["TEXCOORD_0"]).astype(np.float32)
                faces = read_glb_accessor(gltf, bin_data, prim["indices"]).reshape((-1, 3)).astype(np.uint32) + v_offset
                all_pos.append(pos)
                all_norm.append(norm)
                all_uv.append(uv)
                all_faces.append(faces)
                v_offset += len(pos)

        full_pos = np.vstack(all_pos)
        full_norm = np.vstack(all_norm)
        full_uv = np.vstack(all_uv)
        full_faces = np.vstack(all_faces)

        full_pos, full_norm = orient_and_scale_car_vertices(full_pos, full_norm, target_length=11.8, bottom_y=-2.0)
        write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_truck.mesh"), full_pos, full_norm, full_uv, full_faces)

        img = extract_glb_image(gltf, bin_data, 0)
        if img is not None:
            img.save(os.path.join(OUT_TEX_DIR, "satf_truck_colormap.png"))
            # Create a vibrant Rally Red/Gold edition of the colormap too
            arr = np.array(img).astype(np.float32)
            # Where green channel dominates (the green bodywork), shift hue to Rally Crimson Red!
            r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
            green_mask = (g > r * 1.15) & (g > b * 1.05) & (g > 60)
            arr[green_mask, 0] = np.clip(g[green_mask] * 1.35, 0, 255)
            arr[green_mask, 1] = np.clip(r[green_mask] * 0.45, 0, 255)
            arr[green_mask, 2] = np.clip(b[green_mask] * 0.45, 0, 255)
            Image.fromarray(arr.astype(np.uint8), "RGBA").save(os.path.join(OUT_TEX_DIR, "satf_rally_truck.png"))
        print(f"  [OK] Rally Pickup 3D (real_truck_chassis.glb) : {len(full_pos)} sommets, {len(full_faces)} triangles")


# ==============================================================================
# 4. GÉNÉRATEUR DE VOITURES DE SPORT 3D LISSES (SUPRA, POLICE, HYPERION)
# ==============================================================================
class MeshBuilder:
    def __init__(self):
        self.positions = []
        self.uvs = []
        self.faces = []

    def add_mesh(self, pos: np.ndarray, uv: np.ndarray, faces: np.ndarray):
        offset = sum(len(p) for p in self.positions)
        self.positions.append(pos.astype(np.float32))
        self.uvs.append(uv.astype(np.float32))
        self.faces.append((faces.astype(np.uint32) + offset))

    def build(self):
        pos = np.vstack(self.positions)
        uv = np.vstack(self.uvs)
        faces = np.vstack(self.faces)
        norms = compute_smooth_normals(pos, faces)
        return pos, norms, uv, faces


def build_lofted_sportscar_mesh(profile_fn, wheel_radius=1.05, wheel_width=0.95, wheel_z=(-3.75, 3.75), wheel_x=2.65, add_spoiler=False, add_lightbar=False, add_thrusters=False):
    """
    Crée un maillage 3D lisse et profilé de voiture de sport/hypercar avec :
    - Carrosserie loftée haute résolution (64 coupes Z x 40 points de section transversale)
    - Passages de roues galbés (Widebody fenders)
    - 4 roues 3D cylindriques lisses (32 facettes) intégrées avec jantes sculptées
    - Option aileron GT (Supra), gyrophare + pare-buffle (Police), ou tuyères + aileron requin (Hyperion)
    Atlas UV :
    - Carrosserie mappée en vue de dessus/côté sur u in [0.05, 0.95], v in [0.05, 0.72]
    - Roues mappées sur v in [0.78, 0.98], u in [0.05, 0.45]
    - Accessoires (aileron/gyrophare/tuyères) sur v in [0.78, 0.98], u in [0.55, 0.95]
    """
    mb = MeshBuilder()

    nz = 60
    nu = 40
    z_vals = np.linspace(-6.0, 6.0, nz)
    # Angle parameter around cross-section from bottom-left (-pi) through top (0) to bottom-right (+pi)
    theta_vals = np.linspace(-math.pi, math.pi, nu, endpoint=False)

    verts = []
    uvs = []
    for iz, z in enumerate(z_vals):
        half_w, bot_y, deck_y, cabin_w, cabin_y, fender_flare = profile_fn(z)
        v_coord = 0.06 + 0.64 * ((z + 6.0) / 12.0)

        for it, th in enumerate(theta_vals):
            # th in [-pi, pi]:
            # th = 0 is top center (x=0, y=cabin_y)
            # th = +-pi/2 is side waist (x=+-half_w, y=deck_y)
            # th = +-pi is bottom center (x=0, y=bot_y)
            s = math.sin(th)
            c = math.cos(th)

            # Smooth super-elliptical car cross-section
            sign_s = 1.0 if s >= 0 else -1.0
            abs_s = abs(s)

            if c >= 0:
                # Upper half: transitions smoothly from side fenders/deck into cabin dome
                # For |s| < cabin_ratio, rise up to cabin_y
                cabin_ratio = cabin_w / max(half_w, 1e-3)
                if abs_s <= cabin_ratio:
                    t_cab = abs_s / max(cabin_ratio, 1e-3)
                    # Smooth cosine dome for cabin roof + windshield
                    dome = 0.5 * (1.0 + math.cos(math.pi * t_cab))
                    y = deck_y + (cabin_y - deck_y) * (dome ** 0.75)
                    x = sign_s * (abs_s * half_w)
                else:
                    # Shoulder / fender deck
                    t_sh = (abs_s - cabin_ratio) / max(1.0 - cabin_ratio, 1e-3)
                    shoulder = math.sin((1.0 - t_sh) * math.pi * 0.5)
                    y = (bot_y + 0.55 * (deck_y - bot_y)) + 0.45 * (deck_y - bot_y) * (shoulder ** 0.5)
                    x = sign_s * (cabin_w + t_sh * (half_w - cabin_w) + fender_flare * math.sin(t_sh * math.pi))
            else:
                # Lower half: side rocker panels curving into flat aerodynamic undertray
                t_bot = -c  # 0 at side, 1 at bottom center
                x = sign_s * half_w * ((1.0 - t_bot ** 1.6))
                y = bot_y + (1.0 - t_bot ** 2.2) * 0.55 * (deck_y - bot_y)

            u_coord = 0.50 + 0.44 * (x / 3.4)
            verts.append([x, y, z])
            uvs.append([np.clip(u_coord, 0.02, 0.98), np.clip(v_coord, 0.02, 0.72)])

    verts = np.array(verts, dtype=np.float32)
    uvs = np.array(uvs, dtype=np.float32)

    faces = []
    for iz in range(nz - 1):
        for it in range(nu):
            it_next = (it + 1) % nu
            i00 = iz * nu + it
            i01 = iz * nu + it_next
            i10 = (iz + 1) * nu + it
            i11 = (iz + 1) * nu + it_next
            # Winding so normal points outward
            faces.append([i00, i10, i11])
            faces.append([i00, i11, i01])

    # Front & Rear caps
    front_center_idx = len(verts)
    verts = np.vstack([verts, [[0.0, -0.85, -6.05], [0.0, -0.65, 6.05]]])
    uvs = np.vstack([uvs, [[0.5, 0.05], [0.5, 0.71]]])
    rear_center_idx = front_center_idx + 1

    for it in range(nu):
        it_next = (it + 1) % nu
        faces.append([front_center_idx, it_next, it])
        b0 = (nz - 1) * nu + it
        b1 = (nz - 1) * nu + it_next
        faces.append([rear_center_idx, b0, b1])

    mb.add_mesh(verts, uvs, np.array(faces, dtype=np.uint32))

    # Add 4 smooth 3D wheels (32 radial segments)
    n_seg = 28
    for wx_sign in (-1.0, 1.0):
        for wz in wheel_z:
            wx = wx_sign * wheel_x
            wy = -2.0 + wheel_radius
            w_verts = []
            w_uvs = []
            w_faces = []
            x_in = wx - wx_sign * (wheel_width * 0.5)
            x_out = wx + wx_sign * (wheel_width * 0.5)
            for ix, x_val in enumerate([x_in, x_out]):
                for iseg in range(n_seg):
                    ang = (2.0 * math.pi * iseg) / n_seg
                    py = wy + wheel_radius * math.sin(ang)
                    pz = wz + wheel_radius * math.cos(ang)
                    w_verts.append([x_val, py, pz])
                    # Tire tread UV
                    w_uvs.append([0.10 + 0.15 * ix, 0.80 + 0.16 * (iseg / n_seg)])

            # Hub centers for inner and outer wheel faces
            c_in_idx = len(w_verts)
            w_verts.append([x_in, wy, wz])
            w_uvs.append([0.25, 0.88])
            c_out_idx = len(w_verts)
            w_verts.append([x_out + wx_sign * 0.06, wy, wz])
            w_uvs.append([0.35, 0.88])

            for iseg in range(n_seg):
                inext = (iseg + 1) % n_seg
                i0 = iseg
                i1 = inext
                o0 = n_seg + iseg
                o1 = n_seg + inext
                if wx_sign > 0:
                    w_faces.append([i0, i1, o1])
                    w_faces.append([i0, o1, o0])
                    w_faces.append([c_out_idx, o0, o1])
                    w_faces.append([c_in_idx, i1, i0])
                else:
                    w_faces.append([i0, o1, i1])
                    w_faces.append([i0, o0, o1])
                    w_faces.append([c_out_idx, o1, o0])
                    w_faces.append([c_in_idx, i0, i1])

            mb.add_mesh(np.array(w_verts, dtype=np.float32), np.array(w_uvs, dtype=np.float32), np.array(w_faces, dtype=np.uint32))

    # Optional GT Rear Spoiler (curved airfoil + 2 struts)
    if add_spoiler:
        sp_verts = []
        sp_uvs = []
        sp_faces = []
        nx_sp = 20
        xs = np.linspace(-3.15, 3.15, nx_sp)
        for x in xs:
            arch = 0.15 * math.cos((x / 3.15) * math.pi * 0.5)
            y_base = 1.15 + arch
            # Airfoil cross-section (4 points: front-top, rear-top, rear-bot, front-bot)
            pts = [
                [x, y_base + 0.08, 4.85],
                [x, y_base + 0.24, 5.75],
                [x, y_base + 0.14, 5.78],
                [x, y_base + 0.01, 4.88],
            ]
            for ip, pt in enumerate(pts):
                sp_verts.append(pt)
                sp_uvs.append([0.60 + 0.30 * ((x + 3.15) / 6.3), 0.80 + 0.04 * ip])
        for ix in range(nx_sp - 1):
            for ip in range(4):
                ip_n = (ip + 1) % 4
                a0 = ix * 4 + ip
                a1 = ix * 4 + ip_n
                b0 = (ix + 1) * 4 + ip
                b1 = (ix + 1) * 4 + ip_n
                sp_faces.append([a0, b0, b1])
                sp_faces.append([a0, b1, a1])
        mb.add_mesh(np.array(sp_verts, dtype=np.float32), np.array(sp_uvs, dtype=np.float32), np.array(sp_faces, dtype=np.uint32))

    # Optional Police Lightbar on roof + Front Bullbar
    if add_lightbar:
        lb_verts = []
        lb_uvs = []
        lb_faces = []
        xs = np.linspace(-1.85, 1.85, 14)
        for x in xs:
            u_lb = 0.58 + 0.36 * ((x + 1.85) / 3.7)
            pts = [
                [x, 1.72, -0.35],
                [x, 1.72,  0.35],
                [x, 1.48,  0.40],
                [x, 1.48, -0.40],
            ]
            for ip, pt in enumerate(pts):
                lb_verts.append(pt)
                lb_uvs.append([u_lb, 0.84 + 0.02 * ip])
        for ix in range(len(xs) - 1):
            for ip in range(4):
                ip_n = (ip + 1) % 4
                a0 = ix * 4 + ip
                a1 = ix * 4 + ip_n
                b0 = (ix + 1) * 4 + ip
                b1 = (ix + 1) * 4 + ip_n
                lb_faces.append([a0, b0, b1])
                lb_faces.append([a0, b1, a1])
        mb.add_mesh(np.array(lb_verts, dtype=np.float32), np.array(lb_uvs, dtype=np.float32), np.array(lb_faces, dtype=np.uint32))

    # Optional Dorsal Shark Fin + Twin Jet Afterburners (Hyperion)
    if add_thrusters:
        fin_verts = np.array([
            [0.0, 1.25, -0.2],
            [0.0, 1.85,  1.5],
            [0.0, 1.95,  5.6],
            [0.0, 0.70,  5.8],
            [-0.08, 0.75, 2.5],
            [ 0.08, 0.75, 2.5],
        ], dtype=np.float32)
        fin_uvs = np.array([
            [0.75, 0.82], [0.80, 0.85], [0.92, 0.85], [0.92, 0.92], [0.78, 0.90], [0.78, 0.90]
        ], dtype=np.float32)
        fin_faces = np.array([
            [0, 1, 4], [1, 2, 4], [2, 3, 4],
            [0, 5, 1], [1, 5, 2], [2, 5, 3],
        ], dtype=np.uint32)
        mb.add_mesh(fin_verts, fin_uvs, fin_faces)

    return mb.build()


def paint_car_livery_texture(body_rgb, stripe_rgb, accent_rgb, window_rgb=(20, 28, 38), mode="supra") -> Image.Image:
    """Génère une texture UV 512x512 haute précision pour une voiture de sport."""
    W, H = 512, 512
    img = Image.new("RGBA", (W, H), (*body_rgb, 255))
    draw = ImageDraw.Draw(img)

    # Subtle metallic gradient along body length (v from 0.05 to 0.72 -> y from 25 to 370)
    arr = np.array(img, dtype=np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    highlight = 1.0 + 0.14 * np.cos((xx - W * 0.5) / (W * 0.45) * math.pi)
    arr[:, :, 0] = np.clip(arr[:, :, 0] * highlight, 0, 255)
    arr[:, :, 1] = np.clip(arr[:, :, 1] * highlight, 0, 255)
    arr[:, :, 2] = np.clip(arr[:, :, 2] * highlight, 0, 255)
    img = Image.fromarray(arr.astype(np.uint8), "RGBA")
    draw = ImageDraw.Draw(img)

    if mode == "supra":
        # Twin racing stripes + carbon hood vents + JDM side graphics
        draw.rectangle([232, 20, 248, 370], fill=(*stripe_rgb, 255))
        draw.rectangle([264, 20, 280, 370], fill=(*stripe_rgb, 255))
        draw.rectangle([249, 20, 263, 370], fill=(*accent_rgb, 255))
        # Side diagonal drift livery
        draw.polygon([(45, 140), (135, 185), (135, 265), (45, 220)], fill=(*accent_rgb, 255))
        draw.polygon([(467, 140), (377, 185), (377, 265), (467, 220)], fill=(*accent_rgb, 255))
        # Carbon hood louvers
        for y_v in range(65, 115, 12):
            draw.rectangle([185, y_v, 220, y_v + 6], fill=(25, 28, 34, 255))
            draw.rectangle([292, y_v, 327, y_v + 6], fill=(25, 28, 34, 255))

    elif mode == "police":
        # Classic Highway Patrol Black & White doors (white cabin & doors from y=135 to 265)
        draw.rectangle([30, 130, 482, 265], fill=(242, 245, 250, 255))
        # Gold Interceptor Sheriff stripes along waist
        draw.rectangle([35, 122, 477, 132], fill=(*accent_rgb, 255))
        draw.rectangle([35, 265, 477, 275], fill=(*accent_rgb, 255))
        # Gold shield emblem on doors + hood
        draw.ellipse([75, 175, 125, 225], fill=(255, 205, 35, 255), outline=(30, 30, 35, 255), width=3)
        draw.ellipse([387, 175, 437, 225], fill=(255, 205, 35, 255), outline=(30, 30, 35, 255), width=3)
        # Roof Lightbar (mapped at u in [0.58, 0.94], v in [0.84, 0.92])
        draw.rectangle([295, 425, 385, 475], fill=(255, 25, 35, 255))   # Red half
        draw.rectangle([385, 425, 485, 475], fill=(20, 110, 255, 255))  # Blue half

    elif mode == "hyperion":
        # Futuristic Hypercar Carbon + Glowing Cyan & Solar Gold aero channels
        draw.polygon([(256, 25), (195, 145), (317, 145)], fill=(18, 22, 30, 255))
        # Glowing Cyan energy veins along fenders and spine
        draw.line([(256, 25), (256, 365)], fill=(*stripe_rgb, 255), width=8)
        draw.line([(165, 45), (120, 340)], fill=(*stripe_rgb, 255), width=7)
        draw.line([(347, 45), (392, 340)], fill=(*stripe_rgb, 255), width=7)
        draw.line([(155, 65), (110, 340)], fill=(*accent_rgb, 255), width=4)
        draw.line([(357, 65), (402, 340)], fill=(*accent_rgb, 255), width=4)

    # Tinted Windshield & Side/Rear Windows (central dome u in [0.27, 0.73], v in [0.24, 0.54])
    draw.rounded_rectangle([148, 122, 364, 278], radius=28, fill=(*window_rgb, 255), outline=(15, 18, 22, 255), width=5)
    # Roof center panel over cabin
    roof_rgb = body_rgb if mode != "police" else (242, 245, 250)
    draw.rounded_rectangle([172, 162, 340, 238], radius=16, fill=(*roof_rgb, 255))
    if mode == "supra":
        draw.rectangle([235, 162, 277, 238], fill=(*stripe_rgb, 255))

    # Front Grille & Glowing Headlights (v around 0.05..0.09 -> y around 22..48)
    draw.rounded_rectangle([155, 22, 357, 44], radius=6, fill=(14, 16, 20, 255))
    draw.rounded_rectangle([95, 24, 152, 46], radius=6, fill=(245, 252, 255, 255), outline=(0, 220, 255, 255), width=2)
    draw.rounded_rectangle([360, 24, 417, 46], radius=6, fill=(245, 252, 255, 255), outline=(0, 220, 255, 255), width=2)

    # Rear Diffuser & Glowing Red LED Taillights (v around 0.67..0.72 -> y around 342..368)
    draw.rounded_rectangle([90, 344, 422, 368], radius=6, fill=(18, 20, 24, 255))
    draw.rounded_rectangle([98, 346, 205, 362], radius=5, fill=(255, 25, 35, 255))
    draw.rounded_rectangle([307, 346, 414, 362], radius=5, fill=(255, 25, 35, 255))

    # Wheel & Tire UV region (v in [0.78, 0.98] -> y in [395, 505])
    draw.rectangle([0, 390, 285, 512], fill=(22, 24, 28, 255))
    # Metallic Rim hub around (u=0.35, v=0.88 -> x=179, y=450)
    draw.ellipse([139, 410, 219, 490], fill=(190, 198, 210, 255), outline=(90, 95, 105, 255), width=4)

    return img


def build_procedural_sportscars():
    # 1. DRIFT SUPRA GT (satf_supra.mesh + satf_supra.png)
    def supra_profile(z):
        # z in [-6, 6]
        wheel_arch = math.exp(-((abs(z) - 3.75) / 1.25) ** 2)
        half_w = 2.95 + 0.32 * wheel_arch - 0.25 * max(0.0, (-z - 4.2) / 1.8) ** 1.5
        bot_y = -1.45 + 0.22 * max(0.0, (abs(z) - 4.5) / 1.5)
        deck_y = -0.15 + 0.28 * ((z + 6.0) / 12.0) + 0.15 * wheel_arch
        # Fastback cabin between z = -2.3 and z = 3.6
        if -2.4 <= z <= 3.8:
            t_c = (z - (-2.4)) / 6.2
            cab_arch = math.sin(t_c * math.pi) ** 0.75
            cabin_y = deck_y + 1.38 * cab_arch
            cabin_w = 2.15 - 0.25 * (t_c ** 1.4)
        else:
            cabin_y = deck_y + 0.08
            cabin_w = 1.8
        return half_w, bot_y, deck_y, cabin_w, cabin_y, 0.14 * wheel_arch

    pos, norm, uv, faces = build_lofted_sportscar_mesh(supra_profile, add_spoiler=True)
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_supra.mesh"), pos, norm, uv, faces)
    paint_car_livery_texture(
        body_rgb=(20, 105, 245),
        stripe_rgb=(245, 250, 255),
        accent_rgb=(0, 235, 255),
        mode="supra"
    ).save(os.path.join(OUT_TEX_DIR, "satf_supra.png"))
    print(f"  [OK] Drift Supra GT 3D : {len(pos)} sommets, {len(faces)} triangles")

    # 2. POLICE V8 INTERCEPTOR (satf_police.mesh + satf_police.png)
    def police_profile(z):
        wheel_arch = math.exp(-((abs(z) - 3.75) / 1.2) ** 2)
        half_w = 3.05 + 0.22 * wheel_arch - 0.15 * max(0.0, (abs(z) - 4.8) / 1.2)
        bot_y = -1.42
        deck_y = -0.05 + 0.18 * ((z + 6.0) / 12.0) + 0.10 * wheel_arch
        if -2.2 <= z <= 3.2:
            t_c = (z - (-2.2)) / 5.4
            cab_arch = math.sin(t_c * math.pi) ** 0.65
            cabin_y = deck_y + 1.42 * cab_arch
            cabin_w = 2.25
        else:
            cabin_y = deck_y + 0.10
            cabin_w = 2.0
        return half_w, bot_y, deck_y, cabin_w, cabin_y, 0.10 * wheel_arch

    pos, norm, uv, faces = build_lofted_sportscar_mesh(police_profile, add_lightbar=True)
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_police.mesh"), pos, norm, uv, faces)
    paint_car_livery_texture(
        body_rgb=(20, 22, 28),
        stripe_rgb=(245, 248, 255),
        accent_rgb=(255, 200, 30),
        mode="police"
    ).save(os.path.join(OUT_TEX_DIR, "satf_police.png"))
    print(f"  [OK] Police V8 Interceptor 3D : {len(pos)} sommets, {len(faces)} triangles")

    # 3. HYPERION JETCAR (satf_hyperion.mesh + satf_hyperion.png)
    def hyperion_profile(z):
        wheel_arch = math.exp(-((abs(z) - 3.85) / 1.35) ** 2)
        waist_pinch = math.exp(-((z - 0.2) / 1.8) ** 2)
        half_w = 3.18 + 0.30 * wheel_arch - 0.35 * waist_pinch - 0.45 * max(0.0, (-z - 3.8) / 2.2) ** 1.4
        bot_y = -1.52 + 0.18 * max(0.0, (-z - 4.2) / 1.8)
        deck_y = -0.32 + 0.38 * wheel_arch + 0.22 * ((z + 6.0) / 12.0)
        if -2.8 <= z <= 2.8:
            t_c = (z - (-2.8)) / 5.6
            cab_arch = math.sin(t_c * math.pi) ** 0.8
            cabin_y = deck_y + 1.22 * cab_arch
            cabin_w = 1.75 * math.sin(t_c * math.pi) ** 0.35 + 0.3
        else:
            cabin_y = deck_y + 0.06
            cabin_w = 1.4
        return half_w, bot_y, deck_y, cabin_w, cabin_y, 0.18 * wheel_arch

    pos, norm, uv, faces = build_lofted_sportscar_mesh(hyperion_profile, add_spoiler=True, add_thrusters=True)
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_hyperion.mesh"), pos, norm, uv, faces)
    paint_car_livery_texture(
        body_rgb=(24, 28, 38),
        stripe_rgb=(0, 240, 255),
        accent_rgb=(255, 145, 15),
        window_rgb=(0, 185, 235),
        mode="hyperion"
    ).save(os.path.join(OUT_TEX_DIR, "satf_hyperion.png"))
    print(f"  [OK] Hyperion JetCar 3D : {len(pos)} sommets, {len(faces)} triangles")


# ==============================================================================
# 5. GÉNÉRATEUR DES ASSETS D'ENVIRONNEMENT 3D (PALMIER, GRUE, YACHT, ROCHER)
# ==============================================================================
def build_environment_meshes():
    # A. PALMIER TROPICAL 3D COURBÉ (satf_palm_tree.mesh + satf_palm_tree.png)
    mb = MeshBuilder()
    # Curved trunk from Y = 0 to Y = 17.5
    n_rings = 22
    n_rad = 12
    t_verts, t_uvs, t_faces = [], [], []
    for ir in range(n_rings):
        t = ir / (n_rings - 1)
        y = t * 17.5
        # Organic tropical curve in X and Z
        cx = 2.4 * math.sin(t * math.pi * 0.65)
        cz = 0.8 * (1.0 - math.cos(t * math.pi * 0.5))
        # Subtle coconut bark ridges
        r = (0.95 * (1.0 - 0.52 * t)) + 0.05 * math.sin(ir * math.pi)
        for k in range(n_rad):
            ang = (2.0 * math.pi * k) / n_rad
            px = cx + r * math.cos(ang)
            pz = cz + r * math.sin(ang)
            t_verts.append([px, y, pz])
            t_uvs.append([0.05 + 0.40 * (k / n_rad), 0.10 + 0.80 * t])
    for ir in range(n_rings - 1):
        for k in range(n_rad):
            kn = (k + 1) % n_rad
            a0 = ir * n_rad + k
            a1 = ir * n_rad + kn
            b0 = (ir + 1) * n_rad + k
            b1 = (ir + 1) * n_rad + kn
            t_faces.append([a0, a1, b1])
            t_faces.append([a0, b1, b0])
    mb.add_mesh(np.array(t_verts, dtype=np.float32), np.array(t_uvs, dtype=np.float32), np.array(t_faces, dtype=np.uint32))

    # 9 Gracefully arching 3D Palm Fronds at crown (2.4, 17.4, 0.8)
    crown = np.array([2.4, 17.4, 0.8], dtype=np.float32)
    n_fronds = 9
    n_seg_f = 12
    for ifr in range(n_fronds):
        yaw = (2.0 * math.pi * ifr) / n_fronds + 0.2 * (ifr % 2)
        pitch_up = 0.42 if (ifr % 2 == 0) else 0.22
        length = 8.8 if (ifr % 2 == 0) else 7.6
        f_verts, f_uvs, f_faces = [], [], []
        dx, dz = math.cos(yaw), math.sin(yaw)
        rx, rz = -dz, dx
        for iseg in range(n_seg_f):
            s = iseg / (n_seg_f - 1)
            dist = s * length
            # Parabolic arch: rises then droops gracefully
            fy = crown[1] + dist * pitch_up - (s ** 1.85) * 4.2
            fx = crown[0] + dx * dist
            fz = crown[2] + dz * dist
            w = 1.35 * math.sin(math.pi * (s ** 0.7))
            droop_v = 0.25 * w
            # 3 vertices across frond width (left tip, raised center spine, right tip)
            f_verts.append([fx - rx * w, fy - droop_v, fz - rz * w])
            f_verts.append([fx,          fy + 0.12,    fz])
            f_verts.append([fx + rx * w, fy - droop_v, fz + rz * w])
            v_f = 0.08 + 0.84 * s
            f_uvs.extend([[0.55, v_f], [0.75, v_f], [0.95, v_f]])
        for iseg in range(n_seg_f - 1):
            b = iseg * 3
            n = (iseg + 1) * 3
            # Top & bottom faces so palm fronds are visible from below and above!
            for tri in (
                [b, b + 1, n + 1], [b, n + 1, n],
                [b + 1, b + 2, n + 2], [b + 1, n + 2, n + 1],
                [b + 1, b, n + 1], [n + 1, b, n],
                [b + 2, b + 1, n + 2], [n + 2, b + 1, n + 1],
            ):
                f_faces.append(tri)
        mb.add_mesh(np.array(f_verts, dtype=np.float32), np.array(f_uvs, dtype=np.float32), np.array(f_faces, dtype=np.uint32))

    pos, norm, uv, faces = mb.build()
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_palm_tree.mesh"), pos, norm, uv, faces)

    # Palm tree UV texture (left half = warm grooved coconut bark, right half = lush tropical palm leaf)
    palm_img = Image.new("RGBA", (512, 512), (45, 165, 65, 255))
    p_draw = ImageDraw.Draw(palm_img)
    p_draw.rectangle([0, 0, 255, 512], fill=(135, 92, 54, 255))
    for y_ring in range(0, 512, 18):
        p_draw.rectangle([0, y_ring, 255, y_ring + 5], fill=(98, 64, 36, 255))
    # Lush gradient + central rachis on right half
    p_draw.rectangle([256, 0, 512, 512], fill=(38, 175, 62, 255))
    p_draw.rectangle([374, 0, 394, 512], fill=(120, 215, 75, 255))
    for y_fr in range(10, 500, 14):
        p_draw.line([(384, y_fr), (265, y_fr + 10)], fill=(24, 130, 42, 255), width=4)
        p_draw.line([(384, y_fr), (502, y_fr + 10)], fill=(24, 130, 42, 255), width=4)
    palm_img.save(os.path.join(OUT_TEX_DIR, "satf_palm_tree.png"))
    print(f"  [OK] Palmier Tropical 3D : {len(pos)} sommets, {len(faces)} triangles")

    # B. GRUE PORTUAIRE EN TREILLIS 3D (satf_harbor_crane.mesh + satf_magnet_claw.mesh + satf_crane.png)
    mb_crane = MeshBuilder()

    def add_beam(mb_target, pA, pB, radius=0.35, u_range=(0.05, 0.45)):
        pA = np.array(pA, dtype=np.float32)
        pB = np.array(pB, dtype=np.float32)
        d = pB - pA
        L = np.linalg.norm(d)
        if L < 1e-4:
            return
        u_dir = d / L
        up_ref = np.array([0.0, 1.0, 0.0], dtype=np.float32) if abs(u_dir[1]) < 0.9 else np.array([1.0, 0.0, 0.0], dtype=np.float32)
        v1 = np.cross(u_dir, up_ref)
        v1 /= np.linalg.norm(v1)
        v2 = np.cross(u_dir, v1)
        b_verts, b_uvs, b_faces = [], [], []
        for s_idx, pt in enumerate([pA, pB]):
            for k in range(6):
                ang = (2.0 * math.pi * k) / 6
                off = radius * (math.cos(ang) * v1 + math.sin(ang) * v2)
                b_verts.append(pt + off)
                b_uvs.append([u_range[0] + (u_range[1] - u_range[0]) * (k / 6), 0.1 + 0.8 * s_idx])
        for k in range(6):
            kn = (k + 1) % 6
            b_faces.append([k, kn, 6 + kn])
            b_faces.append([k, 6 + kn, 6 + k])
        mb_target.add_mesh(np.array(b_verts, dtype=np.float32), np.array(b_uvs, dtype=np.float32), np.array(b_faces, dtype=np.uint32))

    # 4 Tapered Lattice Tower Legs from Y=0 to Y=26
    levels = np.linspace(0.0, 26.0, 8)
    corners_at_lvl = []
    for y in levels:
        t = y / 26.0
        hw = 3.2 * (1.0 - 0.48 * t)
        corners_at_lvl.append([
            [-hw, y, -hw], [hw, y, -hw], [hw, y, hw], [-hw, y, hw]
        ])
    for il in range(len(levels) - 1):
        c0 = corners_at_lvl[il]
        c1 = corners_at_lvl[il + 1]
        for k in range(4):
            kn = (k + 1) % 4
            # Main corner post
            add_beam(mb_crane, c0[k], c1[k], radius=0.32, u_range=(0.05, 0.45))
            # Horizontal girder
            add_beam(mb_crane, c1[k], c1[kn], radius=0.20, u_range=(0.05, 0.45))
            # Diagonal X-brace
            add_beam(mb_crane, c0[k], c1[kn], radius=0.16, u_range=(0.55, 0.90))

    # Horizontal & Angled Jib Boom extending out over the water (-Z direction from Z=4 to Z=-34)
    boom_z = np.linspace(5.0, -34.0, 11)
    for iz in range(len(boom_z) - 1):
        z0, z1 = boom_z[iz], boom_z[iz + 1]
        y0 = 25.5 + 0.12 * max(0.0, -z0)
        y1 = 25.5 + 0.12 * max(0.0, -z1)
        b0 = [[-1.5, y0, z0], [1.5, y0, z0], [0.0, y0 + 2.4, z0]]
        b1 = [[-1.5, y1, z1], [1.5, y1, z1], [0.0, y1 + 2.4, z1]]
        for k in range(3):
            kn = (k + 1) % 3
            add_beam(mb_crane, b0[k], b1[k], radius=0.24, u_range=(0.05, 0.45))
            add_beam(mb_crane, b1[k], b1[kn], radius=0.16, u_range=(0.55, 0.90))
            add_beam(mb_crane, b0[k], b1[kn], radius=0.14, u_range=(0.55, 0.90))

    # Suspension stays from A-frame apex (0, 32, 0) to boom
    apex = [0.0, 32.5, 0.0]
    for k in range(4):
        add_beam(mb_crane, corners_at_lvl[-1][k], apex, radius=0.22, u_range=(0.05, 0.45))
    add_beam(mb_crane, apex, [0.0, 29.0, -26.0], radius=0.14, u_range=(0.55, 0.90))
    add_beam(mb_crane, apex, [0.0, 26.5, 5.0], radius=0.16, u_range=(0.55, 0.90))

    pos, norm, uv, faces = mb_crane.build()
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_harbor_crane.mesh"), pos, norm, uv, faces)

    # 3D Electromagnetic Claw (satf_magnet_claw.mesh)
    mb_claw = MeshBuilder()
    # 4 curved grapple prongs hanging under the magnet bell
    for k in range(4):
        ang = (2.0 * math.pi * k) / 4 + math.pi * 0.25
        dx, dz = math.cos(ang), math.sin(ang)
        p0 = [dx * 1.2, 0.2, dz * 1.2]
        p1 = [dx * 2.5, -1.2, dz * 2.5]
        p2 = [dx * 1.5, -2.6, dz * 1.5]
        add_beam(mb_claw, p0, p1, radius=0.26, u_range=(0.05, 0.45))
        add_beam(mb_claw, p1, p2, radius=0.20, u_range=(0.55, 0.90))
    pos_c, norm_c, uv_c, faces_c = mb_claw.build()
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_magnet_claw.mesh"), pos_c, norm_c, uv_c, faces_c)

    # Industrial Hazard Yellow & Dark Steel Texture (satf_crane.png)
    crane_img = Image.new("RGBA", (512, 512), (245, 185, 15, 255))
    c_draw = ImageDraw.Draw(crane_img)
    c_draw.rectangle([256, 0, 512, 512], fill=(42, 48, 58, 255))
    for y_st in range(0, 512, 48):
        c_draw.polygon([(0, y_st), (255, y_st + 40), (255, y_st + 60), (0, y_st + 20)], fill=(30, 34, 40, 255))
    crane_img.save(os.path.join(OUT_TEX_DIR, "satf_crane.png"))
    print(f"  [OK] Grue Portuaire 3D en Treillis : {len(pos)} sommets, {len(faces)} triangles")

    # C. YACHT DE PLAISANCE 3D (satf_yacht.mesh + satf_yacht.png)
    def yacht_profile(z):
        # z from -6 to 6 (scaled up in Studio via SpecialMesh.Scale!)
        t = (z + 6.0) / 12.0  # 0 at bow (-6), 1 at stern (+6)
        bow_taper = (t ** 0.55) if t < 0.45 else (0.45 ** 0.55 + 0.25 * (1.0 - ((t - 0.45) / 0.55) ** 2))
        half_w = max(0.25, 3.1 * bow_taper)
        bot_y = -1.6 + 0.95 * max(0.0, (0.35 - t) / 0.35) ** 1.6
        deck_y = 0.25 + 0.45 * (1.0 - t)
        if -1.5 <= z <= 3.2:
            tc = (z - (-1.5)) / 4.7
            cabin_y = deck_y + 1.45 * math.sin(tc * math.pi) ** 0.7
            cabin_w = half_w * 0.72
        else:
            cabin_y = deck_y + 0.1
            cabin_w = half_w * 0.5
        return half_w, bot_y, deck_y, cabin_w, cabin_y, 0.0

    pos_y, norm_y, uv_y, faces_y = build_lofted_sportscar_mesh(yacht_profile, wheel_radius=0.01, wheel_width=0.01)
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_yacht.mesh"), pos_y, norm_y, uv_y, faces_y)

    yacht_img = Image.new("RGBA", (512, 512), (245, 248, 255, 255))
    y_draw = ImageDraw.Draw(yacht_img)
    y_draw.rectangle([0, 0, 90, 512], fill=(15, 95, 195, 255))
    y_draw.rectangle([422, 0, 512, 512], fill=(15, 95, 195, 255))
    y_draw.rectangle([90, 0, 112, 512], fill=(0, 220, 255, 255))
    y_draw.rectangle([400, 0, 422, 512], fill=(0, 220, 255, 255))
    y_draw.rounded_rectangle([145, 140, 367, 290], radius=24, fill=(18, 32, 48, 255))
    yacht_img.save(os.path.join(OUT_TEX_DIR, "satf_yacht.png"))
    print(f"  [OK] Yacht Marina 3D : {len(pos_y)} sommets, {len(faces_y)} triangles")

    # D. ROCHER CÔTIER 3D (satf_rock.mesh + satf_rock.png)
    mb_rock = MeshBuilder()
    n_lat, n_lon = 12, 18
    r_verts, r_uvs, r_faces = [], [], []
    for ilat in range(n_lat):
        v = ilat / (n_lat - 1)
        phi = (v - 0.15) * math.pi * 0.75
        for ilon in range(n_lon):
            u = ilon / n_lon
            theta = u * 2.0 * math.pi
            bump = 1.0 + 0.22 * math.sin(3 * theta + 2 * phi) + 0.15 * math.cos(5 * theta - 3 * phi)
            rx = 5.5 * math.cos(phi) * math.cos(theta) * bump
            ry = max(-0.5, 4.2 * math.sin(phi) * bump)
            rz = 4.8 * math.cos(phi) * math.sin(theta) * bump
            r_verts.append([rx, ry, rz])
            r_uvs.append([u, v])
    for ilat in range(n_lat - 1):
        for ilon in range(n_lon):
            inext = (ilon + 1) % n_lon
            a0 = ilat * n_lon + ilon
            a1 = ilat * n_lon + inext
            b0 = (ilat + 1) * n_lon + ilon
            b1 = (ilat + 1) * n_lon + inext
            r_faces.append([a0, b0, b1])
            r_faces.append([a0, b1, a1])
    mb_rock.add_mesh(np.array(r_verts, dtype=np.float32), np.array(r_uvs, dtype=np.float32), np.array(r_faces, dtype=np.uint32))
    pos_r, norm_r, uv_r, faces_r = mb_rock.build()
    write_roblox_mesh_v2(os.path.join(OUT_MESH_DIR, "satf_rock.mesh"), pos_r, norm_r, uv_r, faces_r)

    rock_img = Image.new("RGBA", (256, 256), (118, 112, 104, 255))
    rk_draw = ImageDraw.Draw(rock_img)
    rk_draw.rectangle([0, 175, 256, 256], fill=(68, 145, 65, 255))  # Lush green island moss on top
    rock_img.save(os.path.join(OUT_TEX_DIR, "satf_rock.png"))
    print(f"  [OK] Rocher Côtier 3D : {len(pos_r)} sommets, {len(faces_r)} triangles")


# ==============================================================================
# 6. DÉPLOIEMENT VERS ROBLOX STUDIO (rbxasset://meshes/ & rbxasset://textures/)
# ==============================================================================
def deploy_to_roblox_studio():
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if not local_app_data:
        return
    versions_dir = os.path.join(local_app_data, "Roblox", "Versions")
    if not os.path.isdir(versions_dir):
        return

    mesh_files = glob.glob(os.path.join(OUT_MESH_DIR, "satf_*.mesh"))
    tex_files = glob.glob(os.path.join(OUT_TEX_DIR, "satf_*.png"))

    deployed = 0
    for v_folder in glob.glob(os.path.join(versions_dir, "version-*")):
        content_dir = os.path.join(v_folder, "content")
        if not os.path.isdir(content_dir):
            continue
        target_meshes = os.path.join(content_dir, "meshes")
        target_textures = os.path.join(content_dir, "textures")
        os.makedirs(target_meshes, exist_ok=True)
        os.makedirs(target_textures, exist_ok=True)
        for mf in mesh_files:
            shutil.copy2(mf, os.path.join(target_meshes, os.path.basename(mf)))
        for tf in tex_files:
            shutil.copy2(tf, os.path.join(target_textures, os.path.basename(tf)))
        deployed += 1
        print(f"  [DEPLOY] {len(mesh_files)} meshes & {len(tex_files)} textures -> {v_folder}")


def main():
    print("=========================================================")
    print(" STOP AT THE FRAME - 3D MESH & TEXTURE GENERATOR v2.00")
    print("=========================================================")
    build_glb_cars()
    build_procedural_sportscars()
    build_environment_meshes()
    deploy_to_roblox_studio()
    print("=========================================================")
    print(" GÉNÉRATION 3D TERMINÉE AVEC SUCCÈS !")
    print("=========================================================")


if __name__ == "__main__":
    main()
