#!/usr/bin/env python3
# Final v1.1 App Store panels.
# HI panels: Devanagari pre-rendered via CoreText (hitxt/*.png), pasted with alpha.
# New 5th panel (EN+HI): the two v1.1 widgets on a home-screen mock.
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SCR = "/private/tmp/claude-501/-Users-shveatamishra-Projects-PhoneApps/f1531242-95e7-4536-a69b-5038b5879353/scratchpad"
HIT = os.path.join(SCR, "hitxt")
ART = "/Users/shveatamishra/Projects/bhaktiangan-site/Darshan Gallery Images"
OUT = os.path.join(SCR, "shots2")
os.makedirs(OUT, exist_ok=True)

W, H = 1290, 2796
PAD = 30
R_IN = 62
R_OUT = 92
RATIO = 2622 / 1206  # grab aspect

def font(path, size):
    return ImageFont.truetype(path, size)

GEO_B = "/System/Library/Fonts/Supplemental/Georgia Bold.ttf"
GEO_R = "/System/Library/Fonts/Supplemental/Georgia.ttf"

def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=255)
    return m

def vgrad(size, top, bot):
    w, h = size
    base = Image.new("RGB", (1, h))
    px = base.load()
    for y in range(h):
        t = y / (h - 1)
        px[0, y] = tuple(int(top[i] + (bot[i]-top[i])*t) for i in range(3))
    return base.resize((w, h))

def glow(canvas, cx, cy, rad, color, strength):
    layer = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(layer)
    d.ellipse([cx-rad, cy-rad*1.15, cx+rad, cy+rad*1.15], fill=strength)
    layer = layer.filter(ImageFilter.GaussianBlur(220))
    tint = Image.new("RGB", (W, H), color)
    return Image.alpha_composite(canvas, Image.merge("RGBA", (*tint.split(), layer.point(lambda a: int(a*0.9)))))

