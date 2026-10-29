#!/usr/bin/env python3
"""Compose the AMA welcome overlay from the user's numbered assets.
The wallpaper is deliberately NOT included here: Kitty draws it natively as the
persistent background, so the standard `clear` command can remove this overlay
while leaving the wallpaper visible.
"""
from __future__ import annotations
import argparse, os, platform, re, shutil, subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1920, 1080
CYAN = (59, 199, 255, 245)
PALE = (215, 233, 250, 245)
MUTED = (122, 166, 199, 235)
NAVY = (4, 15, 29, 218)
BORDER = (37, 157, 224, 145)


def valid_image(path: Path) -> Image.Image | None:
    try:
        im = Image.open(path).convert('RGBA')
        if im.width < 16 or im.height < 16:
            return None
        return im
    except Exception:
        return None


def font_path(preferred: str = 'JetBrainsMono Nerd Font Mono') -> str | None:
    # Prefer the same font kitty uses; fall back to common Linux monospace fonts.
    try:
        out = subprocess.run(['fc-match', '-f', '%{file}', preferred], capture_output=True, text=True, timeout=2)
        p = out.stdout.strip()
        if p and Path(p).exists():
            return p
    except Exception:
        pass
    for p in [
        '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/liberation2/LiberationMono-Regular.ttf',
    ]:
        if Path(p).exists():
            return p
    return None


