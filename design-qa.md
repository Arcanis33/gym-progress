# Design QA — mobile cutout themes

## Evidence

- Selected visual target: `C:\Users\test1\.codex\generated_images\01a05160-6f12-78b3-a459-668665dcd089\exec-afde9c0c-4b61-4953-92da-baf25d1e65c8.png`.
- Artem implementation: `theme-artem-mobile-v2.png` at 390 × 844 CSS px.
- Natasha implementation: `theme-natasha-mobile-v2.png` at 390 × 844 CSS px.
- Side-by-side review: `qa-mobile-v2-comparison.png`.
- State: local preview data; mobile viewport; both athlete themes; exercise creation and workout recording.

## Visual review

| Surface | Result | Evidence |
| --- | --- | --- |
| Selected direction | Passed | The implementation follows option 2: compact segmented switcher, a shallow character strip, one action row and a dense exercise list. |
| Image placement | Passed | Natasha uses palette left, sunglasses portrait center and illustrated portrait right. Artem uses Rumbling left, Itachi center and the angel pair right. |
| Image treatment | Passed | All six supplied images are transparent cutouts, remain clearly visible and never sit behind controls or training data. |
| Light themes | Passed | Both Artem and Natasha use light paper surfaces; personality comes from accent color and artwork rather than a dark page background. |
| Mobile readability | Passed | Primary result and progression remain visible at 390 px; low-value desktop columns collapse without horizontal scrolling. |
| Touch ergonomics | Passed | Athlete switch, add-exercise and recording controls stay at the top and use phone-friendly hit areas. |

## Interaction review

- Artem → Natasha and Natasha → Artem switch: passed.
- Add exercise dialog, muscle group selection and appearance in the relevant workout day: passed.
- Record flow: day → exercise → athlete/weight/reps → save: passed in preview mode.
- Desktop exercise click → right-side statistics with chart, target, percentage and history: passed.
- Mobile exercise tap → full-screen statistics card with chart, percentage, history and close action: passed at 390 × 844.
- Artem blue/steel palette and artwork-backed primary action: passed on desktop and mobile.
- Browser console: no errors or warnings.
- Local preview HTTP response: 200.

## Findings

- P0: none.
- P1: none.
- P2: none.

final result: passed
