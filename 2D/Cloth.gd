tool
extends Node2D

export(bool) var simulate = false
export(Vector2) var gravity_vec = Vector2(0,1)
export(float) var gravity = 98

export(Texture) var texture
export(Texture) var normal_map

export(Vector2) var uv_offset = Vector2(0.0,0.0)
export(Vector2) var uv_scale = Vector2(1.0,1.0)
export(float) var uv_rotation = 0.0