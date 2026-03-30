## Design tokens for 玩具星港：滚滚滚
## Single source of truth for all UI and gameplay colors.
##
## Usage: DesignTokens.ACCENT_CYAN
## (class_name makes it globally accessible — no preload needed)
##
## Canonical palette reference: .impeccable.md

class_name DesignTokens
extends RefCounted

# ── Surface colors ────────────────────────────────────────────────────────────
const SURFACE_BASE         := Color(0.039, 0.071, 0.125, 1.0)   ## #0A1220 deep navy
const SURFACE_CARD         := Color(0.078, 0.110, 0.188, 0.92)  ## #141C30 HUD card
const SURFACE_CARD_OBJ     := Color(0.098, 0.130, 0.210, 0.94)  ## #192135 objective card
const SURFACE_CARD_CTRL    := Color(0.065, 0.098, 0.162, 0.88)  ## #101928 controls card
const SURFACE_CARD_SOLID   := Color(0.078, 0.110, 0.188, 1.0)   ## #141C30 opaque (overlays)
const SURFACE_INSET        := Color(0.039, 0.071, 0.125, 1.0)   ## #0A1220 inset shadow

# ── Accent colors ──────────────────────────────────────────────────────────────
const ACCENT_CYAN          := Color(0.352941, 0.862745, 1.0, 1.0)      ## #5ADBFF info/nav
const ACCENT_CYAN_75       := Color(0.352941, 0.862745, 1.0, 0.75)     ## level card border
const ACCENT_CYAN_72       := Color(0.52549,  0.929412, 0.976471, 0.72) ## controls border
const ACCENT_GOLD          := Color(1.0, 0.733333, 0.337255, 1.0)      ## #FFBB56 progress
const ACCENT_GOLD_85       := Color(1.0, 0.733333, 0.337255, 0.85)     ## objective border
const ACCENT_GOLD_STAR     := Color(1.0, 0.816, 0.376, 1.0)            ## #FFD060 star/reward

# ── Separator colors ──────────────────────────────────────────────────────────
const SEPARATOR_CYAN       := Color(0.349, 0.863, 1.0, 0.3)
const SEPARATOR_GOLD       := Color(1.0, 0.816, 0.376, 0.3)

# ── Text colors ───────────────────────────────────────────────────────────────
const TEXT_TITLE           := Color(0.988235, 0.980392, 0.94902,  1.0) ## #FCF9F2 heading
const TEXT_KICKER          := Color(0.603922, 0.890196, 1.0,       1.0) ## #9AE3FF cyan kicker
const TEXT_SUBTITLE        := Color(0.796078, 0.847059, 0.905882,  1.0) ## #CBD8E7 soft body
const TEXT_OBJECTIVE_TITLE := Color(1.0,      0.85098,  0.52549,   1.0) ## gold section label
const TEXT_HINT            := Color(1.0,      0.980392, 0.94902,   1.0) ## near-white hint
const TEXT_CONTROLS_TITLE  := Color(0.701961, 0.952941, 0.937255,  1.0) ## #B3F3EF
const TEXT_CONTROLS_BODY   := Color(0.960784, 0.972549, 0.992157,  1.0) ## near-white

# ── Box face colors ────────────────────────────────────────────────────────────
const FACE_NORMAL_BODY     := Color(0.956863, 0.701961, 0.247059, 1.0) ## #F4B33F amber
const FACE_NORMAL_LABEL    := Color(1.0,      0.96,     0.84,     1.0)
const FACE_IMPACT_BODY     := Color(0.968627, 0.486275, 0.345098, 1.0) ## #F77C58 coral
const FACE_IMPACT_LABEL    := Color(1.0,      0.86,     0.78,     1.0)
const FACE_HEAVY_BODY      := Color(0.886275, 0.372549, 0.223529, 1.0) ## #E25F39 brick red
const FACE_HEAVY_LABEL     := Color(1.0,      0.96,     0.82,     1.0)
const FACE_ENERGY_BODY     := Color(0.290196, 0.780392, 0.94902,  1.0) ## #4AC7F2 cyan
const FACE_ENERGY_LABEL    := Color(0.88,     0.988,    1.0,      1.0)

