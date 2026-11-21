#!/usr/bin/env python3
"""Complete end-to-end App Store Connect sync & submission for CupSnap (com.yanghe.cupsnap) — 100% Free."""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Optional

KEY_ID = "BD4GFRDCQ9"
ISSUER_ID = "ccf96e7a-0987-4f4b-aa61-863fccd82c33"
KEY_PATH = "/Users/wang/.appstoreconnect/private_keys/AuthKey_BD4GFRDCQ9.p8"
BUNDLE_ID = "com.yanghe.cupsnap"

ROOT = Path(__file__).resolve().parent.parent
META_PATH = ROOT / "release" / "ASC_METADATA_READY.json"
IPA_PATH = ROOT / "dist" / "ipa" / "CupSnap.ipa"
SHOT_ROOT = Path("/Users/wang/OPC/media/20261121-cupsnap/appstore")


def b64u(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def make_jwt() -> str:
    header = b64u(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}, separators=(",", ":")).encode())
    now = int(time.time())
    payload = b64u(json.dumps({"iss": ISSUER_ID, "iat": now - 10, "exp": now + 900, "aud": "appstoreconnect-v1"}, separators=(",", ":")).encode())
    msg = f"{header}.{payload}".encode()
    der = subprocess.check_output(["openssl", "dgst", "-sha256", "-sign", KEY_PATH], input=msg)
    idx = 2 + ((der[1] & 0x7F) if (der[1] & 0x80) else 0)
    rlen = der[idx + 1]
    r = der[idx + 2 : idx + 2 + rlen].lstrip(b"\x00").rjust(32, b"\x00")
    idx = idx + 2 + rlen
    slen = der[idx + 1]
    s = der[idx + 2 : idx + 2 + slen].lstrip(b"\x00").rjust(32, b"\x00")
    return f"{header}.{payload}.{b64u(r + s)}"


def asc(method: str, path: str, body: dict | None = None) -> tuple[int, Any]:
    token = make_jwt()
    data = json.dumps(body).encode() if body is not None else None
    url = path if path.startswith("http") else f"https://api.appstoreconnect.apple.com{path}"
    req = urllib.request.Request(url, data=data, headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"}, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw


def get_all_territories() -> list[str]:
    st, res = asc("GET", "/v1/territories?limit=200")
    if st == 200 and isinstance(res, dict):
        return [t["id"] for t in res.get("data", [])]
    return ["USA", "CHN"]


def find_price_point(endpoint: str, target: float) -> Optional[str]:
    next_url: Optional[str] = endpoint
    best_id, best_diff = None, 99999.0
    for _ in range(6):
        if not next_url:
            break
        st, res = asc("GET", next_url)
        if st != 200 or not isinstance(res, dict):
            break
        for pp in res.get("data", []):
            p = pp.get("attributes", {}).get("customerPrice")
            if p is None:
                continue
            try:
                diff = abs(float(p) - target)
            except ValueError:
                continue
            if diff < best_diff:
                best_diff, best_id = diff, pp["id"]
                if diff <= 0.01:
                    return best_id
        next_url = res.get("links", {}).get("next")
    return best_id


def upload_binary_asset(reserve_ep: str, commit_ep: str, rtype: str, rel_key: str, rel_type: str, rel_id: str, png: Path) -> None:
    raw = png.read_bytes()
    md5 = hashlib.md5(raw).hexdigest()
    st, res = asc("POST", reserve_ep, {
        "data": {
            "type": rtype,
            "attributes": {"fileSize": len(raw), "fileName": png.name},
            "relationships": {rel_key: {"data": {"type": rel_type, "id": rel_id}}},
        }
    })
    if st not in (200, 201):
        print(f"    ! Reserve {png.name} failed ({st}): {res}")
        return
    asset_id = res["data"]["id"]
    for op in res["data"]["attributes"].get("uploadOperations", []):
        chunk = raw[op["offset"] : op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        req = urllib.request.Request(op["url"], data=chunk, headers=headers, method=op["method"])
        with urllib.request.urlopen(req, timeout=60):
            pass
    st2, res2 = asc("PATCH", f"{commit_ep}/{asset_id}", {
        "data": {"type": rtype, "id": asset_id, "attributes": {"uploaded": True, "sourceFileChecksum": md5}}
    })
    if st2 in (200, 204):
        print(f"    ✓ Uploaded {png.name}")
    else:
        print(f"    ! Commit {png.name} failed ({st2}): {res2}")


def sync_shots(vloc_id: str, display_type: str, folder: Path) -> None:
    pngs = sorted(folder.glob("*.png"))
    if not pngs:
        return
    _, sets = asc("GET", f"/v1/appStoreVersionLocalizations/{vloc_id}/appScreenshotSets?limit=20")
    set_id = None
    for s in sets.get("data", []) if isinstance(sets, dict) else []:
        if s["attributes"]["screenshotDisplayType"] == display_type:
            set_id = s["id"]
            _, existing = asc("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=20")
            for item in existing.get("data", []):
                asc("DELETE", f"/v1/appScreenshots/{item['id']}")
            break
    if not set_id:
        st, cset = asc("POST", "/v1/appScreenshotSets", {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display_type},
                "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": vloc_id}}},
            }
        })
        if st in (200, 201):
            set_id = cset["data"]["id"]
    if set_id:
        for png in pngs:
            upload_binary_asset("/v1/appScreenshots", "/v1/appScreenshots", "appScreenshots", "appScreenshotSet", "appScreenshotSets", set_id, png)


