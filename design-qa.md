# Design QA — shared Artem/Natasha layout

## Evidence

- Artem source visual truth: `C:\Users\test1\.codex\generated_images\01a05160-6f12-78b3-a459-668665dcd089\exec-ebea2f8c-2406-49ed-b232-619be0e09258.png`.
- Natasha source visual truth: `C:\Users\test1\.codex\generated_images\01a05160-6f12-78b3-a459-668665dcd089\exec-13d5890b-f9f6-48db-9e2f-6a3a24fac990.png`.
- Mobile implementation: `implementation-mobile-final-v2.png`, `implementation-natasha-mobile-final.png`, `implementation-artem-values-mobile.png`, and `implementation-natasha-values-mobile.png`.
- Desktop implementation: `implementation-desktop-final-full.png` and `implementation-natasha-desktop-final.png`.
- Side-by-side evidence: `qa-artem-final-comparison.png`, `qa-natasha-final-comparison.png`, and `qa-natasha-values-final-comparison.png`.
- Viewports: 390 × 844 CSS px at device scale 1; desktop 1440 × 1024 CSS px at device scale 1.
- Density normalization: source mockups were center-cropped/resized to 390 × 844 for comparison; implementation captures are native 390 × 844 pixels.
- State: preview dataset, both athlete themes, main dashboard, recording entry, exercise statistics, and add-exercise dialog.

## Required fidelity surfaces

- Fonts and typography: Manrope remains consistent across both themes. The final title is exactly `Дневник прогресса`; hierarchy, compact row text, and form labels remain readable at 390 px.
- Spacing and layout rhythm: both personas use the same topbar, switcher, hero, toolbar, recording banner, exercise list, statistics and recording drawer positions. The recording banner is directly below search/add controls on phone and desktop.
- Colors and visual tokens: Artem uses a light blue/steel palette; Natasha uses the same light surfaces with rose/wine accents. Contrast passes visually on buttons, fields and result rows.
- Image quality and asset fidelity: all visible art uses supplied raster assets. Header backgrounds use controlled edge fades; hero cutouts remain sharp; recording-banner art sits beside copy; result-entry art is cropped to the right and does not cover inputs.
- Copy and content: `Спокойная аналитика` is removed. Exercise results, targets, percentages, dates and Russian action labels remain present.

## Interaction verification

- Artem/Natasha switcher: passed at 390 × 844 and 1440 × 1024.
- Recording flow day → exercise → athlete/weight/repetitions: passed for both themes.
- Exercise tap → detailed mobile statistics with graph: passed.
- Add-exercise dialog opening: passed.
- Desktop exercise selection and right-side statistics: passed.
- Browser console errors/warnings: none.
- Local preview response/rendering: passed.

## Comparison history

1. Initial mobile capture found two P2 issues: legacy mobile CSS hid the recording-banner copy, and inherited `object-fit: contain` made the header background read as an isolated image rather than an integrated layer.
2. Fixes: explicitly restored banner copy/icon visibility, reset the switcher surface, and applied a full-width `cover` crop with a controlled fade behind the hero cutout.
3. Post-fix evidence: `implementation-mobile-final-v2.png`, `implementation-natasha-mobile-final.png`, `qa-artem-final-comparison.png`, and `qa-natasha-final-comparison.png`. No remaining P0/P1/P2 issue was observed.

## Findings

- P0: none.
- P1: none.
- P2: none.
- P3: the generated mockups contain decorative bottom navigation that is not part of the existing web app. It was intentionally not introduced because the user required element positions and application behavior to remain unchanged.

Focused comparison was required for the recording banner and result-entry artwork; both are included in the side-by-side evidence above.

## Mobile artifact correction pass

- Updated visual evidence: `implementation-mobile-artifacts-fixed.png`, `implementation-natasha-mobile-artifacts-fixed.png`, `implementation-mobile-detail-fixed.png`, and `implementation-mobile-form-fade-fixed.png`.
- Updated comparisons: `qa-artem-artifacts-fixed-comparison.png` and `qa-natasha-artifacts-fixed-comparison.png` at 390 × 844 CSS px, device scale 1.
- Earlier P2: low-resolution header sources became visibly pixelated under `cover` cropping. Fix: both header sources were replaced with high-resolution upscaled assets and rechecked in both themes.
- Earlier P1: the sticky header could remain visually above the mobile statistics surface. Fix: opening a mobile exercise now applies `detail-open`, fully hides the topbar and persona header, and gives statistics the complete 100dvh viewport.
- Earlier P2: the result-entry illustration met the opaque form at a hard vertical seam. Fix: the form surface and image mask now overlap across a longer multi-stop fade while all controls remain on an opaque readable area.
- Post-fix interaction evidence: `topbarVisible: false`, `personaVisible: false`, and `detailVisible: true` when mobile statistics is open. Browser console contained no warnings or errors.
- Remaining P0/P1/P2 findings: none.

