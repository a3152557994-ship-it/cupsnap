#!/usr/bin/env python3
"""Generate CupSnap Xiaohongshu 3:4 viral promo carousel (5 images) + 15s 9:16 vertical hook video (<20MB)."""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("/Users/wang/OPC/projects/cupsnap")
RAW_DIR = ROOT / "build" / "raw_screens"
MEDIA_OUT = ROOT / "release" / "media"
MEDIA_MIRROR = Path("/Users/wang/OPC/media/20261121-cupsnap/promo")
LIFESTYLE_BG = Path("/Users/wang/.codex/generated_images/01a1fc64-0e5a-7f80-b2e3-4a32a27b378d/exec-8c41cdb1-3f75-4835-be14-2c312ada70c6.png")

FONT_CN = "/System/Library/Fonts/Hiragino Sans GB.ttc"


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_CN, size=size, index=2 if bold else 0)


def paste_phone(canvas: Image.Image, shot_path: Path, box: tuple[int, int, int, int], radius: int = 44) -> None:
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    shot = Image.open(shot_path).convert("RGBA").resize((w, h), Image.Resampling.LANCZOS)
    draw = ImageDraw.Draw(canvas)
    pad = 12
    draw.rounded_rectangle([x0 - pad + 8, y0 - pad + 14, x1 + pad + 8, y1 + pad + 14], radius=radius + pad, fill=(208, 188, 166))
    draw.rounded_rectangle([x0 - pad, y0 - pad, x1 + pad, y1 + pad], radius=radius + pad, fill=(56, 38, 27))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w, h], radius=radius, fill=255)
    canvas.paste(shot, (x0, y0), mask)


def make_cover_lifestyle(out_path: Path) -> None:
    W, H = 1080, 1440
    bg = Image.open(LIFESTYLE_BG).convert("RGB")
    scale = max(W / bg.width, H / bg.height)
    bg = bg.resize((int(bg.width * scale), int(bg.height * scale)), Image.Resampling.LANCZOS)
    left = (bg.width - W) // 2
    top = (bg.height - H) // 2
    canvas = bg.crop((left, top, left + W, top + H))
    draw = ImageDraw.Draw(canvas)

    # Top badge pill
    badge = "0广告纯免费 · 独立开发听劝版"
    f_b = font(32, True)
    bb = draw.textbbox((0, 0), badge, font=f_b)
    draw.rounded_rectangle([64, 58, 64 + (bb[2] - bb[0]) + 52, 58 + (bb[3] - bb[1]) + 28], radius=30, fill=(122, 70, 39))
    draw.text((90, 68), badge, font=f_b, fill=(255, 253, 249))

    # Big warm cocoa headline in clean top 38%
    draw.text((64, 152), "拍一杯奶茶秒变贴纸", font=font(82, True), fill=(61, 38, 24))
    draw.text((64, 254), "贴满整个月也太治愈了！", font=font(76, True), fill=(198, 78, 104))
    draw.text((64, 356), "离线自动抠白边 · 拍小票认出爷爷不泡茶 & 东方茉兰", font=font(33, False), fill=(116, 86, 67))

    # Subtle bottom-right real phone floating preview pill
    wall_shot = RAW_DIR / "iphone_zh_wall.png"
    if wall_shot.exists():
        # Small sleek sticker callout tag at bottom left
        draw.rounded_rectangle([64, 1308, 668, 1384], radius=24, fill=(255, 253, 249))
        draw.text((92, 1327), "App 搜「贴一杯」· 网页也能免费玩", font=font(29, True), fill=(122, 70, 39))

    canvas.save(out_path, "PNG", optimize=True)


