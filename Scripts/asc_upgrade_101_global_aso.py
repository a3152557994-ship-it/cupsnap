#!/usr/bin/env python3
"""Create CupSnap 1.0.1 (Build 2) in App Store Connect with 11-locale global ASO (HK/TW zh-Hant, JP, KR, US 10-locale cross-index), upload screenshots, attach Build 2, and submit for review while 1.0.0 stays live."""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asc_full_sync import asc, sync_shots

APP_ID = "6837625024"
SHOT_ROOT = Path("/Users/wang/OPC/media/20261121-cupsnap/appstore")
URLS = {
    "privacy": "https://a3152557994-ship-it.github.io/cupsnap/privacy.html",
    "support": "https://a3152557994-ship-it.github.io/cupsnap/support.html",
    "marketing": "https://a3152557994-ship-it.github.io/cupsnap/",
}

LOCALES = {
    "zh-Hans": {
        "name": "贴一杯 - 奶茶咖啡拍照抠图贴纸日历",
        "subtitle": "0广告离线识小票 · 自动抠杯变贴纸",
        "keywords": "奶茶记录,咖啡打卡,饮品手账,奶茶贴纸,喝水日历,咖啡因计算,霸王茶姬,瑞幸喜茶,古茗茶百道,热量糖分,账单统计,桌面小组件,不干胶,续命水",
        "promotionalText": "100% 纯免费 · 0 广告 · 免登录！对准奶茶或冰咖啡拍一张，1 秒离线抠出手工白边手账贴纸；拍外卖小票 0.3 秒自动填好品牌糖度价格，月底一键生成 3:4 续命饮品海报！",
        "whatsNew": "• 新增港台繁体中文、日文、韩文等 11 个地区语言支持\n• 优化月度 3:4 手账海报导出体验与反馈通道\n• 持续坚持 100% 离线隐私优先、0 开屏广告、纯免费体验",
        "description": (
            "每次点完奶茶或冰美式，想记下来却嫌手填麻烦？别的打卡软件要么搜不到街角独立咖啡馆，要么满屏开屏广告与诱导付费？\n\n"
            "「贴一杯 CupSnap」是一款专为奶茶控、咖啡脑袋与手账爱好者打造的 0 广告离线贴纸日历——\n\n"
            "【核心亮点】\n"
            "1. 拍杯子 1 秒变手工白边贴纸：基于 Apple Vision 本地离线抠图，自动剥离杂乱桌面背景，套上手工白边不干胶、拍立得或邮票边框，贴满整月彩色日历墙。\n"
            "2. 拍杯身小票 0.3 秒自动填表：离线 OCR 智能识别 100+ 连锁与独立茶咖品牌、饮品名、实付价格、糖度（不另外加糖/三分糖等）与冰量，也支持任意自定义小众店名。\n"
            "3. 一键导出 3:4 月度晒图海报：内置焦糖奶油、抹茶拿铁、莓果奶盖多套手账配色，自动生成「品牌荣誉股东」称号、月度总杯数、花费与咖啡因汇总海报，无水印直发社交平台。\n"
            "4. 桌面小组件 + 永不丢数据备份：支持主屏幕今日饮品贴纸组件；支持一键将全部记录导出为本地 JSON 备份或 Excel CSV 表格，换机永不丢记录。\n\n"
            "隐私承诺：无需注册登录，无任何云端服务器，所有饮品照片与账单 100% 保存在您自己的手机本地。"
        ),
    },
    "zh-Hant": {
        "name": "貼一杯 - 手搖飲與咖啡貼紙打卡日曆",
        "subtitle": "0廣告離線拍收據 · 自動去背變貼紙",
        "keywords": "手搖飲紀錄,珍珠奶茶,珍奶打卡,飲料日曆,咖啡紀錄,貼紙手帳,咖啡因計算,糖度熱量,買一送一,五十嵐迷客夏,得正龜記,霸王茶姬,記帳統計,桌面小工具",
        "promotionalText": "100% 免費 · 0 廣告 · 免註冊！對準手搖飲或冰咖啡拍一張，1 秒離線去背生成手工白邊貼紙；拍杯身貼紙收據 0.3 秒自動帶入品牌甜度冰塊與價格，月底一鍵匯出 3:4 飲品海報！",
        "whatsNew": "• 全新支援繁體中文（香港 / 台灣手搖飲與連鎖咖啡詞庫體驗優化）\n• 提升 3:4 月度飲品貼紙海報匯出畫質與順暢度\n• 100% 本機離線運算、0 廣告、免登入隱私承諾",
        "description": (
            "每天一杯手搖飲或冰拿鐵，想紀錄卻懶得手動打字？\n\n"
            "「貼一杯 CupSnap」是專為手搖飲控、咖啡迷與電子手帳愛好者設計的 0 廣告離線貼紙日曆：\n"
            "• 拍照 1 秒變白邊手帳貼紙：採用 Apple Vision 本機離線去背，拍下飲料杯瞬間變成可愛白邊貼紙貼進月曆牆，支援自由輸入任何巷口自創品牌與獨立咖啡廳。\n"
            "• 杯身貼紙 / 收據 0.3 秒自動辨識：離線辨識品牌、品項、甜度（無糖/微糖/一分糖）、冰塊與金額，省去繁瑣手填。\n"
            "• 一鍵產出 3:4 月度手搖戰績海報：自動統計本月總杯數、總花費、最愛品牌與咖啡因攝取量，無浮水印直接存進相簿分享 IG / Threads / 小紅書。\n"
            "• 桌面 Widget 小工具 + 本機 JSON/CSV 完整備份：免綁定帳號，換手機一鍵還原永不遺失資料。"
        ),
    },
    "en-US": {
        "name": "CupSnap: Boba & Coffee Diary",
        "subtitle": "Drink Sticker Calendar & Log",
        "keywords": "bubble tea,milk tea,caffeine,iced latte,matcha,espresso,tracker,cutout,journal,receipt ocr,widget",
        "promotionalText": "100% Free, Zero Ads, No Login! Snap any boba or iced coffee to create die-cut white-border stickers offline in 1s, scan receipts & export 3:4 monthly posters.",
        "whatsNew": "• Added 11 international localizations & improved receipt OCR brand matching\n• Smoother high-res 3:4 monthly drink sticker poster export\n• 100% Free, Zero Ads, 100% On-Device Apple Vision privacy",
        "description": (
            "Turn every boba run, matcha latte, and iced coffee into a colorful die-cut sticker calendar — 100% free, zero ads, and completely offline.\n\n"
            "WHY CUPSNAP?\n"
            "• 1-Second Die-Cut Cup Stickers: Powered by on-device Apple Vision subject lifting. Snap your cup and watch messy tables vanish into a crisp white-bordered planner sticker, Polaroid frame, or postage stamp.\n"
            "• 0.3s Offline Receipt & Cup-Label OCR: Scan any cafe receipt or cup sticker to auto-fill brand, drink name, price, sweetness (0%–100%), and ice level — plus type any indie cafe freely.\n"
            "• 3:4 Aesthetic Monthly Poster Studio: Export watermark-free monthly drink wrap-up posters showing your cup count, total spend, top cafe, and caffeine intake.\n"
            "• Home Screen Widget & Local JSON/CSV Backup: Your photos and spending stay strictly on your iPhone with 1-tap backup to iCloud Drive."
        ),
    },
    "en-GB": {
        "name": "CupSnap: Coffee & Boba Diary",
        "subtitle": "Offline Drink Sticker Log",
        "keywords": "bubble tea,iced coffee,flat white,matcha,caffeine tracker,cafe journal,sticker planner,spending,ocr",
        "promotionalText": "100% Free & Ad-Free! Turn iced coffee, matcha & bubble tea photos into die-cut white-border stickers offline in 1s, scan cafe receipts & export monthly posters.",
        "whatsNew": "• Expanded international language support & smoother 3:4 monthly poster export\n• 100% Free, Zero Ads, Zero Cloud Upload",
        "description": (
            "Turn every flat white, iced matcha, and bubble tea into a colourful die-cut sticker calendar — 100% free, zero ads, and completely offline on your iPhone & iPad.\n\n"
            "• 1-Second Cup Cutout Stickers via on-device Apple Vision\n"
            "• Instant Offline Receipt & Cup Label OCR for price, sugar & ice\n"
            "• Aesthetic 3:4 Monthly Drink Wrap-Up Poster & CSV/JSON Backup"
        ),
    },
    "ja": {
        "name": "CupSnap: カフェ・タピオカ記録帳",
        "subtitle": "写真から1秒で白フチステッカーカレンダー",
        "keywords": "カフェ巡り,推し活,コーヒー記録,ドリンク日記,シール帳,手帳,カフェイン管理,抹茶ラテ,スタバ,レシート読取,家計簿,広告なし,無料",
        "promotionalText": "完全無料・広告ゼロ・登録不要！カフェやタピオカの写真を1秒で白フチシールに切り抜いてカレンダーにペタッ。レシート自動読取＆月間まとめポスター出力対応！",
        "whatsNew": "• 日本語を含む11言語のストア表示に対応\n• 月間ドリンクまとめポスターの高画質保存を改善",
        "description": (
            "毎日のカフェ巡り、アイスコーヒー、抹茶ラテ、タピオカを可愛い「白フチステッカー」にしてカレンダーに貼れる無料・広告なしのオフライン記録アプリです。\n"
            "• 写真から1秒で背景切り抜きステッカー作成（Apple Vision完全オンデバイス処理）\n"
            "• レシートやカップラベルから店名・金額・甘さを自動読取\n"
            "• SNSシェアに最適な3:4月間ドリンクまとめポスター出力＆JSON/CSVバックアップ対応"
        ),
    },
    "ko": {
        "name": "CupSnap: 카페·버블티 스티커 일기",
        "subtitle": "음료 사진 1초 누끼 스티커 캘린더",
        "keywords": "카페투어,커피기록,아아,말차라떼,공차,다이어리꾸미기,다꾸,카페인추적,영수증인식,음료가계부,무광고,오프라인,위젯",
        "promotionalText": "100% 무료 · 광고 없음 · 로그인 불필요! 커피와 버블티 사진을 1초 만에 흰 테두리 다꾸 스티커로 만들어 달력에 붙이고 월간 음료 포스터를 저장하세요.",
        "whatsNew": "• 한국어 포함 11개 언어 지원 및 월간 포스터 고화질 저장 개선\n• 100% 기기 내 오프라인 처리 · 광고 제로",
        "description": (
            "매일 마시는 아이스 아메리카노, 말차 라떼, 버블티를 귀여운 흰 테두리 다꾸 스티커로 만들어 달력에 기록하세요!\n"
            "• 기기 내 Apple Vision으로 1초 만에 컵 배경 제거 스티커 생성\n"
            "• 영수증 및 컵 라벨 오프라인 자동 인식 (브랜드, 가격, 당도, 얼음량)\n"
            "• 감성 3:4 월간 음료 결산 포스터 저장 및 로컬 JSON/CSV 백업 지원"
        ),
    },
    "vi": {
        "name": "CupSnap: Nhật Ký Trà Sữa",
        "subtitle": "Lịch Sticker Cà Phê & Đồ Uống",
        "keywords": "tra sua,ca phe,matcha,boba,sticker,lich uong nuoc,chi tieu,caffeine,khong quang cao,offline,diary",
        "promotionalText": "Miễn phí 100%, không quảng cáo! Chụp ly trà sữa hoặc cà phê tạo sticker viền trắng trong 1 giây, quét hóa đơn ngoại tuyến và xuất poster tổng kết tháng 3:4.",
        "whatsNew": "• Hỗ trợ đa ngôn ngữ & nâng cấp xuất poster tổng kết đồ uống hàng tháng\n• Miễn phí 100%, không quảng cáo, bảo mật ngoại tuyến",
        "description": (
            "Biến mỗi ly trà sữa, cà phê muối hay matcha latte thành bộ lịch sticker viền trắng cực xinh — hoàn toàn miễn phí, không quảng cáo và chạy 100% ngoại tuyến.\n"
            "• Tách nền ly nước tạo sticker trong 1 giây ngay trên máy\n"
            "• Quét hóa đơn tự điền thương hiệu, giá tiền, mức đường & đá\n"
            "• Xuất poster 3:4 tổng kết số ly & chi tiêu hàng tháng"
        ),
    },
    "es-MX": {
        "name": "CupSnap: Diario Café y Boba",
        "subtitle": "Calendario Stickers Bebidas",
        "keywords": "cafe helado,te de burbujas,tapioca,cafeina,matcha,agenda,pegatinas,gastos,recibos,sin anuncios,ocr",
        "promotionalText": "¡100% Gratis y Sin Anuncios! Convierte fotos de tu café helado o boba en stickers con borde blanco en 1s, escanea tickets sin conexión y crea pósters mensuales.",
        "whatsNew": "• Soporte multilingüe ampliado y exportación mejorada de póster mensual 3:4\n• 100% gratis, sin anuncios y 100% privado en tu iPhone",
        "description": (
            "Convierte cada café helado, matcha latte y té de burbujas (boba) en un calendario lleno de stickers recortados automáticamente — 100% gratis, sin anuncios y sin conexión.\n"
            "• Recorte automático de vasos en 1 segundo con Apple Vision en el dispositivo\n"
            "• Escáner OCR de tickets para precio, azúcar y hielo + póster mensual 3:4"
        ),
    },
    "fr-CA": {
        "name": "CupSnap: Journal Café & Boba",
        "subtitle": "Calendrier Autocollants Café",
        "keywords": "the aux perles,cafe glace,latte,matcha,cafeine,agenda,autocollant,budget,hors ligne,sans pub,widget",
        "promotionalText": "100 % gratuit et sans pub ! Transformez vos photos de café glacé et bubble tea en autocollants détourés en 1 s, scannez vos reçus hors ligne et créez votre affiche.",
        "whatsNew": "• Prise en charge de 11 langues et exportation d'affiches mensuelles 3:4 améliorée\n• 100 % gratuit, zéro publicité, confidentialité locale",
        "description": (
            "Transformez chaque café glacé, matcha et bubble tea en un calendrier d'autocollants à bordure blanche — 100 % gratuit, sans publicité et 100 % hors ligne.\n"
            "• Détourage instantané en 1 seconde sur l'appareil\n"
            "• Lecture OCR des reçus, suivi caféine/budget et affiche mensuelle 3:4"
        ),
    },
    "de-DE": {
        "name": "CupSnap: Kaffee & Boba Planer",
        "subtitle": "Getränke Sticker Kalender",
        "keywords": "eiskaffee,bubble tea,matcha,koffein,tagebuch,aufkleber,ausgaben,kassenbon,offline,werbefrei,widget",
        "promotionalText": "100 % kostenlos & werbefrei! Verwandle Eiskaffee- und Bubble-Tea-Fotos offline in 1 Sek. in Sticker mit weißem Rand, scanne Bons & teile dein Monats-Poster.",
        "whatsNew": "• Unterstützung für 11 Regionen & verbesserter 3:4 Monats-Poster-Export\n• 100 % kostenlos, werbefrei und lokal auf dem Gerät",
        "description": (
            "Verwandle jeden Eiskaffee, Matcha Latte und Bubble Tea in einen bunten Sticker-Kalender — 100 % kostenlos, ohne Werbung und komplett offline auf deinem iPhone.\n"
            "• Automatischer Becher-Freisteller mit weißem Sticker-Rand in 1 Sekunde\n"
            "• Offline-Kassenbon-Scanner, Koffein-/Ausgaben-Statistik & 3:4 Monats-Poster"
        ),
    },
    "pt-BR": {
        "name": "CupSnap: Diário Café e Boba",
        "subtitle": "Calendário de Adesivos Café",
        "keywords": "cafe gelado,cha de bolhas,matcha,cafeina,planner,adesivo,gastos,cupom,sem anuncios,offline,widget",
        "promotionalText": "100% grátis e sem anúncios! Transforme fotos de café gelado e bubble tea em adesivos com borda branca em 1s offline, leia recibos e gere pôsteres mensais 3:4.",
        "whatsNew": "• Novo suporte a 11 idiomas e exportação aprimorada do pôster mensal 3:4\n• 100% gratuito, sem anúncios e 100% offline",
        "description": (
            "Transforme cada café gelado, matcha e bubble tea em um calendário de adesivos recortados automaticamente — 100% gratuito, sem anúncios e totalmente offline.\n"
            "• Recorte de copo em 1 segundo com borda branca estilo planner\n"
            "• Leitura offline de recibos, controle de cafeína/gastos e pôster mensal 3:4"
        ),
    },
}