## Single-image edge-fade correction

- Source visual truth: `C:\Users\test1\AppData\Local\Temp\codex-clipboard-57a9fa77-b46e-4eaa-ba7f-68ec91998a37.png` (591 × 1280 px), showing the hard rectangular top edge in the result-entry artwork.
- Browser-rendered implementations: `implementation-artem-values-singlefade.png` and `implementation-natasha-values-singlefade.png`, each captured at 390 × 844 CSS px and 390 × 844 output pixels, device scale 1.
- Side-by-side full-view evidence: `qa-values-singlefade-comparison.png`; the source was normalized to the same 390 × 844 display box. The full view makes the affected top, left, right, and bottom edges legible, so a separate focused crop was not required.
- State: preview dataset, mobile result-entry screen, `Жим ногами`, verified in both athlete themes.
- Earlier P1: the illustration started at a hard rectangular top boundary. The first attempted correction intersected two linear masks, which did not match the intended single-image treatment.
- Final fix: each theme still renders exactly one `<img>`; one radial mask now makes that single raster image dissolve continuously toward every edge. No duplicate artwork layer, pseudo-element, or secondary mask remains.
- Fonts and typography: unchanged; all form labels and values retain their original hierarchy and remain readable.
- Spacing and layout rhythm: unchanged; controls remain in their existing positions and the art stays behind the form overlap.
- Colors and visual tokens: unchanged; Artem keeps blue/steel controls and Natasha keeps rose controls.
- Image quality and asset fidelity: the supplied raster assets are preserved, with a single non-destructive CSS mask and corrected focal positioning.
- Copy and content: unchanged.
- Primary interactions tested: theme switch, recording mode, day selection, exercise selection, and result-entry controls.
- Browser console errors/warnings: none.
- Remaining P0/P1/P2 findings: none.

## Form-overlay seam correction

- Source visual truth: `C:\Users\test1\AppData\Local\Temp\codex-clipboard-3355b70b-f41d-4a7a-92bc-96beebd5ac07.png` (423 × 267 px), focused on the visible vertical rectangle below the save button.
- Implementations: `implementation-artem-values-seam-fixed.png` and `implementation-natasha-values-seam-fixed.png`, captured at 390 × 844 CSS/output px, device scale 1.
- Focused normalized comparison: `qa-form-seam-comparison.png`, showing the same lower form/art region before and after.
- Earlier P1 diagnosis corrected: the visible seam came from the finite rectangular background of `#record-form`, not from a duplicate artwork layer.
- Fix: the mobile form container is now transparent; the input fields and save button retain their own opaque surfaces, so readability remains intact while the single masked image is uninterrupted underneath.
- Typography, spacing, palette, assets and copy remain unchanged. Both themes and the complete recording flow were rechecked; browser console errors/warnings: none.
- Remaining P0/P1/P2 findings: none.

## Exercise discovery and analytics expansion

- Mobile implementation: `implementation-mobile-analytics-v3.png` and `implementation-mobile-image-dialog.png`, captured at 390 × 844 CSS/output px, device scale 1.
- Desktop implementation: `implementation-desktop-analytics-v3.png`, captured at 1440 × 1024 CSS/output px, device scale 1.
- State: preview dataset, positive-progress exercise with two sessions, expanded statistics view, and exercise-image dialog.
- Positive changes: arrow, value, and detail progress percentage use the same semantic green in both athlete themes.
- Muscle-group discovery: compact Material Symbols badges sit directly beside exercise names in the list, recorder and detail heading without changing the row structure.
- Analytics: the mixed dual-axis chart was replaced with separate working-weight, repetition, and estimated-1RM charts. Each date represents the best working set of that workout, preventing duplicate or competing points. Assisted exercises omit the invalid 1RM chart.
- Useful summary metrics: best working load, best repetitions, estimated 1RM (or best assisted set) are shown; no total-volume metric was introduced.
- Image editing: mobile dialog, preview, client-side resize/compression, reset-to-default, and preview upload flow passed. Supabase migration completed successfully for persistent storage.
- Fonts, spacing, colors, image quality and copy were checked at both viewports. Primary interactions and browser console: passed with no application warnings or errors.
- Remaining P0/P1/P2 findings: none.

final result: passed
