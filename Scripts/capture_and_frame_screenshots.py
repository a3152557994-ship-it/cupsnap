#!/usr/bin/env python3
"""Boot iOS Simulators, capture real CupSnap native UI screenshots (CN + EN),
and frame them into App Store 6.5" iPhone (1284x2778) and 13" iPad (2064x2752) showcases."""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
DERIVED = ROOT / "build" / "SimDerived"
RAW_DIR = ROOT / "build" / "raw_screens"
OUT_ROOT = Path("/Users/wang/OPC/media/20261121-cupsnap/appstore")

IPHONE_UDID = "763788AE-549A-4E0A-8D30-128A44F000E9"  # iPhone 18 Pro Max
IPAD_UDID = "578123F2-ECF5-49A3-AF3B-08157D9471AD"    # iPad Pro 13-inch (M5)
BUNDLE_ID = "com.yanghe.cupsnap"

FONT_CN = "/System/Library/Fonts/Hiragino Sans GB.ttc"
FONT_CN_FALLBACK = "/System/Library/Fonts/STHeiti Medium.ttc"
FONT_EN = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def load_font(size: int, bold: bool = True, cn: bool = True) -> ImageFont.FreeTypeFont:
    if cn:
        if Path(FONT_CN).exists():
            try:
                return ImageFont.truetype(FONT_CN, size=size, index=2 if bold else 0)
            except Exception:
                return ImageFont.truetype(FONT_CN, size=size, index=0)
        return ImageFont.truetype(FONT_CN_FALLBACK, size=size, index=0)
    if Path(FONT_EN).exists():
        return ImageFont.truetype(FONT_EN, size=size)
    return ImageFont.truetype(FONT_CN, size=size, index=2 if bold else 0)


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=check, capture_output=True, text=True)


def build_sim_app() -> Path:
    print("[1/4] Building CupSnap for iOS Simulator...")
    subprocess.run([
        "xcodebuild",
        "-project", str(ROOT / "CupSnap.xcodeproj"),
        "-scheme", "CupSnap",
        "-configuration", "Debug",
        "-destination", f"platform=iOS Simulator,id={IPHONE_UDID}",
        "-derivedDataPath", str(DERIVED),
        "CODE_SIGNING_ALLOWED=NO",
        "build",
    ], check=True)
    app_path = DERIVED / "Build" / "Products" / "Debug-iphonesimulator" / "CupSnap.app"
    if not app_path.exists():
        raise RuntimeError(f"Built app not found at {app_path}")
    return app_path


def capture_device_screens(udid: str, app_path: Path, device_tag: str, screens: list[str], langs: list[str]) -> dict[tuple[str, str], Path]:
    print(f"[2/4] Booting simulator {device_tag} ({udid})...")
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])
    run(["xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100", "--wifiBars", "3", "--cellularBars", "4"], check=False)
    run(["xcrun", "simctl", "install", udid, str(app_path)])

    captured: dict[tuple[str, str], Path] = {}
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    run(["xcrun", "simctl", "launch", udid, BUNDLE_ID], check=False)
    time.sleep(2.5)
    run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False)
    time.sleep(0.5)

    for lang in langs:
        for screen in screens:
            run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False)
            time.sleep(0.4)
            run(["xcrun", "simctl", "launch", udid, BUNDLE_ID, "-ui_lang", lang, "-ui_demo_screen", screen])
            out_png = RAW_DIR / f"{device_tag}_{lang}_{screen}.png"
            for attempt in range(4):
                time.sleep(2.3 if attempt == 0 else 1.4)
                run(["xcrun", "simctl", "io", udid, "screenshot", str(out_png)])
                if out_png.stat().st_size > 40_000:
                    break
            captured[(lang, screen)] = out_png
            print(f"  ✓ Captured {out_png.name} ({out_png.stat().st_size // 1024} KB)")

    run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False)
    run(["xcrun", "simctl", "shutdown", udid], check=False)
    return captured