def validate_all() -> None:
    for loc, d in LOCALES.items():
        assert len(d["name"]) <= 30, f"{loc} name > 30: {len(d['name'])}"
        assert len(d["subtitle"]) <= 30, f"{loc} subtitle > 30: {len(d['subtitle'])}"
        assert len(d["keywords"]) <= 100, f"{loc} keywords > 100: {len(d['keywords'])} ({d['keywords']})"
        assert len(d["promotionalText"]) <= 170, f"{loc} promo > 170: {len(d['promotionalText'])}"
    print(f"✓ Validated all {len(LOCALES)} locales (name<=30, subtitle<=30, keywords<=100, promo<=170)")


def main() -> int:
    validate_all()

    # 1. Ensure IOS 1.0.1 version exists
    _, vers = asc("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=10")
    ver_id = None
    for v in vers.get("data", []):
        if v["attributes"]["versionString"] == "1.0.1":
            ver_id = v["id"]
            print(f"✓ Found existing IOS 1.0.1 version: {ver_id} ({v['attributes']['appStoreState']})")
            break
    if not ver_id:
        st_c, res_c = asc("POST", "/v1/appStoreVersions", {
            "data": {
                "type": "appStoreVersions",
                "attributes": {
                    "platform": "IOS",
                    "versionString": "1.0.1",
                    "copyright": "© 2026 Yang He",
                    "releaseType": "AFTER_APPROVAL",
                },
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        })
        if st_c not in (200, 201):
            print("ERROR creating 1.0.1:", st_c, res_c)
            return 1
        ver_id = res_c["data"]["id"]
        print(f"+ Created IOS 1.0.1 version: {ver_id}")

    # 2. Find editable appInfo (the one attached to PREPARE_FOR_SUBMISSION)
    _, infos = asc("GET", f"/v1/apps/{APP_ID}/appInfos?limit=10")
    info_id = None
    for inf in infos.get("data", []):
        state = inf["attributes"].get("appStoreState") or inf["attributes"].get("state")
        print(f"  appInfo {inf['id']} state={state}")
        if state in ("PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", None):
            info_id = inf["id"]
    if not info_id and infos.get("data"):
        info_id = infos["data"][0]["id"]

    _, info_locs = asc("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations?limit=50")
    imap = {x["attributes"]["locale"]: x["id"] for x in info_locs.get("data", [])}

    # 3A. Sync all 11 appInfoLocalizations first (ASC auto-creates matching appStoreVersionLocalizations!)
    for loc, d in LOCALES.items():
        iattrs = {"name": d["name"], "subtitle": d["subtitle"], "privacyPolicyUrl": URLS["privacy"]}
        if loc in imap:
            st_i, _ = asc("PATCH", f"/v1/appInfoLocalizations/{imap[loc]}", {
                "data": {"type": "appInfoLocalizations", "id": imap[loc], "attributes": iattrs}
            })
        else:
            st_i, _ = asc("POST", "/v1/appInfoLocalizations", {
                "data": {
                    "type": "appInfoLocalizations",
                    "attributes": {"locale": loc, **iattrs},
                    "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}},
                }
            })
        print(f"  ✓ appInfoLocalization {loc} -> {st_i}")

    # Re-fetch appStoreVersionLocalizations after appInfo creation so we PATCH cleanly without 409
    _, ver_locs = asc("GET", f"/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations?limit=50")
    vmap = {x["attributes"]["locale"]: x["id"] for x in ver_locs.get("data", [])}

    # 3B. Sync all 11 appStoreVersionLocalizations
    zh_en_vlocs = {}
    for loc, d in LOCALES.items():
        vattrs = {
            "description": d["description"],
            "keywords": d["keywords"],
            "promotionalText": d["promotionalText"],
            "whatsNew": d["whatsNew"],
            "supportUrl": URLS["support"],
            "marketingUrl": URLS["marketing"],
        }
        if loc in vmap:
            vloc_id = vmap[loc]
            st_v, res_v = asc("PATCH", f"/v1/appStoreVersionLocalizations/{vloc_id}", {
                "data": {"type": "appStoreVersionLocalizations", "id": vloc_id, "attributes": vattrs}
            })
        else:
            st_v, res_v = asc("POST", "/v1/appStoreVersionLocalizations", {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {"locale": loc, **vattrs},
                    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}},
                }
            })
            vloc_id = res_v["data"]["id"] if st_v in (200, 201) and isinstance(res_v, dict) and "data" in res_v else None
        if st_v not in (200, 201):
            print(f"  ! vloc {loc} returned {st_v}: {res_v}")
        else:
            print(f"  ✓ Synced vloc {loc}: {st_v} (kw={len(d['keywords'])}c)")
        if loc in ("zh-Hans", "en-US") and vloc_id:
            zh_en_vlocs[loc] = vloc_id

    # 4. Ensure screenshots on zh-Hans & en-US if empty
    for loc, vloc_id in zh_en_vlocs.items():
        _, sets = asc("GET", f"/v1/appStoreVersionLocalizations/{vloc_id}/appScreenshotSets?limit=10")
        has_shots = False
        for s in sets.get("data", []):
            _, items = asc("GET", f"/v1/appScreenshotSets/{s['id']}/appScreenshots?limit=5")
            if items.get("data"):
                has_shots = True
        if not has_shots:
            print(f"  Uploading screenshots for {loc}...")
            sync_shots(vloc_id, "APP_IPHONE_65", SHOT_ROOT / loc / "iphone65")
            sync_shots(vloc_id, "APP_IPAD_PRO_3GEN_129", SHOT_ROOT / loc / "ipad13")
        else:
            print(f"  ✓ Screenshots already inherited/present for {loc}")

    # 5. Review details
    rattrs = {
        "contactFirstName": "Yang",
        "contactLastName": "He",
        "contactPhone": "+86 196 3394 8182",
        "contactEmail": "a3152557994@gmail.com",
        "demoAccountRequired": False,
        "notes": (
            "CupSnap 1.0.1 adds 11 international store localizations and polish while keeping all core functionality "
            "100% free, ad-free, and 100% offline via Apple Vision (VNGenerateForegroundInstanceMaskRequest & VNRecognizeTextRequest). No login required."
        ),
    }
    st_r, res_r = asc("GET", f"/v1/appStoreVersions/{ver_id}/appStoreReviewDetail")
    if st_r == 200 and isinstance(res_r, dict) and res_r.get("data"):
        rd_id = res_r["data"]["id"]
        asc("PATCH", f"/v1/appStoreReviewDetails/{rd_id}", {"data": {"type": "appStoreReviewDetails", "id": rd_id, "attributes": rattrs}})
    else:
        asc("POST", "/v1/appStoreReviewDetails", {
            "data": {
                "type": "appStoreReviewDetails",
                "attributes": rattrs,
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}},
            }
        })
    print("  ✓ Review details saved")

    # 6. Wait for Build 2 VALID & attach & submit
    print("Waiting for Build 2 to finish Apple processing...")
    deadline = time.time() + 360
    attached = False
    while time.time() < deadline:
        _, blds = asc("GET", f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=5")
        b2 = next((b for b in blds.get("data", []) if b["attributes"].get("version") == "2"), None)
        if b2 and b2["attributes"].get("processingState") == "VALID":
            st_att, res_att = asc("PATCH", f"/v1/appStoreVersions/{ver_id}/relationships/build", {
                "data": {"type": "builds", "id": b2["id"]}
            })
            print(f"  ✓ Attached Build 2 ({b2['id']}) -> {st_att}")
            attached = st_att in (200, 204)
            break
        state = b2["attributes"].get("processingState") if b2 else "NOT_VISIBLE_YET"
        print(f"  ... Build 2 state: {state}")
        time.sleep(15)

    if not attached:
        print("! Build 2 still processing; run again shortly to submit.")
        return 2

    st_rs, res_rs = asc("POST", "/v1/reviewSubmissions", {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if st_rs in (200, 201):
        rs_id = res_rs["data"]["id"]
        asc("POST", "/v1/reviewSubmissionItems", {
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": rs_id}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}},
                },
            }
        })
        st_sub, res_sub = asc("PATCH", f"/v1/reviewSubmissions/{rs_id}", {
            "data": {"type": "reviewSubmissions", "id": rs_id, "attributes": {"submitted": True}}
        })
        print(f"🚀 Submitted CupSnap 1.0.1 ({rs_id}) -> {st_sub}")
        if st_sub not in (200, 201):
            print("  Submission detail:", res_sub)
    else:
        print("  reviewSubmissions status:", st_rs, res_rs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