def make_showcase_card(
    out_path: Path,
    badge: str,
    badge_color: tuple[int, int, int],
    title1: str,
    title2: str,
    subtitle: str,
    bg_color: tuple[int, int, int],
    shots: list[Path],
) -> None:
    W, H = 1080, 1440
    canvas = Image.new("RGB", (W, H), bg_color)
    draw = ImageDraw.Draw(canvas)

    f_b = font(30, True)
    bb = draw.textbbox((0, 0), badge, font=f_b)
    draw.rounded_rectangle([64, 54, 64 + (bb[2] - bb[0]) + 48, 54 + (bb[3] - bb[1]) + 26], radius=28, fill=badge_color)
    draw.text((88, 63), badge, font=f_b, fill=(255, 253, 249))

    draw.text((64, 144), title1, font=font(72, True), fill=(61, 38, 24))
    draw.text((64, 232), title2, font=font(68, True), fill=badge_color)
    draw.text((64, 326), subtitle, font=font(32, False), fill=(124, 96, 78))

    if len(shots) == 2:
        paste_phone(canvas, shots[0], (72, 412, 514, 1368), radius=40)
        paste_phone(canvas, shots[1], (566, 412, 1008, 1368), radius=40)
    else:
        paste_phone(canvas, shots[0], (300, 404, 780, 1382), radius=44)

    canvas.save(out_path, "PNG", optimize=True)