def sync_core_metadata(app_id: str, meta: dict[str, Any], territories: list[str], do_shots: bool) -> str:
    print("[1/4] Syncing Rights, Categories & Age Rating (4+)...")
    asc("PATCH", f"/v1/apps/{app_id}", {
        "data": {
            "type": "apps", "id": app_id,
            "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT", "primaryLocale": "zh-Hans"},
        }
    })
    _, infos = asc("GET", f"/v1/apps/{app_id}/appInfos")
    info_id = infos["data"][0]["id"]
    st_cat, _ = asc("PATCH", f"/v1/appInfos/{info_id}", {
        "data": {
            "type": "appInfos", "id": info_id,
            "relationships": {
                "primaryCategory": {"data": {"type": "appCategories", "id": meta["primaryCategory"]}},
                "secondaryCategory": {"data": {"type": "appCategories", "id": meta["secondaryCategory"]}},
            },
        }
    })
    print(f"  ✓ Categories ({meta['primaryCategory']} / {meta['secondaryCategory']}) -> {st_cat}")

    _, age_res = asc("GET", f"/v1/appInfos/{info_id}/ageRatingDeclaration")
    if isinstance(age_res, dict) and age_res.get("data"):
        age_id = age_res["data"]["id"]
        st_age, res_age = asc("PATCH", f"/v1/ageRatingDeclarations/{age_id}", {
            "data": {
                "type": "ageRatingDeclarations", "id": age_id,
                "attributes": {
                    "advertising": False,
                    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
                    "contests": "NONE",
                    "gambling": False,
                    "gamblingSimulated": "NONE",
                    "gunsOrOtherWeapons": "NONE",
                    "healthOrWellnessTopics": False,
                    "kidsAgeBand": None,
                    "lootBox": False,
                    "medicalOrTreatmentInformation": "NONE",
                    "messagingAndChat": False,
                    "parentalControls": False,
                    "profanityOrCrudeHumor": "NONE",
                    "ageAssurance": False,
                    "sexualContentGraphicAndNudity": "NONE",
                    "sexualContentOrNudity": "NONE",
                    "socialMedia": False,
                    "socialMediaAgeRestricted": False,
                    "horrorOrFearThemes": "NONE",
                    "matureOrSuggestiveThemes": "NONE",
                    "unrestrictedWebAccess": False,
                    "userGeneratedContent": False,
                    "violenceCartoonOrFantasy": "NONE",
                    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
                    "violenceRealistic": "NONE",
                },
            }
        })
        print(f"  ✓ Age rating (4+) -> {st_age}")

    print("[2/4] Setting Global Availability & Free Base Price...")
    st_av, _ = asc("GET", f"/v2/appAvailabilities/{app_id}")
    if st_av == 404:
        st_p, _ = asc("POST", "/v2/appAvailabilities", {
            "data": {
                "type": "appAvailabilities",
                "attributes": {"availableInNewTerritories": True},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "territoryAvailabilities": {"data": [{"type": "territoryAvailabilities", "id": f"${{ta-{t}}}"} for t in territories]},
                },
            },
            "included": [
                {
                    "type": "territoryAvailabilities",
                    "id": f"${{ta-{t}}}",
                    "attributes": {"available": True, "releaseDate": None, "preOrderEnabled": False},
                    "relationships": {"territory": {"data": {"type": "territories", "id": t}}},
                }
                for t in territories
            ],
        })
        print(f"  ✓ Availability ({len(territories)} territories) -> {st_p}")

    usa_pp = find_price_point(f"/v1/apps/{app_id}/appPricePoints?filter[territory]=USA&limit=50", 0.0)
    chn_pp = find_price_point(f"/v1/apps/{app_id}/appPricePoints?filter[territory]=CHN&limit=50", 0.0)
    if usa_pp:
        mrefs = [{"type": "appPrices", "id": "${p-usa}"}]
        incs = [{"type": "appPrices", "id": "${p-usa}", "attributes": {"startDate": None}, "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": usa_pp}}}}]
        if chn_pp:
            mrefs.append({"type": "appPrices", "id": "${p-chn}"})
            incs.append({"type": "appPrices", "id": "${p-chn}", "attributes": {"startDate": None}, "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": chn_pp}}}})
        st_ps, _ = asc("POST", "/v1/appPriceSchedules", {
            "data": {
                "type": "appPriceSchedules",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                    "manualPrices": {"data": mrefs},
                },
            },
            "included": incs,
        })
        print(f"  ✓ Base Price FREE -> {st_ps}")

    print("[3/4] Syncing CN + EN Metadata, Screenshots & Review Info...")
    _, vers = asc("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS")
    ver_id = vers["data"][0]["id"]
    asc("PATCH", f"/v1/appStoreVersions/{ver_id}", {
        "data": {"type": "appStoreVersions", "id": ver_id, "attributes": {"versionString": "1.0.0", "copyright": meta["copyright"], "releaseType": "AFTER_APPROVAL"}}
    })

    _, info_locs = asc("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations?limit=50")
    imap = {x["attributes"]["locale"]: x["id"] for x in info_locs.get("data", [])}
    _, ver_locs = asc("GET", f"/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations?limit=50")
    vmap = {x["attributes"]["locale"]: x["id"] for x in ver_locs.get("data", [])}

    for loc, data in meta["localizations"].items():
        iattrs = {"name": data["name"], "subtitle": data["subtitle"], "privacyPolicyUrl": meta["urls"]["privacy"]}
        if loc in imap:
            asc("PATCH", f"/v1/appInfoLocalizations/{imap[loc]}", {"data": {"type": "appInfoLocalizations", "id": imap[loc], "attributes": iattrs}})
        else:
            asc("POST", "/v1/appInfoLocalizations", {"data": {"type": "appInfoLocalizations", "attributes": {"locale": loc, **iattrs}, "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}}}})

        vattrs = {
            "description": data["description"],
            "keywords": data["keywords"],
            "promotionalText": data["promotionalText"],
            "supportUrl": meta["urls"]["support"],
            "marketingUrl": meta["urls"]["marketing"],
        }
        if loc in vmap:
            vloc_id = vmap[loc]
            asc("PATCH", f"/v1/appStoreVersionLocalizations/{vloc_id}", {"data": {"type": "appStoreVersionLocalizations", "id": vloc_id, "attributes": vattrs}})
        else:
            st_vl, c = asc("POST", "/v1/appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations", "attributes": {"locale": loc, **vattrs}, "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}}}})
            vloc_id = c["data"]["id"] if st_vl in (200, 201) and isinstance(c, dict) and "data" in c else None
        print(f"  ✓ Localization {loc} synced")
        if do_shots and vloc_id:
            sync_shots(vloc_id, "APP_IPHONE_65", SHOT_ROOT / loc / "iphone65")
            sync_shots(vloc_id, "APP_IPAD_PRO_3GEN_129", SHOT_ROOT / loc / "ipad13")

    review_notes = (
        "CupSnap (贴一杯) is a 100% free, ad-free, offline drink sticker calendar powered exclusively by on-device Apple Vision frameworks "
        "(VNGenerateForegroundInstanceMaskRequest for cup cutouts & VNRecognizeTextRequest for receipt OCR). Zero cloud servers, zero generative AI / AIGC, zero login required.\n\n"
        "Quick Review Guide:\n"
        "1. Wall Tab: Browse the pre-populated starter monthly sticker calendar, tap any day or the bottom-right 'Snap Cup / 贴一杯' button.\n"
        "2. Add Sheet: Try picking any photo for on-device cutout stickers (4 border styles + 12 illustrated presets) or tap one of the 3 sample receipt buttons to test offline brand/price/sugar/ice parsing instantly.\n"
        "3. Poster Tab: Switch between 3 pastel themes and save/share a 3:4 monthly drink sticker poster.\n"
        "4. Stats Tab: View monthly spend/caffeine analytics and test local JSON backup export/restore & CSV export."
    )
    rattrs = {
        "contactFirstName": "Yang",
        "contactLastName": "He",
        "contactPhone": "+86 196 3394 8182",
        "contactEmail": "a3152557994@gmail.com",
        "demoAccountRequired": False,
        "notes": review_notes,
    }
    st_r, res_r = asc("GET", f"/v1/appStoreVersions/{ver_id}/appStoreReviewDetail")
    if st_r == 200 and isinstance(res_r, dict) and res_r.get("data"):
        rd_id = res_r["data"]["id"]
        asc("PATCH", f"/v1/appStoreReviewDetails/{rd_id}", {"data": {"type": "appStoreReviewDetails", "id": rd_id, "attributes": rattrs}})
    else:
        asc("POST", "/v1/appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails", "attributes": rattrs, "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}}}})
    print("  ✓ App Review Details saved")
    return ver_id


def wait_and_attach_build(app_id: str, ver_id: str, wait_secs: int = 300) -> bool:
    print("[4/4] Checking/waiting for VALID build to attach...")
    deadline = time.time() + wait_secs
    while True:
        _, blds = asc("GET", f"/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=5")
        data = blds.get("data", []) if isinstance(blds, dict) else []
        valid = next((b for b in data if b["attributes"].get("processingState") == "VALID"), None)
        if valid:
            st, _ = asc("PATCH", f"/v1/appStoreVersions/{ver_id}/relationships/build", {"data": {"type": "builds", "id": valid["id"]}})
            print(f"  ✓ Attached VALID build {valid['attributes']['version']} ({valid['id']}) -> {st}")
            return st in (200, 204)
        states = [(b["attributes"].get("version"), b["attributes"].get("processingState")) for b in data]
        print(f"  ... builds so far: {states}")
        if time.time() >= deadline:
            return False
        time.sleep(15)


def submit_for_review(app_id: str, ver_id: str) -> None:
    print("[SUBMIT] Submitting CupSnap 1.0.0 to Apple App Review...")
    st_rs, res_rs = asc("POST", "/v1/reviewSubmissions", {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
        }
    })
    if st_rs not in (200, 201):
        print("  ! reviewSubmissions create returned:", st_rs, res_rs)
        return
    rs_id = res_rs["data"]["id"]
    st_i, res_i = asc("POST", "/v1/reviewSubmissionItems", {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": rs_id}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}},
            },
        }
    })
    print(f"  + Added version item -> {st_i}")
    if st_i not in (200, 201):
        print("   ", res_i)
        return
    st_sub, res_sub = asc("PATCH", f"/v1/reviewSubmissions/{rs_id}", {
        "data": {"type": "reviewSubmissions", "id": rs_id, "attributes": {"submitted": True}}
    })
    print(f"  🚀 Submitted reviewSubmission ({rs_id}) -> {st_sub}")
    if st_sub not in (200, 201):
        print("   ", res_sub)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--upload-ipa", action="store_true")
    parser.add_argument("--screenshots", action="store_true")
    parser.add_argument("--submit", action="store_true")
    args = parser.parse_args()

    meta = json.loads(META_PATH.read_text(encoding="utf-8"))
    st, res = asc("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")
    if st != 200 or not res.get("data"):
        print(f"ERROR: App shell {BUNDLE_ID} not found in ASC.")
        return 1
    app_id = res["data"][0]["id"]
    print(f"✅ Found CupSnap App ID: {app_id}")

    if args.upload_ipa:
        print(f"🚀 Uploading {IPA_PATH} via xcrun altool...")
        subprocess.run([
            "xcrun", "altool", "--upload-app", "-t", "ios",
            "-f", str(IPA_PATH), "--apiKey", KEY_ID, "--apiIssuer", ISSUER_ID,
        ], check=True)
        print("  ✓ IPA upload accepted by Apple!")

    territories = get_all_territories()
    ver_id = sync_core_metadata(app_id, meta, territories, do_shots=args.screenshots)

    if args.submit:
        attached = wait_and_attach_build(app_id, ver_id, wait_secs=240)
        if attached:
            submit_for_review(app_id, ver_id)
        else:
            print("  ! Build still processing; re-run with --submit once Apple finishes processing.")

    _, vers = asc("GET", f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS&include=build")
    v = vers["data"][0]
    print("  Version Status:", v["attributes"]["versionString"], v["attributes"]["appStoreState"], "build:", v.get("relationships", {}).get("build", {}).get("data"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
