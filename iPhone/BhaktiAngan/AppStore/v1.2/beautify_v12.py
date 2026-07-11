#!/usr/bin/env python3
# v1.2 App Store panels: Voice Japa + Daily Shlok (EN + HI).
# Reuses the v1.1 look: maroon gradient + gold ornament (base_canvas) and a
# gold-framed device screenshot (framed_screen). EN headlines drawn in Georgia;
# HI headlines pre-shaped via hitext.swift (CoreText) into hitxt_v12/*.png.
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BASE = "/Users/shveatamishra/Projects/PhoneApps/iPhone/BhaktiAngan/AppStore/v1.2"
RAW = os.path.join(BASE, "raw")
HIT = "/private/tmp/claude-501/-Users-shveatamishra-Projects-PhoneApps/f1531242-95e7-4536-a69b-5038b5879353/scratchpad/hitxt_v12"
EN = os.path.join(BASE, "en")
HI = os.path.join(BASE, "hi")
os.makedirs(EN, exist_ok=True); os.makedirs(HI, exist_ok=True)

W, H = 1290, 2796
PAD, R_IN, R_OUT = 30, 62, 92
RATIO = 2622 / 1206
GEO_B = "/System/Library/Fonts/Supplemental/Georgia Bold.ttf"
GEO_R = "/System/Library/Fonts/Supplemental/Georgia.ttf"

def font(p, s): return ImageFont.truetype(p, s)
def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=255)
    return m
def vgrad(size, top, bot):
    w, h = size; base = Image.new("RGB", (1, h)); px = base.load()
    for y in range(h):
        t = y/(h-1); px[0, y] = tuple(int(top[i]+(bot[i]-top[i])*t) for i in range(3))
    return base.resize((w, h))
def glow(canvas, cx, cy, rad, color, strength):
    layer = Image.new("L", (W, H), 0)
    ImageDraw.Draw(layer).ellipse([cx-rad, cy-rad*1.15, cx+rad, cy+rad*1.15], fill=strength)
    layer = layer.filter(ImageFilter.GaussianBlur(220))
    tint = Image.new("RGB", (W, H), color)
    return Image.alpha_composite(canvas, Image.merge("RGBA", (*tint.split(), layer.point(lambda a: int(a*0.9)))))
def base_canvas():
    c = vgrad((W, H), (32, 13, 10), (78, 27, 16)).convert("RGBA")
    c = glow(c, W//2, 1620, 760, (236, 190, 96), 150)
    d = ImageDraw.Draw(c); cx, y, lw = W//2, 168, 150
    d.line([(cx-lw, y), (cx-26, y)], fill=(205, 163, 73), width=3)
    d.line([(cx+26, y), (cx+lw, y)], fill=(205, 163, 73), width=3)
    d.polygon([(cx, y-9), (cx+13, y), (cx, y+9), (cx-13, y)], fill=(224, 178, 92))
    return c
def paste_c(canvas, path, cx, y, max_w=None, f=0.5):
    img = Image.open(path).convert("RGBA")
    if f != 1.0:
        img = img.resize((max(1, int(img.width*f)), max(1, int(img.height*f))), Image.LANCZOS)
    if max_w and img.width > max_w:
        nh = int(img.height*(max_w/img.width)); img = img.resize((max_w, nh), Image.LANCZOS)
    canvas.alpha_composite(img, (int(cx-img.width/2), int(y)))
    return y + img.height
def draw_center_txt(d, cx, y, text, fnt, fill):
    b = d.textbbox((0, 0), text, font=fnt); d.text((cx-(b[2]-b[0])/2, y-b[1]), text, font=fnt, fill=fill)
    return y+(b[3]-b[1])
def framed_screen(canvas, grab_path, fy):
    avail = H-fy-40; sh = int(avail-2*PAD); sw = int(sh/RATIO)
    if sw > 966: sw = 966; sh = int(sw*RATIO)
    scr = Image.open(grab_path).convert("RGB").resize((sw, sh), Image.LANCZOS)
    fw, fh = sw+2*PAD, sh+2*PAD; fx = (W-fw)//2
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([fx, fy+30, fx+fw, fy+fh+30], radius=R_OUT, fill=(0, 0, 0, 150))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(38)))
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle([fx, fy, fx+fw, fy+fh], radius=R_OUT, fill=(18, 16, 20, 255))
    d.rounded_rectangle([fx, fy, fx+fw, fy+fh], radius=R_OUT, outline=(150, 116, 58, 200), width=2)
    canvas.paste(scr, (fx+PAD, fy+PAD), rounded_mask((sw, sh), R_IN))
    return canvas

def en_panel(grab, head_lines, sub_lines, out):
    c = base_canvas(); d = ImageDraw.Draw(c); cx = W//2
    fh, fs = font(GEO_B, 92), font(GEO_R, 46); y = 212
    for line in head_lines: y = draw_center_txt(d, cx, y, line, fh, (240, 212, 146)) + 22
    y += 10
    for line in sub_lines: y = draw_center_txt(d, cx, y, line, fs, (226, 206, 178)) + 12
    c = framed_screen(c, os.path.join(RAW, grab), int(y+34))
    c.convert("RGB").save(os.path.join(EN, out), "PNG"); print("wrote en/"+out)

def hi_panel(grab, head_png, sub_png, out):
    c = base_canvas()
    y = paste_c(c, os.path.join(HIT, head_png), W//2, 196, max_w=1000)
    y = paste_c(c, os.path.join(HIT, sub_png), W//2, y-6, max_w=940)
    c = framed_screen(c, os.path.join(RAW, grab), int(y+34))
    c.convert("RGB").save(os.path.join(HI, out), "PNG"); print("wrote hi/"+out)

# --- Voice Japa (panel 02) ---
en_panel("g3_voicejapa_en.png", ["Chant. It counts", "by itself."],
         ["Hands-free japa, eyes closed,", "all on your device."], "en_02_voicejapa.png")
hi_panel("g3_voicejapa_hi.png", "vj_head.png", "vj_sub.png", "hi_02_voicejapa.png")
# --- Daily Shlok (panel 03) ---
en_panel("g3_verses_en.png", ["A Gita shlok", "every morning"],
         ["Sanskrit with meaning, and", "one line to live by today."], "en_03_shlok.png")
hi_panel("g3_verses_hi.png", "sh_head.png", "sh_sub.png", "hi_03_shlok.png")
print("done")
