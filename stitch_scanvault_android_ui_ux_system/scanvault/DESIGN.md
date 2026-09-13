---
name: ScanVault
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#3d4947'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#6d7a77'
  outline-variant: '#bcc9c6'
  surface-tint: '#006a61'
  primary: '#00685f'
  on-primary: '#ffffff'
  primary-container: '#008378'
  on-primary-container: '#f4fffc'
  inverse-primary: '#6bd8cb'
  secondary: '#855300'
  on-secondary: '#ffffff'
  secondary-container: '#fea619'
  on-secondary-container: '#684000'
  tertiary: '#006860'
  on-tertiary: '#ffffff'
  tertiary-container: '#248279'
  on-tertiary-container: '#f3fffc'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#89f5e7'
  primary-fixed-dim: '#6bd8cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#005049'
  secondary-fixed: '#ffddb8'
  secondary-fixed-dim: '#ffb95f'
  on-secondary-fixed: '#2a1700'
  on-secondary-fixed-variant: '#653e00'
  tertiary-fixed: '#9cf2e8'
  tertiary-fixed-dim: '#80d5cb'
  on-tertiary-fixed: '#00201d'
  on-tertiary-fixed-variant: '#00504a'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.015em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  title-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1rem
  margin-tablet: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system embodies modern Material 3 architecture engineered specifically for an offline-first, privacy-respecting utility. The core aesthetic balances institutional trust with tactile modern software craftsmanship. It rejects ephemeral web clutter, ads, and distracting telemetry prompts in favor of deliberate, focused productivity.

Key visual attributes:
- **Tone:** Professional, reliable, secure, and surgical.
- **Visual Movement:** Contemporary Material You (M3) refined with crisp Scandinavian precision. High-contrast textual hierarchies prevent cognitive fatigue during document auditing.
- **Physical Metaphor:** Physical filing cards rendered in pure digital surfaces—structured, stacked, and tactile without skeuomorphic excess.

## Colors
The palette leverages high-acuity emerald teal as an emblem of encryption, precision, and organic security, complemented by an amber focal accent for urgent states and high-value document actions.

- **Primary (`#0D9488` / Deep `#0F766E`):** Directs the primary scan workflows, camera triggers, affirmative action buttons, and active bottom navigation states.
- **Secondary (`#F59E0B`):** Reserved for starred items, PDF compression alerts, OCR processing states, and visual warnings.
- **Neutral & Typography (`#1E293B` & `#334155`):** Slate neutrals replace harsh absolute blacks to maximize readability under ambient office or outdoor capture light.
- **Surfaces:**
  - Screen Background: `#F8F9FA`
  - Surface Pure: `#FFFFFF` (Document card base, bottom sheet surfaces)
  - Surface Container Low: `#F1F3F5` (Grouping containers, search rails)
  - Surface Container High: `#E9ECEF` (Segmented controls, disabled backdrops)
  - Structural Outlines: `#E2E8F0` (Ghost borders providing separation without visual noise)

## Typography
Plus Jakarta Sans delivers geometric clarity combined with humanist terminal openings, ensuring extreme legibility when rendering dense PDF metadata, file sizes, and cryptographic checksum details.

- Headings use medium and semibold weights with slight negative tracking to preserve structural tension.
- Numeric displays (page counts, timestamps, kilobyte meters) utilize tabular alignment features inherent in the font.
- Labels maintain distinct positive letter-spacing to ensure legibility across dynamic chip badges and dense table headers.

## Layout & Spacing
The layout follows an 8-point base grid optimized for handheld interaction, touch targets (minimum 48x48dp), and thumb-zone access.

- **Mobile Viewports (<600dp):** Single-column fluid view with an edge-to-edge container structure. Top App Bar collapses on scroll; floating action triggers anchor directly above the bottom navigation rail. 16px screen-edge margins.
- **Foldables & Tablets (600dp - 1024dp):** Two-pane master-detail arrangement. Left rail houses folder taxonomies and storage stats; right pane renders preview grids and batch inspection tools. 24px gutters with 32px safe margins.

