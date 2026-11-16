# SCons profile for the 3D-view web export template (3D track, step 1 of spike3d/PLAN_3D.md).
# Same as tools/web_template/custom.py (the live 2D engine) except 3D rendering is ON so Sprite3D / lights / shadows / Environment
# exist. 3D physics and 3D navigation stay off: the game sim stays 2D and the 3D view only draws it.
# Keep this file in step with tools/web_template/custom.py. Built by .github/workflows/web_template_3d.yml into release
# "web-template-3d" (branches: "web-template-3d-preview"). The live build does NOT use it yet (step 7 flips that).
# Original notes from custom.py follow.
# Built by .github/workflows/web_template.yml (emscripten 4.0.11, threads=no to match the Web preset's
# nothreads variant) and published to the "web-template-2d" release; build.yml exports with it when present.
# The game is pure 2D, draws its own UI, ships English text, wav/ogg audio and png/jpg/webp art.
# Check a new build with a real web boot + play test: a class the scripts need but the build lacks only
# shows up as a parse error in the browser console (e.g. WorldEnvironment, SubViewportContainer).
# platform/target/threads are passed on the scons command line (the profile does not set them)
optimize = "size_extra"
lto = "full"
# deprecated stays on: scripts may still call renamed APIs (e.g. Image.create) and only fail when loaded
disable_3d = "no"
disable_physics_3d = "yes"
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"
# advanced GUI stays: game.gd needs SubViewportContainer
minizip = "no"
# Text stays on the advanced server (HarfBuzz): the fallback one spaced the title text wrong ("therent").
# Graphite (exotic script shaping) is not needed for English.
graphite = "no"
module_text_server_fb_enabled = "no"
module_msdfgen_enabled = "no"
# importers, editors, 3D and networking the runtime never touches
for m in ["basis_universal", "camera", "csg", "cvtt", "dds", "enet", "fbx", "gltf", "gridmap", "hdr",
          "interactive_music", "jolt_physics", "jsonrpc", "ktx", "lightmapper_rd", "meshoptimizer", "minimp3",
          "mobile_vr", "mono", "multiplayer", "openxr", "raycast", "tga", "theora", "tinyexr", "upnp", "vhacd",
          "webrtc", "websocket", "webxr", "xatlas_unwrap", "glslang", "betsy", "bmp",
          # textures ship pre-imported (.ctex), so no runtime jpg/svg loaders or encoders; no TLS on web
          "jpg", "svg", "noise", "etcpak", "astcenc", "mbedtls", "zip"]:
    globals()["module_%s_enabled" % m] = "no"
