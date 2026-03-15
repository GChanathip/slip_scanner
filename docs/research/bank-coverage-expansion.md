# Bank Coverage Expansion: Thai Banks Priority & Slip Format Analysis

## User Segment

Thai users of the Slip Scanner app who transact with banks beyond SCB, KBank, and Dime — primarily Bangkok Bank, Krungthai Bank, Krungsri, ttb, and Government Savings Bank account holders who currently get no OCR extraction from their payment slips.

## Problem Statement

The app only extracts structured data from SCB, KBank (Make/K Plus), and Dime slips. Users of the five next-largest Thai banks receive no extraction (amount, sender, receiver, date, reference ID stay blank), making the app useless for ~60% of the Thai banking market by institution count. PromptPay slips are cross-bank but the OCR layer is bank-siloed.

## Evidence

- Thailand processed **19.89 billion PromptPay transactions** in 2023 (THB 47.42 trillion value).
- 77.2M+ registered PromptPay accounts (90M+ by mid-2025).
- KBank + SCB dominate digital volume but **Bangkok Bank, KTB, Krungsri, ttb, and GSB collectively serve tens of millions of digital banking users**.
- The `reefwn/thai-bank-slip-ocr-line-bot` repo (Python, LINE bot) implements OCR parsers for BBL, KTB, BAY, TMB/ttb, and GOV (GSB) — confirming these are the next five highest-demand banks for OCR.
- **No public labeled slip image dataset exists** for Thai transfer slips — sample collection must come from real users or manual capture.

## Current Workarounds

Users screenshot slips and manually type amounts/details into their expense tracker, or skip tracking altogether for non-SCB/non-KBank transactions.

---

## Bank Priority Order

### Recommended sequence: **BBL → KTB → Krungsri → ttb → GSB**

| Rank | Bank | App | Bank Code | Rationale |
|------|------|-----|-----------|-----------|
| 1 | Bangkok Bank (BBL) | Bualuang mBanking | 002 | Largest by total assets; 13M+ app users; well-documented slip format |
| 2 | Krungthai Bank (KTB) | Krungthai NEXT + Pao Tang | 006 | 18M+ users; government welfare integration drives mass volume; positional extraction pattern well-documented |
| 3 | Krungsri (BAY) | krungsri app | 025 | MUFG subsidiary; strong Bangkok middle-class user base; "BAY" anchor makes detection trivial |
| 4 | ttb (TMBThanachart) | ttb touch | 011 | 2021 merger of TMB + Thanachart; combined user base sizable; somewhat complex OCR layout |
| 5 | GSB (ออมสิน) | MyMo | 030 | Rural/government bank; 5M+ users; specialized date format; lowest complexity |

---

## Slip Format Analysis Per Bank

### Shared Universal Fields (All Thai Bank PromptPay Slips)

Every authentic Thai e-slip contains these fields due to NITMX PromptPay standard:

| Thai Label | Meaning | Notes |
|-----------|---------|-------|
| จำนวนเงิน | Amount | Format: `1,500.00 บาท` |
| ชื่อผู้โอน / ชื่อบัญชีผู้โอน | Sender name | Thai full name |
| เลขที่บัญชีผู้โอน | Sender account | Masked (bank-specific pattern) |
| ชื่อผู้รับ / ชื่อบัญชีผู้รับ | Receiver name | Thai full name |
| เลขที่บัญชีผู้รับ | Receiver account | Masked |
| วันที่ / วันที่ทำรายการ | Date | B.E. calendar (พ.ศ.) on display |
| เวลา / เวลาทำรายการ | Time | 24h or 12h AM/PM depending on bank |
| เลขที่อ้างอิง / เลขที่รายการ / รหัสอ้างอิง | Reference/transaction ID | Label varies by bank |

**Embedded QR code** carries machine-readable `transRef` (~22–25 digit numeric, NITMX-assigned) — the most reliable unique cross-bank identifier.

---

### Bangkok Bank (BBL)

- **Header text**: "รายการโอนเงินสำเร็จ" or "ยืนยันการทำรายการ"
- **Reference label**: เลขที่อ้างอิง (+ `approvalCode` 6-digit field)
- **Reference position**: Index `[len-2]` or `[len-4]` in positional OCR output
- **Date format**: `DD/MM/YYYY` — **CE year** (unlike KTB/GSB which use B.E.)
- **Date+time position**: Index `[2]`, comma-delimited
- **Amount position**: Index `[3]`, highest numeric value in field
- **Account masking**: "A/c 4734xxx426" (first 4 + last 3, x-padded middle)
- **Bank detection anchor**: Logo text "กรุงเทพ" or "Bangkok Bank" in OCR
- **Effort**: ★★☆ Medium — CE dates simplify conversion, but positional extraction (no labeled fields) requires calibration with real samples