## Elevation & Depth
Depth is created through layered surface tonal shifts combined with subtle ambient occlusion rather than heavy drop shadows, reinforcing an authentic modern Android Material 3 feel.

- **Level 0 (Flat):** Document view backdrops (`#F8F9FA`).
- **Level 1 (Cards & Lists):** Surface White (`#FFFFFF`) framed by a 1px crisp hairline border (`#E2E8F0`). Shadow: `0px 1px 3px rgba(15, 23, 42, 0.04), 0px 1px 2px rgba(15, 23, 42, 0.02)`.
- **Level 2 (Scrolled App Bars, Search Bars):** Surface Container Low (`#F1F3F5`) with shadow: `0px 4px 6px -1px rgba(15, 23, 42, 0.06), 0px 2px 4px -2px rgba(15, 23, 42, 0.04)`.
- **Level 3 (Floating Action Button & Bottom Sheets):** Elevated Teal Surface or Pure White. Shadow: `0px 10px 15px -3px rgba(13, 148, 136, 0.2), 0px 4px 6px -4px rgba(15, 23, 42, 0.08)`.

## Shapes
Geometry uses Material 3 curvature scales:
- **Standard Cards & Modals:** `1rem` (16px) to `1.5rem` (24px) for expansive document preview surfaces (`rounded-2xl`).
- **Pills & Buttons:** Fully curved (9999px) for chips, primary action buttons, filter tags, and bottom nav item selection bubbles.
- **Thumbnails:** `0.75rem` (12px) internal radius to cushion rectangular page previews within outer card shells.

## Components

### Floating Action Button (FAB)
- **Primary Scan FAB:** Prominent pill-extended or 56x56dp rounded-2xl container (`#0D9488`) housing crisp camera iconography. When expanded, provides actions for "Multi-Page Scan", "Import PDF", and "Quick ID".
- **States:** Hover/Focus transitions to Deep Teal (`#0F766E`). Press triggers a standard 0.12 ripple effect.

### Cards & Document Tiles
- **Structure:** White container bounded by `#E2E8F0` border with 16px padding.
- **Thumbnail:** Aspect-ratio locked 3:4 document snapshot preview, cushioned inside `#F1F3F5` container with a page count badge anchored bottom-right.
- **Metadata:** Document Title (`title-md`), modification timestamp (`body-sm`), OCR tag chips, and a right-aligned vertical overflow menu.

### Bottom Navigation Bar
- **Surface:** `#FFFFFF` with a 1px border-t (`#E2E8F0`).
- **Active State:** Icon sits within an emerald-tinted pill indicator (`#CCFBF1`, 64x32dp), icon tint shifts to `#0F766E`.
- **Destinations:** Documents, Tags/Folders, Search, Vault Settings.

### Input Fields & Search
- **Search Anchor:** Floating rounded-full bar (`#F1F3F5`) with leading search icon, placeholder "Search text, tags, or OCR content", and trailing filter icon button.
- **Text Inputs:** Outlined Material style with 12px rounded corners. Active focus replaces `#E2E8F0` border with a 2px `#0D9488` stroke without layout shift.

### Chips & Filter Pills
- **Filter Chips:** Height 32dp, pill-shaped. Inactive state: `#F1F3F5` background, `#334155` text. Active state: `#0D9488` background, `#FFFFFF` text, leading checkmark icon.

### Selection Controls
- **Checkboxes & Radios:** 20dp hit target scaled to 48dp touch footprint. Checked fill `#0D9488` with clean white glyph. Unchecked: 1.5px stroke of `#94A3B8`.

### Scanner Edge Overlay & Crop Guides
- Specialized viewfinder UI featuring high-contrast `#0D9488` corner brackets (3px stroke), magnetic snapping handles on document corners, and high-visibility amber perspective warning badges.