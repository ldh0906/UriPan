---
version: alpha
name: UriPan Family Board
description: Warm, calm, mobile-first design system for a shared family board.
colors:
  primary: "#647D31"
  secondary: "#E7A14B"
  tertiary: "#D79059"
  background: "#FFF2BB"
  surface: "#FFFFFF"
  surface-variant: "#F2E8D9"
  text: "#13243B"
  muted-text: "#64748B"
  success: "#10B981"
  warning: "#E7A14B"
  error: "#E25454"
  info: "#3B82F6"
  primary-soft: "#EFF6D6"
  success-soft: "#E8F8F0"
  warning-soft: "#FFF0D8"
  info-soft: "#EAF2FF"
  danger-soft: "#FFEAEA"
typography:
  headline-lg:
    fontFamily: Roboto
    fontSize: 32px
    fontWeight: 800
    lineHeight: 1.18
    letterSpacing: 0px
  headline-md:
    fontFamily: Roboto
    fontSize: 26px
    fontWeight: 800
    lineHeight: 1.22
    letterSpacing: 0px
  headline-sm:
    fontFamily: Roboto
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: 0px
  title-lg:
    fontFamily: Roboto
    fontSize: 20px
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: 0px
  title-md:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 700
    lineHeight: 1.35
    letterSpacing: 0px
  title-sm:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 700
    lineHeight: 1.35
    letterSpacing: 0px
  body-lg:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0px
  body-md:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: 0px
  body-sm:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: 0px
  label-lg:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: 0px
  label-md:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: 0px
rounded:
  sm: 8px
  md: 12px
  lg: 16px
  xl: 18px
  card: 24px
  full: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 20px
  xxl: 24px
  page-x: 20px
  bottom-safe: 110px
components:
  soft-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.card}"
    padding: 18px
  pulse-card:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.text}"
    rounded: "{rounded.card}"
    padding: 18px
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.xl}"
    height: 52px
  chip-meta:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.text}"
    rounded: "{rounded.full}"
    padding: 10px
  chip-tag:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary}"
    rounded: "{rounded.full}"
    padding: 10px
---

# UriPan Design System

## Overview

UriPan should feel like a warm family situation board, not a generic task app. The UI is calm, readable, and practical for repeated household use: parents checking schedules, children seeing chores, and everyone noticing pinned family updates.

The primary emotional target is "softly organized." Screens should make the day easier to scan without becoming decorative or precious. The app can be friendly, but it should still behave like an operational tool: clear hierarchy, stable controls, short labels, and predictable navigation.

## Colors

The palette is warm and domestic, with olive green as the main action color.

- **Primary Olive (#647D31):** Primary actions, selected navigation, task completion, and important active states.
- **Warm Yellow Background (#FFF2BB):** The page foundation. It gives UriPan its family-board identity and should remain visible around cards.
- **White Surface (#FFFFFF):** Cards, sheets, dialogs, and form surfaces.
- **Soft State Colors:** Use `primary-soft`, `success-soft`, `warning-soft`, and `info-soft` to distinguish schedules, tasks, notices, and guidance without turning the interface into a rainbow.
- **Text Navy (#13243B):** Main text color. Avoid pure black.
- **Muted Slate (#64748B):** Secondary labels, helper text, and low-priority metadata.

Do not introduce new dominant purple, dark-blue dashboard, beige-only, or generic SaaS palettes. Any new feature should first try the existing semantic colors.

## Typography

Typography is compact and steady. Use weight and spacing to show hierarchy rather than oversized marketing-style headings.

- **Headlines:** Use 24-32px only for page-level identity such as the board name or major empty states.
- **Section titles:** Use 16px bold for list sections like Today schedules, tasks, notices, and members.
- **Item titles:** Use 14px bold so cards stay dense enough for family scanning.
- **Body text:** Use 14-16px regular with relaxed line height for Korean readability.
- **Labels and chips:** Use 12-14px bold. Letter spacing stays `0px`.

Avoid viewport-scaled text. If content is long, wrap or truncate intentionally instead of shrinking unpredictably.

## Layout

UriPan is mobile-first. The primary layout is one vertical board with full-width bands and repeated item cards.

- Keep page horizontal padding at 20px.
- Keep bottom content padding large enough for the bottom navigation: 110px.
- Use 8px and 12px spacing for dense relationships, 20px and 24px for section breaks.
- Cards should be repeated items or framed controls, not nested page sections.
- Bottom navigation is persistent and controlled; primary add actions live in the header to avoid overlap.
- Modal sheets must scroll when content grows, especially add/detail sheets with date, tag, and action controls.

## Elevation & Depth

Depth should be subtle. Cards use a light shadow and border to lift from the warm background; dialogs and sheets can rely on Material elevation.

- Soft cards: white surface, 24px radius, faint navy shadow.
- Avoid heavy shadows, glass effects, or gradient blobs.
- State chips should feel embedded, not floating.

## Shapes

Shapes are rounded but stable.

- Repeated item cards: 24px radius.
- Icon wells: 15-17px radius.
- Primary buttons: 18px radius.
- Meta and tag chips: full pill radius.
- Avoid putting cards inside cards.

## Components

**SoftCard:** The default repeated container for items, summaries, and member panels. It should have stable padding and never resize on hover or state changes.

**PulseCard:** The Today summary. It appears before lists and must stay concise: schedules count, open tasks count, notices count.

**AddItemSheet:** The creation surface. Order fields as type, date/time when relevant, title, memo, tags, options, submit. Tags are user-entered, not auto-generated.

**Tag Input:** Use one text field plus preview chips. Split by comma or whitespace, trim `#`, remove duplicates, cap at 5 tags and 12 characters per tag. Chips are removable in the sheet.

**ItemCard:** Show title, detail, time/owner metadata, and up to 3 tag chips. Do not show every tag on the card if it makes the list tall.

**ItemDetailSheet:** Show system metadata first, memo second, user tags as a separate chip group third, then actions. Keep user tags visually distinct from system status chips.

**BottomNav:** Five stable tabs: Today, Calendar, Tasks, Notices, Members. Selection state should be obvious through icon color and soft background.

## Do's and Don'ts

Do:

- Preserve the warm yellow background and olive primary action identity.
- Keep Today as the home base for daily family value.
- Make every interactive control reachable with a clear icon, label, or tooltip.
- Use scrollable sheets whenever content can grow.
- Keep tags manual and lightweight until search/filtering is intentionally designed.

Don't:

- Do not create a marketing landing page inside the app shell.
- Do not mix user tags with system state chips in detail views.
- Do not add color pickers, tag management screens, or automatic suggestions before the core board flow is stable.
- Do not hide backend failures behind empty states.
- Do not let floating add controls overlap bottom navigation or list content.