---

### Krungthai Bank (KTB)

- **Header text**: "โอนเงินสำเร็จ" or "ยืนยันการโอนเงิน"
- **Reference label**: เลขที่รายการ (no colon, minimal labeling)
- **Reference position**: Index `[1]`, strip special characters
- **Date format**: `DD/MM/YYYY` — **B.E. year** (e.g., 15/03/2567 = 15 Mar 2024)
  - Already handled by existing `normalizeToISODate` Buddhist calendar code
- **Date+time position**: Last indices, hyphen-delimited `date - time`
- **Account masking**: Similar x-padding to KBank (unconfirmed exact format — needs real sample)
- **Bank detection anchor**: "กรุงไทย" or "Krungthai" in OCR header
- **Special note**: Pao Tang (government welfare) slips may differ from NEXT app slips — additional parser variant may be needed
- **Effort**: ★★☆ Medium — B.E. already solved; positional reference without label requires testing

---

### Krungsri / Bank of Ayudhya (BAY)

- **Header text**: "ทำรายการสำเร็จ" or "โอนเงินเรียบร้อย"
- **Reference label**: เลขที่รายการ
- **Date+time position**: Index `[1]`, newline-split
- **Sender/receiver position**: Indices `[2–5]`, newline-aware
- **Date format**: B.E. calendar likely; needs confirmation with samples
- **Account masking**: Standard masked format; developer API exposes partial account
- **Bank detection anchor**: **"BAY"** appears as literal text in OCR output — highly reliable anchor for bank detection
- **Effort**: ★☆☆ Low — "BAY" anchor makes detection trivial; field structure closely mirrors KTB

---

### ttb (TMBThanachart)

- **Header text**: "โอนเงินสำเร็จ" / "ทำรายการสำเร็จ"
- **Reference label**: เลขที่อ้างอิง
- **Reference position**: Indices `[14–16]`, exclude "/" patterns — slip is **more text-dense** than other banks
- **Date+time position**: Index `[13]`, last two space-separated tokens
- **Amount position**: Index `[1]`, scan for maximum numeric value
- **Account masking**: Standard x-padded format
- **Bank detection anchor**: "ttb" or "ทีเอ็มบีธนชาต" in header
- **Special note**: Post-2021 rebranding — earlier slips may show "TMB" branding; app has customizable slip branding for promotions
- **Effort**: ★★★ High — Most text-dense layout; deep positional indices require multiple real samples to calibrate; dual branding (TMB legacy + ttb) adds edge cases

---

### Government Savings Bank (GSB / ออมสิน)

- **Header text**: "ยืนยันการโอนเงิน" / "ทำรายการสำเร็จ"
- **Reference label**: เลขที่อ้างอิง
- **Reference position**: Indices `[1–2]`, exclude special characters
- **Date+time position**: Indices `[2–4]`, space-delimited with **15-character length validation** (date + time in single longer string)
- **Date format**: B.E. calendar; combined with time in one field
- **Account masking**: Standard x-padded format
- **Bank detection anchor**: "ออมสิน" or "GSB" in header/logo area
- **Effort**: ★★☆ Medium — 15-char date validation is idiosyncratic but simple once documented; rural user base means less consistent OCR quality may require more robust fallbacks

---

## PromptPay Universal Patterns

The NITMX QR code embedded in every Thai bank e-slip contains a structured payload. **`transRef`** is the gold-standard cross-bank unique identifier:

```
transRef     — ~22–25 digit numeric string (NITMX-assigned)
               Example: "2022011211544723000693608"
               Regex: \b\d{22,25}\b  (or extract from QR payload directly)

sender.bank.id  — 3-digit code: "002"=BBL, "006"=KTB, "025"=BAY, "011"=TTB, "030"=GSB
                  Embedded in QR; also appears as suffix in some reference strings

date         — ISO 8601 in QR; displayed as DD/MM/YYYY (B.E.) on visual slip
amount       — Always "X,XXX.XX บาท" format on visual slip (existing patterns already match this)
```

**Cross-bank regex that already works** (from existing `RegexPatterns.swift`):
- Amount: `จำนวนเงิน\s*([\d,]+\.\d{2})` — works for all 5 banks
- Thai month abbreviations — works universally
- Buddhist year conversion — works universally
- `เลขที่รายการ:?\s*([A-Za-z0-9]+)` — covers KTB, BAY, GSB reference label variants

