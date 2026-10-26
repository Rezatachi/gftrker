# Food Matcher Regression

Run this checklist on a physical iPhone before a TestFlight upload.

## Automated Gate

```bash
zsh Tools/MatcherEvaluation/run.sh
```

Required:

- Exact-count accuracy >= 95%.
- Item recall >= 95%.
- Item precision >= 95%.
- Within-tolerance rate >= 95%.
- Gram MAPE <= 15%.
- Gram p95 APE <= 20%.
- Source compliance passes for cases that specify expected sources.
- Confidence compliance passes for cases that specify minimum confidence.
- Debug and Release builds succeed.

## Device Setup

- Build the Debug configuration with the personal development team.
- Confirm the app launches after a clean install.
- Confirm the app launches again after force quit.
- Confirm existing meals and settings remain after relaunch.
- Confirm Debug does not request or require iCloud.

## Food Log

1. Submit:
   `1/4 cup granola, some kimchi, handful of oats, 1/8 cup oat milk`
2. Verify four review items appear.
3. Verify the estimates are approximately:
   `28g`, `85g`, `25g`, and `30g`.
4. Submit `kimchi and soju`.
5. Verify both foods appear and no unrelated food appears.
6. Submit `oikos yogurt`.
7. Verify one food appears and the alternate-match control is available.
8. Submit `iced oat milk latte`.
9. Verify one food appears rather than separate oat milk and latte entries.
10. Submit `一碗米饭和两个鸡蛋`.
11. Verify rice and eggs both appear.

## Candidate Review

- Open the alternate-match menu.
- Verify no more than three candidates appear.
- Select the second candidate.
- Verify name, grams, range, calories, and macros update together.
- Adjust the grams after switching candidates.
- Confirm the meal and verify the selected values are saved.
- Verify candidate alternatives never increase the meal food count.

## Correction Memory

- Confirm a non-default candidate.
- Log the same normalized phrase again without force-quitting the app.
- Verify the confirmed candidate is returned from Saved correction.
- Force-quit and relaunch.
- Verify correction memory was cleared and no food or health data was uploaded
  to iCloud.

## Notifications

- Use the notification testing controls to schedule the test batch.
- Verify randomized text is used.
- Verify tapping a notification opens the app.
- Verify production reminders remain within the configured time window.

## Hydration

- Tap Water Drank once.
- Verify the animation completes and the button disables.
- Relaunch the app and verify it remains disabled for the same day.
- Change the test date or wait until the next day.
- Verify the button becomes available and analytics show Water Drank.

## Failure Criteria

Block release for:

- Missing or duplicated food phrases.
- Candidate changes that do not update nutrition values.
- Corrections selecting a previously rejected candidate.
- Data loss after relaunch.
- Notification or hydration actions firing more than once.