# ── Interactable light colors (3D OmniLight) ──────────────────────────────────
const LIGHT_BUTTON_ON      := Color(0.52, 1.0,  0.62, 1.0) ## green — button pressed
const LIGHT_BUTTON_OFF     := Color(1.0,  0.48, 0.42, 1.0) ## red   — button unpressed
const LIGHT_GOAL_IDLE      := Color(0.62, 0.78, 1.0,  1.0) ## cool blue  — goal waiting
const LIGHT_GOAL_ACTIVE    := Color(0.58, 0.96, 1.0,  1.0) ## bright cyan — goal triggered
const LIGHT_GOAL_UNLIT     := Color(0.36, 0.42, 0.54, 1.0) ## dim blue    — goal unpowered

# ── Door light colors ─────────────────────────────────────────────────────────
const LIGHT_DOOR_OPEN          := Color(1.0, 0.815686, 0.376471, 1.0) ## gold
const LIGHT_DOOR_CLOSED        := Color(1.0, 0.45, 0.4, 1.0)         ## coral-red
const LIGHT_DOOR_OPEN_ENERGY   := 0.45
const LIGHT_DOOR_CLOSED_ENERGY := 0.55

# ── Energy socket light colors ────────────────────────────────────────────────
const LIGHT_ENERGY_ON          := Color(0.48, 0.98, 1.0, 1.0)   ## bright cyan
const LIGHT_ENERGY_OFF         := Color(0.32, 0.44, 0.54, 1.0)  ## dim blue-gray
const LIGHT_ENERGY_ON_ENERGY   := 1.2
const LIGHT_ENERGY_OFF_ENERGY  := 0.18

# ── Enemy defeat light colors ─────────────────────────────────────────────────
const LIGHT_ENEMY_DEFEAT_HEAVY  := Color(1.0, 0.92, 0.65, 1.0) ## warm gold
const LIGHT_ENEMY_DEFEAT_NORMAL := Color(1.0, 0.72, 0.55, 1.0) ## warm orange
const LIGHT_ENEMY_DEFEAT_ENERGY := 0.2

# ── Feedback colors ────────────────────────────────────────────────────────────
const DENY_FLASH_ALBEDO    := Color(1.0, 0.35, 0.35, 1.0) ## red body flash on move denied
const DENY_FLASH_EMISSION  := Color(0.8, 0.1,  0.1,  1.0) ## red emission on move denied

# ── Terrain tile colors ─────────────────────────────────────────────────────────
## Ramp: warm amber — matches FACE_NORMAL palette
const RAMP_COLOR           := Color(0.957, 0.702, 0.247, 1.0)   ## #F4B33F amber
const RAMP_ACTIVE_COLOR    := Color(1.0,   0.85,  0.4,   1.0)   ## brighter amber
const RAMP_GLOW            := Color(1.0,   0.75,  0.3,   0.4)   ## amber glow

## Conveyor: cool cyan — matches FACE_ENERGY palette
const CONVEYOR_COLOR       := Color(0.290, 0.780, 0.949, 1.0)   ## #4AC7F2 cyan
const CONVEYOR_ACTIVE_COLOR := Color(0.55,  0.98,  1.0,   1.0)   ## brighter cyan
const CONVEYOR_GLOW        := Color(0.35,  0.88,  1.0,   0.4)   ## cyan glow

## Rotating Platform: brick red — matches FACE_HEAVY palette
const ROTATING_COLOR       := Color(0.886, 0.373, 0.224, 1.0)   ## #E25F39 brick red
const ROTATING_ACTIVE_COLOR := Color(1.0,   0.55,  0.4,   1.0)   ## brighter red
const ROTATING_GLOW        := Color(0.9,   0.4,   0.3,   0.4)   ## red glow