**New patterns needed**:
```swift
// Bank detection anchors
#"กรุงเทพ|Bangkok\s*Bank|BBL"#          // Bangkok Bank
#"กรุงไทย|Krungthai|KTB"#               // KTB
#"กรุงศรี|BAY|Krungsri"#                // Krungsri
#"ttb|ทีเอ็มบีธนชาต|TMBThanachart"#     // ttb
#"ออมสิน|GSB"#                          // GSB

// Sender/receiver label variants (new banks use different labels)
#"ชื่อผู้โอน\s*\n?(.*?)(?=\n)"#         // Sender name (KTB/BAY/ttb/GSB variant)
#"ชื่อผู้รับ\s*\n?(.*?)(?=\n)"#         // Receiver name (KTB/BAY/ttb/GSB variant)
#"ชื่อบัญชีผู้โอน\s*\n?(.*?)(?=\n)"#   // Sender name (BBL variant)
#"ชื่อบัญชีผู้รับ\s*\n?(.*?)(?=\n)"#   // Receiver name (BBL variant)

// Account number masking variant (BBL "A/c" format)
#"A/c\s*(\d{4})x+(\d{3,4})"#           // Bangkok Bank

// Reference without labeled prefix (positional, KTB style)
// No regex possible — requires index-based extraction fallback
```

---

## Sample Collection Guidance

**Realistic options (in priority order):**

1. **Real user volunteers** — The highest quality source. Add in-app prompt: "Help us support your bank — share an anonymized slip." Even 2–3 samples per bank is enough to validate patterns.
2. **Developer API dry-run responses** — Bangkok Bank, KTB, and Krungsri all have public developer portals with sandbox environments and documented JSON response schemas. These reveal masked account formats and reference ID structure without requiring real transactions.
3. **GitHub repos** — `reefwn/thai-bank-slip-ocr-line-bot` contains hard-coded test data strings for BBL, KTB, BAY, TMB, GOV. Not real slip images but OCR output strings are extractable.
4. **Thai tech forums / social media** — Pantip.com and Twitter/X occasionally have slip screenshots in "transfer successful" posts. Manual collection, low volume, some risk of outdated format.
5. **No public labeled dataset exists** — Kaggle, Roboflow, HuggingFace have zero Thai bank transfer slip datasets. Do not expect to find one.

**Minimum viable for implementation**: 2–3 real OCR text samples per bank to write and validate regex. The `extractedText` column in the database is the ideal source once a single user has the relevant bank.

---

## Severity Assessment

- **Frequency:** Every user with a non-SCB/non-KBank transaction gets zero extraction — this is a constant miss, not an edge case.
- **Intensity:** High — the core value proposition (automatic expense categorization from slips) completely fails for ~40–60% of Thai banking users.
- **Market size:** Bangkok Bank alone has 13M app users; KTB has 18M. Combined addressable market for this fix is 30–50M Thai digital banking users.

---

## Effort Estimate Per Bank

| Bank | Effort | Key challenge | Est. patterns to add |
|------|--------|--------------|---------------------|
| Krungsri (BAY) | ★☆☆ Low | None — "BAY" anchor trivial | 6–8 |
| Bangkok Bank (BBL) | ★★☆ Medium | Positional extraction, CE dates | 8–10 |
| KTB | ★★☆ Medium | Positional reference (no label), B.E. dates | 8–10 |
| GSB | ★★☆ Medium | Idiosyncratic 15-char date field | 6–8 |
| ttb | ★★★ High | Text-dense layout, dual branding legacy | 10–14 |

**Quick win**: Krungsri (BAY) should be first to implement — "BAY" text anchor makes bank detection trivial and field structure mirrors KTB. Can likely be done with existing pattern infrastructure.

---

## Recommendation

**Pursue.** Strong evidence, large addressable market, clear implementation path.

**Phased approach:**
1. **Phase 1** (quick wins): Krungsri (BAY) + Bangkok Bank (BBL) — both have well-documented positional patterns; BAY is trivially detectable
2. **Phase 2**: KTB + GSB — B.E. date handling already solved; positional extraction similar to KTB
3. **Phase 3**: ttb — highest complexity, dual-branding edge cases; worth doing after validating the pattern for the other four

**Key dependency**: Real slip OCR text samples. Recommend adding a "Help improve bank support" in-app feature request prompt to collect 2–3 samples per bank from users, or use the `reefwn` project's hardcoded OCR strings as initial test fixtures.

**Implementation note for CTO**: The same patterns must be added to both `ios/Runner/RegexPatterns.swift` and `macos/Runner/RegexPatterns.swift` (per CLAUDE.md). The `buildSlipResult()` function in OCRService.swift will need bank-detection logic to route to the right extraction strategy (labeled vs. positional).