def base_canvas():
    c = vgrad((W, H), (32, 13, 10), (78, 27, 16)).convert("RGBA")
    c = glow(c, W//2, 1620, 760, (236, 190, 96), 150)
    d = ImageDraw.Draw(c)
    cx, y, lw = W//2, 168, 150
    d.line([(cx-lw, y), (cx-26, y)], fill=(205, 163, 73), width=3)
    d.line([(cx+26, y), (cx+lw, y)], fill=(205, 163, 73), width=3)
    d.polygon([(cx, y-9), (cx+13, y), (cx, y+9), (cx-13, y)], fill=(224, 178, 92))
    return c

def paste_c(canvas, path, cx, y, max_w=None, f=0.5):
    # hitext PNGs are rendered at 2x (Retina backing scale); f=0.5 restores point size.
    img = Image.open(path).convert("RGBA")
    if f != 1.0:
        img = img.resize((max(1, int(img.width*f)), max(1, int(img.height*f))), Image.LANCZOS)
    if max_w and img.width > max_w:
        nh = int(img.height * (max_w / img.width))
        img = img.resize((max_w, nh), Image.LANCZOS)
    canvas.alpha_composite(img, (int(cx - img.width/2), int(y)))
    return y + img.height

def framed_screen(canvas, grab_path, fy):
    # scale device to fit between fy and bottom margin
    avail = H - fy - 40
    sh = int(avail - 2*PAD)
    sw = int(sh / RATIO)
    if sw > 966:
        sw = 966
        sh = int(sw * RATIO)
    scr = Image.open(grab_path).convert("RGB").resize((sw, sh), Image.LANCZOS)
    fw, fh = sw + 2*PAD, sh + 2*PAD
    fx = (W - fw) // 2
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([fx, fy+30, fx+fw, fy+fh+30], radius=R_OUT, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(38))
    canvas = Image.alpha_composite(canvas, shadow)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle([fx, fy, fx+fw, fy+fh], radius=R_OUT, fill=(18, 16, 20, 255))
    d.rounded_rectangle([fx, fy, fx+fw, fy+fh], radius=R_OUT, outline=(150, 116, 58, 200), width=2)
    canvas.paste(scr, (fx+PAD, fy+PAD), rounded_mask((sw, sh), R_IN))
    return canvas

def hi_panel(grab, head_png, sub_png, outname):
    c = base_canvas()
    y = paste_c(c, os.path.join(HIT, head_png), W//2, 196)
    y = paste_c(c, os.path.join(HIT, sub_png), W//2, y - 14)
    c = framed_screen(c, os.path.join(SCR, grab), int(y + 34))
    c.convert("RGB").save(os.path.join(OUT, outname), "PNG")
    print("wrote", outname)

def sq_crop(path, size):
    img = Image.open(path).convert("RGB")
    s = min(img.size)
    l = (img.width - s)//2
    t = int((img.height - s) * 0.22)  # bias toward face
    return img.crop((l, t, l+s, t+s)).resize((size, size), Image.LANCZOS)

def card_shadow(canvas, box, radius):
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([box[0], box[1]+16, box[2], box[3]+16], radius=radius, fill=(0, 0, 0, 130))
    return Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(24)))

def draw_center_txt(d, cx, y, text, fnt, fill):
    b = d.textbbox((0, 0), text, font=fnt)
    d.text((cx - (b[2]-b[0])/2, y - b[1]), text, font=fnt, fill=fill)
    return y + (b[3]-b[1])

def odraw(canvas, fn):
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fn(ImageDraw.Draw(ov))
    return Image.alpha_composite(canvas, ov)

def widget_panel(lang, outname):
    c = base_canvas()
    cx = W//2
    if lang == "hi":
        y = paste_c(c, os.path.join(HIT, "hi5_head.png"), cx, 196)
        y = paste_c(c, os.path.join(HIT, "hi5_sub.png"), cx, y - 14)
    else:
        d = ImageDraw.Draw(c)
        fh, fs = font(GEO_B, 92), font(GEO_R, 46)
        y = 212
        for line in ["Darshan on your", "home screen"]:
            y = draw_center_txt(d, cx, y, line, fh, (240, 212, 146)) + 22
        y += 10
        for line in ["Two new widgets: Daily Darshan and live", "Choghadiya, always a glance away"]:
            y = draw_center_txt(d, cx, y, line, fs, (226, 206, 178)) + 12
    fy = int(y + 34)

    # phone frame with home-screen wallpaper
    avail = H - fy - 40
    sh = int(avail - 2*PAD)
    sw = int(sh / RATIO)
    if sw > 966:
        sw = 966
        sh = int(sw * RATIO)
    fw, fh_ = sw + 2*PAD, sh + 2*PAD
    fx = (W - fw)//2
    c = card_shadow(c, [fx, fy, fx+fw, fy+fh_], R_OUT)
    d = ImageDraw.Draw(c)
    d.rounded_rectangle([fx, fy, fx+fw, fy+fh_], radius=R_OUT, fill=(18, 16, 20, 255))
    d.rounded_rectangle([fx, fy, fx+fw, fy+fh_], radius=R_OUT, outline=(150, 116, 58, 200), width=2)
    wall = vgrad((sw, sh), (46, 19, 15), (96, 37, 22))
    c.paste(wall, (fx+PAD, fy+PAD), rounded_mask((sw, sh), R_IN))
    d = ImageDraw.Draw(c)

    sx, sy = fx+PAD, fy+PAD
    m = int(sw * 0.072)                 # side margin inside screen
    cw = sw - 2*m                       # content width
    scale = sw / 966.0

    # --- medium Daily Darshan widget ---
    mh = int(400 * scale)
    mx, my = sx+m, sy + int(110*scale)
    mbox = [mx, my, mx+cw, my+mh]
    c = card_shadow(c, mbox, int(44*scale))
    d = ImageDraw.Draw(c)
    d.rounded_rectangle(mbox, radius=int(44*scale), fill=(26, 19, 28, 255))
    img = sq_crop(os.path.join(ART, "krishna-bansuri.png"), mh)
    lmask = rounded_mask((mh, mh), int(44*scale))
    # square off the right edge of the image mask
    ImageDraw.Draw(lmask).rectangle([mh//2, 0, mh, mh], fill=255)
    lm2 = rounded_mask((mh, mh), int(44*scale))
    lmask = Image.composite(lmask, lm2, Image.new("L", (mh, mh), 255).crop((0, 0, mh, mh)))
    c.paste(img, (mx, my), lmask)
    d = ImageDraw.Draw(c)
    tx = mx + mh + int(44*scale)
    t_cx = (tx + mx + cw) // 2
    if lang == "hi":
        yy = paste_c(c, os.path.join(HIT, "w_krishna_hi.png"), t_cx, my + int(80*scale), f=0.5*scale, max_w=int(cw-mh-70*scale))
        yy = paste_c(c, os.path.join(HIT, "w_mantra_hi.png"), t_cx, yy + int(16*scale), f=0.5*scale, max_w=int(cw-mh-70*scale))
    else:
        d = ImageDraw.Draw(c)
        yy = draw_center_txt(d, t_cx, my + int(88*scale), "Bansi Wale", font(GEO_B, int(52*scale)), (247, 241, 230)) + int(20*scale)
        yy = draw_center_txt(d, t_cx, yy, "Om Namo Bhagavate", font(GEO_R, int(33*scale)), (226, 206, 178)) + int(8*scale)
        yy = draw_center_txt(d, t_cx, yy, "Vasudevaya", font(GEO_R, int(33*scale)), (226, 206, 178))
    d = ImageDraw.Draw(c)
    cap = font(GEO_B, int(22*scale))
    b = d.textbbox((0, 0), "B H A K T I  A N G A N", font=cap)
    d.text((t_cx - (b[2]-b[0])/2, my + mh - int(58*scale)), "B H A K T I  A N G A N", font=cap, fill=(205, 163, 73))

    # --- row 2: choghadiya (left) + small darshan (right) ---
    gap = int(36*scale)
    swd = (cw - gap)//2
    y2 = my + mh + gap
    # choghadiya card
    cbox = [mx, y2, mx+swd, y2+swd]
    c = card_shadow(c, cbox, int(44*scale))
    cg = vgrad((swd, swd), (32, 96, 70), (14, 58, 42))
    c.paste(cg, (mx, y2), rounded_mask((swd, swd), int(44*scale)))
    d = ImageDraw.Draw(c)
    ccx = mx + swd//2
    if lang == "hi":
        paste_c(c, os.path.join(HIT, "w_chogh_hi.png"), ccx, y2 + int(34*scale), f=0.5*scale)
        yy = paste_c(c, os.path.join(HIT, "w_amrit_hi.png"), ccx, y2 + int(96*scale), f=0.5*scale)
        d = ImageDraw.Draw(c)
        yy = draw_center_txt(d, ccx, yy + int(10*scale), "7:30 - 9:00 AM", font(GEO_R, int(30*scale)), (214, 236, 222)) + int(24*scale)
        pill = Image.open(os.path.join(HIT, "w_shubh_hi.png")).convert("RGBA")
        pill = pill.resize((int(pill.width*0.5*scale), int(pill.height*0.5*scale)), Image.LANCZOS)
        pw, ph = pill.size
        yy2 = yy
        c = odraw(c, lambda d: d.rounded_rectangle([ccx-pw//2-18, yy2, ccx+pw//2+18, yy2+ph+10], radius=(ph+10)//2, fill=(255, 255, 255, 42)))
        c.alpha_composite(pill, (ccx-pw//2, int(yy2+5)))
    else:
        d = ImageDraw.Draw(c)
        draw_center_txt(d, ccx, y2 + int(38*scale), "C H O G H A D I Y A", font(GEO_B, int(21*scale)), (190, 225, 205))
        yy = draw_center_txt(d, ccx, y2 + int(108*scale), "Amrit", font(GEO_B, int(72*scale)), (247, 246, 240)) + int(14*scale)
        yy2 = draw_center_txt(d, ccx, yy, "7:30 - 9:00 AM", font(GEO_R, int(30*scale)), (214, 236, 222)) + int(24*scale)
        pt = "Good time"
        pf = font(GEO_B, int(26*scale))
        b = d.textbbox((0, 0), pt, font=pf)
        pw, ph = b[2]-b[0], b[3]-b[1]
        c = odraw(c, lambda d: d.rounded_rectangle([ccx-pw//2-20, yy2, ccx+pw//2+20, yy2+ph+22], radius=(ph+22)//2, fill=(255, 255, 255, 42)))
        d = ImageDraw.Draw(c)
        d.text((ccx-pw//2, yy2+11-b[1]), pt, font=pf, fill=(234, 250, 240))
    # small darshan card
    gx = mx + swd + gap
    gbox = [gx, y2, gx+swd, y2+swd]
    c = card_shadow(c, gbox, int(44*scale))
    gimg = sq_crop(os.path.join(ART, "ganesha-signature.png"), swd)
    ov = Image.new("L", (swd, swd), 0)
    od = ImageDraw.Draw(ov)
    for i in range(swd//3):
        od.rectangle([0, swd - swd//3 + i, swd, swd - swd//3 + i + 1], fill=int(200 * (i/(swd//3))))
    dark = Image.new("RGB", (swd, swd), (10, 8, 6))
    gimg = Image.composite(dark, gimg, ov)
    c.paste(gimg, (gx, y2), rounded_mask((swd, swd), int(44*scale)))
    d = ImageDraw.Draw(c)
    gcx = gx + swd//2
    if lang == "hi":
        nm = Image.open(os.path.join(HIT, "w_ganesha_hi.png")).convert("RGBA")
        nm = nm.resize((int(nm.width*0.5*scale), int(nm.height*0.5*scale)), Image.LANCZOS)
        c.alpha_composite(nm, (gcx - nm.width//2, y2 + swd - nm.height - int(26*scale)))
    else:
        nf = font(GEO_B, int(38*scale))
        b = d.textbbox((0, 0), "Shri Ganesha", font=nf)
        d.text((gcx-(b[2]-b[0])/2, y2 + swd - (b[3]-b[1]) - int(34*scale) - b[1]), "Shri Ganesha", font=nf, fill=(247, 241, 230))

    # --- abstract app icon grid + dock (translucent, drawn on overlay) ---
    ic = int(104*scale)
    dock_h = int(140*scale)
    dy = sy + sh - dock_h - int(26*scale)
    def icons(d):
        y3 = y2 + swd + int(70*scale)
        while y3 + ic < dy - int(50*scale):
            for i in range(4):
                icx = mx + int(i * (cw - ic) / 3)
                d.rounded_rectangle([icx, y3, icx+ic, y3+ic], radius=int(26*scale), fill=(255, 255, 255, 24))
            y3 += ic + int(64*scale)
        d.rounded_rectangle([sx+m//2, dy, sx+sw-m//2, dy+dock_h], radius=int(44*scale), fill=(255, 255, 255, 20))
        ic2 = int(100*scale)
        for i in range(4):
            icx = sx + m + int(i * (sw - 2*m - ic2) / 3)
            d.rounded_rectangle([icx, dy+(dock_h-ic2)//2, icx+ic2, dy+(dock_h-ic2)//2+ic2], radius=int(26*scale), fill=(255, 255, 255, 26))
    c = odraw(c, icons)

    c.convert("RGB").save(os.path.join(OUT, outname), "PNG")
    print("wrote", outname)

hi_panel("g2_today_hi.png",   "hi1_head.png", "hi1_sub.png", "hi_01_today.png")
hi_panel("g2_library_hi.png", "hi2_head.png", "hi2_sub.png", "hi_02_library.png")
hi_panel("g2_katha_hi.png",   "hi3_head.png", "hi3_sub.png", "hi_03_katha.png")
hi_panel("g2_japa_hi.png",    "hi4_head.png", "hi4_sub.png", "hi_04_japa.png")
widget_panel("en", "en_05_widgets.png")
widget_panel("hi", "hi_05_widgets.png")
print("done")