def make_vertical_video(out_mp4: Path) -> None:
    W, H = 1080, 1920
    tmp_dir = ROOT / "build" / "video_frames"
    tmp_dir.mkdir(parents=True, exist_ok=True)

    wall = RAW_DIR / "iphone_zh_wall.png"
    add = RAW_DIR / "iphone_zh_add.png"
    poster = RAW_DIR / "iphone_zh_poster.png"
    stats = RAW_DIR / "iphone_zh_stats.png"

    scenes = [
        ("s1.png", (250, 243, 232), (122, 70, 39), "痛点 1 · 照片全在相册吃灰？", "受够奶茶软件搜不到小众店\n还动不动弹广告逼充会员？", "自己搓了个 0 广告纯免费「贴一杯」", wall),
        ("s2.png", (241, 247, 239), (88, 137, 100), "黑科技 · 本地离线 AI", "拍杯子 1 秒自动抠白边贴纸\n拍小票 0.3 秒自动填表", "爷爷不泡茶 · 东方茉兰 · 100+品牌全认识", add),
        ("s3.png", (253, 240, 243), (206, 92, 118), "小红书爆款晒图神器", "月底一键出 3:4 续命海报\n解锁你的饮品专属称号", "3 套高颜值奶油手账配色 · 无水印直出", poster),
        ("s4.png", (246, 239, 229), (105, 65, 42), "100% 纯免费 · 永不丢数据", "咖啡因消费账单一眼看清\n一键备份换手机不丢记录", "App 搜「贴一杯」· 评论区报你本月喝了几杯", stats),
    ]

    frame_paths = []
    for fname, bg, accent, badge, title, sub, shot in scenes:
        c = Image.new("RGB", (W, H), bg)
        d = ImageDraw.Draw(c)
        fb = font(34, True)
        bb = d.textbbox((0, 0), badge, font=fb)
        bw, bh = bb[2] - bb[0], bb[3] - bb[1]
        d.rounded_rectangle([(W - bw - 60) // 2, 105, (W + bw + 60) // 2, 105 + bh + 32], radius=34, fill=accent)
        d.text(((W - bw) // 2, 118), badge, font=fb, fill=(255, 253, 249))

        y = 218
        for line in title.split("\n"):
            ft = font(66, True)
            lb = d.textbbox((0, 0), line, font=ft)
            d.text(((W - (lb[2] - lb[0])) // 2, y), line, font=ft, fill=(61, 38, 24))
            y += (lb[3] - lb[1]) + 24

        fs = font(34, False)
        sb = d.textbbox((0, 0), sub, font=fs)
        d.text(((W - (sb[2] - sb[0])) // 2, y + 10), sub, font=fs, fill=accent)

        paste_phone(c, shot, (222, 488, 858, 1824), radius=54)
        fp = tmp_dir / fname
        c.save(fp, "PNG")
        frame_paths.append(fp)

    # Concatenate into crisp 15s (3.75s x 4) H.264 vertical video with subtle gentle fade transitions
    cmd = [
        "/Users/wang/.local/bin/ffmpeg", "-y",
        "-loop", "1", "-t", "3.8", "-i", str(frame_paths[0]),
        "-loop", "1", "-t", "3.8", "-i", str(frame_paths[1]),
        "-loop", "1", "-t", "3.8", "-i", str(frame_paths[2]),
        "-loop", "1", "-t", "3.8", "-i", str(frame_paths[3]),
        "-filter_complex",
        "[0:v]scale=1080:1920,fps=30,fade=t=in:st=0:d=0.3,fade=t=out:st=3.5:d=0.3[v0];"
        "[1:v]scale=1080:1920,fps=30,fade=t=in:st=0:d=0.3,fade=t=out:st=3.5:d=0.3[v1];"
        "[2:v]scale=1080:1920,fps=30,fade=t=in:st=0:d=0.3,fade=t=out:st=3.5:d=0.3[v2];"
        "[3:v]scale=1080:1920,fps=30,fade=t=in:st=0:d=0.3,fade=t=out:st=3.5:d=0.3[v3];"
        "[v0][v1][v2][v3]concat=n=4:v=1:a=0[v]",
        "-map", "[v]",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23", "-movflags", "+faststart",
        str(out_mp4),
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    shutil.rmtree(tmp_dir, ignore_errors=True)


def main() -> int:
    MEDIA_OUT.mkdir(parents=True, exist_ok=True)
    MEDIA_MIRROR.mkdir(parents=True, exist_ok=True)

    make_cover_lifestyle(MEDIA_OUT / "xhs_01_cover_lifestyle.png")
    make_showcase_card(
        MEDIA_OUT / "xhs_02_wall_showcase.png",
        "0广告纯免费 · 打开直接贴",
        (122, 70, 39),
        "每天喝一杯贴一张",
        "把整月攒成彩色贴纸墙",
        "不用注册登录 · 桌面小组件一键直达记录",
        (250, 243, 232),
        [RAW_DIR / "iphone_zh_wall.png", RAW_DIR / "iphone_zh_add.png"],
    )
    make_showcase_card(
        MEDIA_OUT / "xhs_03_ocr_cutout.png",
        "专治虚假 AI 填表 · 100% 离线",
        (88, 137, 100),
        "拍杯子秒抠白边贴纸",
        "拍小票 0.3 秒填糖度价格",
        "爷爷不泡茶 · 东方茉兰 · 100+热门与小众品牌全收录",
        (241, 247, 239),
        [RAW_DIR / "iphone_zh_add.png"],
    )
    make_showcase_card(
        MEDIA_OUT / "xhs_04_poster_export.png",
        "小红书 3:4 黄金比例直出",
        (206, 92, 118),
        "月底一键出续命海报",
        "看看谁是品牌荣誉股东",
        "焦糖奶油 / 抹茶和纸 / 草莓波点 · 无水印存相册",
        (253, 240, 243),
        [RAW_DIR / "iphone_zh_poster.png"],
    )
    make_showcase_card(
        MEDIA_OUT / "xhs_05_backup_stats.png",
        "换手机再也不丢一年心血",
        (105, 65, 42),
        "咖啡因与消费一目了然",
        "一键导出备份永久保存",
        "不依赖云端服务器 · 支持 JSON 备份与 CSV 表格导出",
        (246, 239, 229),
        [RAW_DIR / "iphone_zh_stats.png"],
    )
    make_vertical_video(MEDIA_OUT / "cupsnap_hook_15s_9x16.mp4")

    for p in MEDIA_OUT.iterdir():
        shutil.copy2(p, MEDIA_MIRROR / p.name)
        print(f"  ✓ {p.name} ({p.stat().st_size // 1024} KB)")

    if LIFESTYLE_BG.exists():
        shutil.rmtree(LIFESTYLE_BG.parent, ignore_errors=True)
        print("  ✓ Cleaned temporary codex generated_images cache.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