def draw_rounded_paste(canvas: Image.Image, shot: Image.Image, box: tuple[int, int, int, int], radius: int, bezel_color=(56, 38, 27)) -> None:
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    resized = shot.convert("RGBA").resize((w, h), Image.Resampling.LANCZOS)

    draw = ImageDraw.Draw(canvas)
    pad = int(w * 0.022)
    # Soft warm shadow
    draw.rounded_rectangle([x0 - pad + 8, y0 - pad + 18, x1 + pad + 8, y1 + pad + 18], radius=radius + pad, fill=(214, 196, 174))
    draw.rounded_rectangle([x0 - pad, y0 - pad, x1 + pad, y1 + pad], radius=radius + pad, fill=bezel_color)

    mask = Image.new("L", (w, h), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle([0, 0, w, h], radius=radius, fill=255)
    canvas.paste(resized, (x0, y0), mask)


def compose_store_slide(
    raw_png: Path,
    out_png: Path,
    target_size: tuple[int, int],
    badge: str,
    title: str,
    subtitle: str,
    bg_rgb: tuple[int, int, int],
    badge_rgb: tuple[int, int, int],
    is_cn: bool,
    is_ipad: bool = False,
) -> None:
    W, H = target_size
    canvas = Image.new("RGB", (W, H), bg_rgb)
    draw = ImageDraw.Draw(canvas)

    # Subtle decorative pastel circles
    dot_c = (max(0, bg_rgb[0] - 10), max(0, bg_rgb[1] - 12), max(0, bg_rgb[2] - 14))
    draw.ellipse([W - int(W * 0.42), -int(H * 0.06), W + int(W * 0.14), int(H * 0.20)], fill=dot_c)
    draw.ellipse([-int(W * 0.20), int(H * 0.72), int(W * 0.34), int(H * 1.04)], fill=dot_c)

    ink_color = (61, 38, 24)
    sub_color = (126, 98, 80)

    badge_font = load_font(int(W * (0.022 if is_ipad else 0.032)), bold=True, cn=is_cn)
    title_font = load_font(int(W * (0.044 if is_ipad else 0.064)), bold=True, cn=is_cn)
    sub_font = load_font(int(W * (0.023 if is_ipad else 0.035)), bold=False, cn=is_cn)

    # Top badge pill
    tb = draw.textbbox((0, 0), badge, font=badge_font)
    bw, bh = tb[2] - tb[0], tb[3] - tb[1]
    px, py = int(W * 0.034), int(H * 0.008)
    pill_w = bw + px * 2
    pill_h = bh + py * 2
    top_y = int(H * 0.048)
    draw.rounded_rectangle([(W - pill_w) // 2, top_y, (W + pill_w) // 2, top_y + pill_h], radius=pill_h // 2, fill=badge_rgb)
    draw.text(((W - bw) // 2, top_y + py - tb[1]), badge, font=badge_font, fill=(255, 253, 249))

    # Main Headline
    y_cursor = top_y + pill_h + int(H * 0.022)
    for line in title.split("\n"):
        lb = draw.textbbox((0, 0), line, font=title_font)
        lw, lh = lb[2] - lb[0], lb[3] - lb[1]
        draw.text(((W - lw) // 2, y_cursor), line, font=title_font, fill=ink_color)
        y_cursor += lh + int(H * 0.014)

    # Subtitle
    sb = draw.textbbox((0, 0), subtitle, font=sub_font)
    sw = sb[2] - sb[0]
    draw.text(((W - sw) // 2, y_cursor + int(H * 0.006)), subtitle, font=sub_font, fill=sub_color)

    # Framed simulator shot
    shot = Image.open(raw_png)
    shot_aspect = shot.width / shot.height
    frame_top = y_cursor + int(H * 0.055)
    max_h = H - frame_top - int(H * 0.042)
    max_w = int(W * (0.78 if is_ipad else 0.80))

    fit_w = min(max_w, int(max_h * shot_aspect))
    fit_h = int(fit_w / shot_aspect)
    if fit_h > max_h:
        fit_h = max_h
        fit_w = int(fit_h * shot_aspect)

    x0 = (W - fit_w) // 2
    y0 = frame_top + (max_h - fit_h) // 2
    draw_rounded_paste(canvas, shot, (x0, y0, x0 + fit_w, y0 + fit_h), radius=int(fit_w * 0.068))

    out_png.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_png, "PNG", optimize=True)


def main() -> int:
    app_path = build_sim_app()
    screens = ["wall", "add", "poster", "stats"]
    langs = ["zh", "en"]

    iphone_shots = capture_device_screens(IPHONE_UDID, app_path, "iphone", screens, langs)
    ipad_shots = capture_device_screens(IPAD_UDID, app_path, "ipad", screens, langs)

    slides = {
        "zh-Hans": [
            ("wall", "01_wall.png", "0广告纯免费 · 治愈手账", "把每天喝的奶茶咖啡\n贴成彩色贴纸日历", "打开即贴无需登录 · 支持桌面小组件", (250, 243, 232), (122, 70, 39)),
            ("add", "02_add_ocr.png", "本地 AI 离线抠图 + 识小票", "拍杯子秒变白边贴纸\n拍小票0.3秒填表", "内置100+热门与小众品牌 · 爷爷不泡茶也能认", (241, 247, 239), (88, 137, 100)),
            ("poster", "03_poster.png", "小红书 3:4 黄金比例", "一键生成月度续命海报\n解锁你的饮品人设", "3套神仙手账主题 · 无水印高清直出相册", (253, 240, 243), (206, 92, 118)),
            ("stats", "04_stats_backup.png", "换手机永不丢数据", "咖啡因消费一目了然\n一键备份随时恢复", "100% 本地隐私 · 支持 JSON / CSV 导出", (246, 239, 229), (105, 65, 42)),
        ],
        "en-US": [
            ("wall", "01_wall.png", "100% Free · Zero Ads", "Turn Daily Boba & Coffee\ninto a Sticker Wall", "Instant calendar logging with Home Screen widgets", (250, 243, 232), (122, 70, 39)),
            ("add", "02_add_ocr.png", "On-Device Vision AI", "1-Tap Cup Cutout Stickers\n& Offline Receipt OCR", "Auto-fills brand, sugar, ice & price in 0.3 seconds", (241, 247, 239), (88, 137, 100)),
            ("poster", "03_poster.png", "Made to Share", "Export Aesthetic 3:4\nMonthly Drink Posters", "3 pastel themes with your fun caffeine persona", (253, 240, 243), (206, 92, 118)),
            ("stats", "04_stats_backup.png", "Local Privacy First", "Track Spend & Caffeine\nwith 1-Tap Backup", "Export JSON or CSV anytime — never lose a cup", (246, 239, 229), (105, 65, 42)),
        ],
    }

    print("[3/4] Framing 6.5\" iPhone (1284x2778) & 13\" iPad (2064x2752) App Store screenshots...")
    for locale, items in slides.items():
        lang_key = "zh" if locale == "zh-Hans" else "en"
        is_cn = locale == "zh-Hans"
        for screen, fname, badge, title, sub, bg, bcol in items:
            compose_store_slide(
                iphone_shots[(lang_key, screen)],
                OUT_ROOT / locale / "iphone65" / fname,
                (1284, 2778), badge, title, sub, bg, bcol, is_cn, is_ipad=False,
            )
            compose_store_slide(
                ipad_shots[(lang_key, screen)],
                OUT_ROOT / locale / "ipad13" / fname,
                (2064, 2752), badge, title, sub, bg, bcol, is_cn, is_ipad=True,
            )

    print(f"[4/4] Done! All App Store screenshots ready in {OUT_ROOT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