def get_font(size: int, italic: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    p = font_path('JetBrainsMono Nerd Font Mono')
    if italic:
        for q in [
            str(Path(p).with_name('JetBrainsMonoNerdFontMono-Italic.ttf')) if p else '',
            '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Oblique.ttf',
        ]:
            if q and Path(q).exists():
                p = q
                break
    try:
        return ImageFont.truetype(p, size) if p else ImageFont.load_default()
    except Exception:
        return ImageFont.load_default()


def contain(src: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    x, y, bw, bh = box
    im = src.copy()
    im.thumbnail((bw, bh), Image.Resampling.LANCZOS)
    return im


def cover(src: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    x, y, bw, bh = box
    sw, sh = src.size
    scale = max(bw / sw, bh / sh)
    nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
    im = src.resize((nw, nh), Image.Resampling.LANCZOS)
    left = max(0, (nw - bw) // 2)
    top = max(0, (nh - bh) // 2)
    return im.crop((left, top, left + bw, top + bh))


def paste_contain(canvas: Image.Image, src: Image.Image, box: tuple[int, int, int, int], padding=0):
    x, y, bw, bh = box
    im = contain(src, (0, 0, bw - padding * 2, bh - padding * 2))
    px = x + (bw - im.width) // 2
    py = y + (bh - im.height) // 2
    canvas.alpha_composite(im, (px, py))


def os_name() -> str:
    if os.environ.get('AMA_OS_LABEL'):
        return os.environ['AMA_OS_LABEL']
    try:
        data = {}
        for line in Path('/etc/os-release').read_text(encoding='utf-8').splitlines():
            if '=' in line:
                k, v = line.split('=', 1)
                data[k] = v.strip().strip('"')
        return data.get('PRETTY_NAME', platform.system())
    except Exception:
        return platform.system()


def read_first(path: str, default: str = '') -> str:
    try:
        return Path(path).read_text(encoding='utf-8', errors='ignore').strip().splitlines()[0]
    except Exception:
        return default


def device_name() -> str:
    if os.environ.get('AMA_DEVICE_LABEL'):
        return os.environ['AMA_DEVICE_LABEL']
    for p in ['/sys/devices/virtual/dmi/id/product_name', '/sys/devices/virtual/dmi/id/product_family']:
        s = read_first(p)
        if s and s.lower() not in {'none', 'system product name', 'not specified'}:
            return s
    return platform.node()


def cpu_name() -> str:
    if os.environ.get('AMA_CPU_LABEL'):
        return os.environ['AMA_CPU_LABEL']
    try:
        for line in Path('/proc/cpuinfo').read_text(errors='ignore').splitlines():
            if line.lower().startswith('model name'):
                return line.split(':', 1)[1].strip()
    except Exception:
        pass
    return platform.processor() or 'Unknown'


def gpu_name() -> str:
    if os.environ.get('AMA_GPU_LABEL'):
        return os.environ['AMA_GPU_LABEL']
    if shutil.which('nvidia-smi'):
        try:
            r = subprocess.run(['nvidia-smi', '--query-gpu=name', '--format=csv,noheader'], capture_output=True, text=True, timeout=2)
            s = r.stdout.strip().splitlines()
            if s:
                return s[0].strip()
        except Exception:
            pass
    return 'System graphics'


def memory_usage() -> str:
    if os.environ.get('AMA_RAM_LABEL'):
        return os.environ['AMA_RAM_LABEL']
    try:
        vals = {}
        for line in Path('/proc/meminfo').read_text().splitlines():
            k, v = line.split(':', 1)
            vals[k] = int(v.strip().split()[0])
        total = vals.get('MemTotal', 0) / 1024 / 1024
        avail = vals.get('MemAvailable', 0) / 1024 / 1024
        used = total - avail
        pct = round((used / total) * 100) if total else 0
        return f'{used:.1f} / {total:.1f} GiB  ({pct}%)'
    except Exception:
        return 'Unavailable'


def disk_usage() -> str:
    if os.environ.get('AMA_DISK_LABEL'):
        return os.environ['AMA_DISK_LABEL']
    try:
        du = shutil.disk_usage('/')
        used = (du.total - du.free) / (1024 ** 3)
        total = du.total / (1024 ** 3)
        return f'{used:.1f} / {total:.1f} GiB  ({round(used / total * 100)}%)'
    except Exception:
        return 'Unavailable'


def battery_status() -> str:
    if os.environ.get('AMA_BATTERY_LABEL'):
        return os.environ['AMA_BATTERY_LABEL']
    for p in Path('/sys/class/power_supply').glob('BAT*'):
        cap = read_first(str(p / 'capacity'))
        status = read_first(str(p / 'status'))
        if cap:
            return f'{cap}%  {status or "Unknown"}'
    return 'Not detected'


def shorten(s: str, max_chars: int) -> str:
    s = re.sub(r'\s+', ' ', s).strip()
    if len(s) > max_chars:
        return s[:max_chars - 1] + '…'
    return s


def placeholder(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], title: str, subtitle: str = 'REPLACE PNG'):
    x, y, w, h = box
    # Dashed cyan outline so the user can see exactly where an image belongs.
    draw.rounded_rectangle((x, y, x+w, y+h), radius=14, fill=(5, 20, 38, 120), outline=(40, 160, 223, 170), width=2)
    f1, f2 = get_font(max(17, min(24, w // 10))), get_font(12)
    bb = draw.textbbox((0, 0), title, font=f1)
    draw.text((x + (w-(bb[2]-bb[0]))/2, y+h*0.39), title, font=f1, fill=CYAN)
    bb2 = draw.textbbox((0, 0), subtitle, font=f2)
    draw.text((x + (w-(bb2[2]-bb2[0]))/2, y+h*0.63), subtitle, font=f2, fill=MUTED)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--assets', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    assets = args.assets.expanduser().resolve()
    out = args.output.expanduser().resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, 'RGBA')

    # Main hero image on the right. It is a foreground overlay, not the wallpaper.
    hero_box = (1220, 0, 700, 1080)
    hero = valid_image(assets / '01_hero_robot_lab.png')
    if hero:
        hero_fit = cover(hero, (0, 0, hero_box[2], hero_box[3]))
        # clipped rounded card via mask
        mask = Image.new('L', hero_fit.size, 0)
        md = ImageDraw.Draw(mask)
        md.rectangle((0, 0, hero_fit.width-1, hero_fit.height-1), fill=255)
        canvas.alpha_composite(Image.composite(hero_fit, Image.new('RGBA', hero_fit.size, (0,0,0,0)), mask), (hero_box[0], hero_box[1]))
        #draw.rounded_rectangle((hero_box[0], hero_box[1], hero_box[0]+hero_box[2], hero_box[1]+hero_box[3]), radius=22, outline=(38, 158, 225, 190), width=3)
    else:
        placeholder(draw, hero_box, '01  ROBOTICS LAB', 'HERO PHOTO PNG')

    # Brand strip: AMA logo and four tool/technology images.
    logo = valid_image(assets / '06_ama_logo.png')
    if logo:
        paste_contain(canvas, logo, (72, 45, 350, 130), 2)
    else:
        placeholder(draw, (72, 45, 350, 130), 'AMA', '06_ama_logo.png')

    badges = [
        ('05_python.png', (448, 55, 90, 96), 'PYTHON'),
        ('04_cpp.png', (560, 55, 90, 96), 'C++'),
        ('03_vscode.png', (672, 55, 90, 96), 'VS CODE'),
        ('02_ros.png', (784, 55, 180, 96), 'ROS'),
    ]
    for filename, box, label in badges:
        img = valid_image(assets / filename)
        if img:
            paste_contain(canvas, img, box, 4)
        else:
            placeholder(draw, box, label, 'ICON SLOT')

    # Portrait and name/signature on the left.
    profile_box = (88, 210, 330, 325)
    profile = valid_image(assets / '08_profile.png')
    if profile:
        paste_contain(canvas, profile, profile_box, 0)
    else:
        placeholder(draw, profile_box, '08  PROFILE', 'TRANSPARENT PNG')

    name_box = (70, 548, 390, 95)
    name_image = valid_image(assets / '07_name_signature.png')
    if name_image:
        paste_contain(canvas, name_image, name_box, 2)
    else:
        # Default live-looking name text so the slot is clear but the screen still feels designed.
        draw.text((name_box[0] + 8, name_box[1] + 12), 'Abdelrahman Abdelgawad', font=get_font(27, italic=True), fill=(80, 211, 255, 245))
        draw.line((name_box[0]+12, name_box[1]+57, name_box[0]+315, name_box[1]+43), fill=(39, 190, 244, 190), width=3)
        

    # Compact dynamic hardware panel.
    panel = (462, 198, 714, 424)
    x, y, pw, ph = panel
    draw.rounded_rectangle((x, y, x+pw, y+ph), radius=18, fill=NAVY, outline=BORDER, width=2)
    title_font = get_font(17)
    label_font = get_font(15)
    value_font = get_font(15)
    user = os.environ.get('AMA_USER_LABEL', 'ama_robotics')
    host = shorten(os.environ.get('AMA_HOST_LABEL') or platform.node(), 38)
    draw.text((x+24, y+18), f'{user}@{host}', font=title_font, fill=(85, 190, 255, 255))
    draw.line((x+24, y+51, x+pw-24, y+51), fill=(41, 134, 193, 170), width=2)
    shell = os.environ.get('AMA_SHELL_LABEL') or os.environ.get('AMA_SHELL_NAME') or os.environ.get('SHELL', '/bin/zsh').rsplit('/', 1)[-1]
    kitty_ver = os.environ.get('AMA_TERMINAL_LABEL', 'kitty')
    try:
        if os.environ.get('AMA_TERMINAL_LABEL'):
            raise RuntimeError('preview terminal label set')
        r = subprocess.run(['kitty', '--version'], capture_output=True, text=True, timeout=2)
        if r.stdout.strip(): kitty_ver = r.stdout.strip()
    except Exception:
        pass
    gpu = gpu_name()
    rows = [
        ('OS', os_name()),
        ('Device', device_name()),
        ('Shell', shell),
        ('Terminal', kitty_ver),
        ('CPU', cpu_name()),
        ('GPU', gpu),
        ('RAM', memory_usage()),
        ('Disk', disk_usage()),
        ('Battery', battery_status()),
    ]
    row_y = y + 68
    row_h = 37
    for label, value in rows:
        draw.text((x+24, row_y), label, font=label_font, fill=(45, 202, 243, 250))
        max_chars = 48 if label in {'OS', 'Device', 'CPU'} else 46
        value = shorten(value, max_chars)
        draw.text((x+150, row_y), value, font=value_font, fill=PALE)
        row_y += row_h

    # Small corner marks echo the blueprint wallpaper, but remain subtle.
    for cx, cy in [(45, 42), (1170, 42), (45, 1008)]:
        draw.line((cx-10, cy, cx+10, cy), fill=(25, 113, 178, 140), width=2)
        draw.line((cx, cy-10, cx, cy+10), fill=(25, 113, 178, 140), width=2)

    canvas.save(out, optimize=True)
    print(f'Built transparent welcome overlay: {out} ({W}x{H})')
    print('The 10_background_blueprint.png remains a separate Kitty wallpaper, so `clear` removes the overlay but leaves the wallpaper.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
