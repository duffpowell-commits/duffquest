# SCons profile for Duff Quest's web export template: Godot 4.5-stable, 2D only, nothing the game doesn't use.
# Built by .github/workflows/web_template.yml (emscripten 4.0.11, threads=no to match the Web preset's
# nothreads variant) and published to the "web-template-2d" release; build.yml exports with it when present.
# The game is pure 2D, draws its own UI, ships English text, wav/ogg audio and png/jpg/webp art.
# platform/target/threads are passed on the scons command line (the profile does not set them)
optimize = "size"
lto = "full"
deprecated = "no"
disable_3d = "yes"
disable_physics_3d = "yes"
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"
disable_advanced_gui = "yes"
# English only: the small fallback text server instead of ICU + HarfBuzz
module_text_server_adv_enabled = "no"
module_text_server_fb_enabled = "yes"
module_msdfgen_enabled = "no"
# importers, editors, 3D and networking the runtime never touches
for m in ["basis_universal", "camera", "csg", "cvtt", "dds", "enet", "fbx", "gltf", "gridmap", "hdr",
          "interactive_music", "jolt_physics", "jsonrpc", "ktx", "lightmapper_rd", "meshoptimizer", "minimp3",
          "mobile_vr", "mono", "multiplayer", "openxr", "raycast", "tga", "theora", "tinyexr", "upnp", "vhacd",
          "webrtc", "websocket", "webxr", "xatlas_unwrap", "glslang", "betsy", "bmp"]:
    globals()["module_%s_enabled" % m] = "no"
