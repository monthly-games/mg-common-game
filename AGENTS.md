# MG_COMMON_GAME SOURCE REPO KNOWLEDGE BASE

## OVERVIEW
Engine SOURCE repository (429 Dart files, 117 feature directories). **NOT the canonical library** — games use `libs/mg_common_game/` (174 files, curated). This repo is for development/experimentation.

## CRITICAL: DUAL-SOURCE ARCHITECTURE
```
repos/mg-common-game/    ← SOURCE (429 files, 24,077 LOC, experimental)
       ↓ sync/curate
libs/mg_common_game/     ← CANONICAL (174 files, 35,063 LOC, production)
       ↓ path dependency
mg-game-XXXX/           ← 52 games depend on canonical lib
```

**Games import from `libs/`, NOT `repos/`.** Changes here must be synced to canonical.

## STRUCTURE
```
lib/
├── core/                          # 153 files, 26 subdirs — HOTSPOT
│   ├── ads/, analytics/, audio/  # Infrastructure
│   ├── engine/, systems/         # Core game engine
│   ├── ui/                       # 76 files (overlap with ui/ below)
│   ├── economy/, iap/            # Monetization
│   └── [20+ other subdirs]       # See full list below
├── features/                      # 16 files, 6 subdirs
│   ├── battle/, crafting/, deck/ # Game mechanics
│   ├── idle/, puzzle/, hud/      # Feature modules
├── systems/                       # 61 files, 20+ subdirs
│   ├── battlepass/, gacha/       # Monetization
│   ├── progression/, quests/     # Engagement
│   └── [15+ other systems]
├── ui/                           # 30 files, 15+ subdirs
│   └── [UI components]           # Overlap with core/ui/
└── [113 other top-level dirs]    # Experimental/deprecated

Total: 429 Dart files across 117+ directories
```

## CORE SUBSYSTEMS (core/ — 26 subdirs)

**Infrastructure**:
- ads/, analytics/, audio/, cloud/, event/, feedback/, firebase/
- i18n/, loading/, localization/, networking/, notifications/
- performance/, security/, social/, storage/

**Game Engine**:
- engine/, models/, systems/, utils/

**UI System**:
- ui/ (76 files) — **Overlaps with top-level ui/**

**Economy**:
- economy/, iap/

**Optimization**:
- optimization/

**Social**:
- quest/, social/

## DUPLICATE/OVERLAPPING MODULES

**Critical Issues**:

| Module | Location 1 | Location 2 | Location 3 | Status |
|--------|-----------|-----------|-----------|--------|
| **UI** | `core/ui/` (76 files) | `ui/` (30 files) | — | Unclear separation |
| **ab_testing** | `ab_testing/` | `abtesting/` | — | Duplicate dirs |
| **notification** | `notification/` | `notifications/` | — | Duplicate dirs |
| **localization** | `localization/` | `l10n/` | — | Duplicate dirs |
| **offline** | `offline/` | `offline_mode/` | — | Duplicate dirs |
| **vr/ar** | `ar_vr/` | `vr_ar/` | `xr/` | Triple dirs |
| **chat/messaging** | `chat/`, `communication/`, `messaging/`, `push/`, `voice_chat/` | — | — | 5+ overlapping dirs |
| **social** | `guild/`, `guild_dashboard/`, `guild_war/`, `party/`, `social/`, `social_friends/` | — | — | 6+ overlapping dirs |
| **events** | `event_management/`, `events/` | — | — | 2 event dirs |

## BLOAT ANALYSIS

**117 top-level directories** (vs 4 in canonical lib):
- **Experimental**: Many dirs appear unused or incomplete
- **Duplicates**: 30+ duplicate/overlapping directories
- **Unclear ownership**: No clear module boundaries

**Canonical lib (libs/) has only 4 dirs**: core/, features/, systems/, api/

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| **Coding standards** | `doc/CODING_STANDARDS.md` | 547 lines, definitive guide |
| **Test helpers** | `lib/testing/test_helpers.dart` | Mocks, fakes, generators |
| **Core engine** | `lib/core/engine/` | GameManager, SceneManager, effects/ |
| **Battle system** | `lib/features/battle/` | BattleScene + logic/ui |
| **UI widgets** | `lib/core/ui/` OR `lib/ui/` | **Unclear which to use** |
| **Gacha/Battlepass** | `lib/systems/gacha/`, `lib/systems/battlepass/` | Monetization |
| **Progression** | `lib/systems/progression/` | Level, upgrades, achievements |
| **Tests** | `test/` | Test suites for engine |

## SYNC TO CANONICAL

**Workflow**:
1. Develop/experiment in `repos/mg-common-game/`
2. Curate changes (remove experimental, resolve duplicates)
3. Sync curated code to `libs/mg_common_game/`
4. Games import from `libs/` (174 files, production-ready)

**Sync Status**:
- Source: 429 files (24,077 LOC)
- Canonical: 174 files (35,063 LOC)
- **Canonical has fewer files but MORE LOC** → higher quality, more complete implementations

## CONVENTIONS

Same as canonical lib:
- **Imports**: Package imports ONLY (`import 'package:mg_common_game/...'`)
- **77 relative import violations** exist here (needs fixing)
- **UI**: Always MGColors/MGTextStyles/MGSpacing
- **Tests**: Given-When-Then, mock externals
- **Performance**: `ListView.builder` for lists, no new objects in `build()`
- **Linting**: 170+ rules, strict mode

## ANTI-PATTERNS

- **NEVER** import from this repo directly — games use `libs/mg_common_game/`
- **NEVER** sync experimental code to canonical without review
- **NEVER** break public API of canonical lib
- **DO NOT** create new top-level directories without design review (already 117!)
- **DO NOT** duplicate existing modules (check for 30+ existing duplicates)
- **AVOID** relative imports (77 violations exist)

## CLEANUP ROADMAP

**Priority 1: Deduplicate**
- Merge `ab_testing/` + `abtesting/` → `ab_testing/`
- Merge `notification/` + `notifications/` → `notifications/`
- Merge `localization/` + `l10n/` → `l10n/`
- Merge `offline/` + `offline_mode/` → `offline/`
- Merge `ar_vr/` + `vr_ar/` + `xr/` → `xr/`

**Priority 2: Clarify UI separation**
- Decide: `core/ui/` vs `ui/` ownership
- Consolidate or document clear boundaries

**Priority 3: Consolidate social/messaging**
- Merge 5+ chat/messaging dirs → `communication/`
- Merge 6+ social/guild dirs → `social/`

**Priority 4: Remove experimental**
- Identify unused directories
- Archive or delete

**Priority 5: Fix relative imports**
- Convert 77 violations to package imports

## MIGRATION NOTES

**From source (repos/) to canonical (libs/)**:
- Source has 255 MORE files (429 vs 174)
- Canonical has 11,000 MORE lines (35,063 vs 24,077)
- **Canonical is curated, higher quality**

**Experimental features NOT in canonical**:
- Many of 117 top-level dirs (e.g., ar_vr, esports, ml, voice_chat)
- Duplicates (ab_testing variants, notification variants)

**Production features in canonical**:
- All in `lib/core/`, `lib/features/`, `lib/systems/`
- Curated from source over time

---

**Document version**: 1.0  
**Last updated**: 2026-02-26  
**Status**: Active development (experimental), sync to canonical for production
