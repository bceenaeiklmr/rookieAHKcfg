# Worktime Logger

A lightweight, daily worktime tracking and statistics dashboard built in **AutoHotkey v2**.

---

## Features

- **Daily Time Tracking**:
  - Log `Start` and `End` times for any workday.
  - Quick **"Start Now"** and **"End Now"** buttons for immediate timestamping.
  - **"Fill Default"** button to auto-fill the standard schedule for the selected day.
  - Dedicated **Lunch break** deduction (defaults to 20 minutes).
  - Dedicated **🏠 Home Office** checkbox to mark remote workdays.
  - Optional **Note** field for context (e.g., Doctor, Sick Leave).
- **Missing & Incomplete Workdays Tracking**:
  - Automatically scans past workdays for unrecorded days or incomplete entries (e.g., clocked in but forgot to record end time).
  - Quick **"Missing Days"** dropdown in the header displays issues (most recent first) and jumps directly to that date on selection.
  - Dedicated **"🔍 Check Missing"** dialog to filter by scope (*Since First Log*, *This Month*, *Past 14 Days*, *Past 30 Days*).
  - One-click **"⚡ Fill with Default"** action in the dialog to quickly backfill standard hours.
- **Date Navigation & Editing**:
  - Jump back and forth between days using `◄` / `►` or select any date with the date picker.
  - Click **"Today"** to instantly jump back to current date.
  - Review, edit, or delete any past entries anytime.
- **Live Day Progress & Target Estimation**:
  - Flexible start times (07:00 – 09:00).
  - Live elapsed time tracking during active workdays (auto-updates every minute).
  - Displays **Expected End Time** and **Remaining Time** for the day based on your actual start time.
- **Comprehensive Statistics & Plan Balance**:
  - **Today**: Logged / live time worked, daily target, balance, and remaining time.
  - **This Week**: Monday–Sunday totals, target pace so far, full 40h target, balance, and remaining time to complete the week.
  - **This Month**: Month-to-date worked hours vs. month target, balance, and remaining hours for the month.
  - **All Time**: Cumulative worked vs. target for all logged days, showing overall overtime/undertime balance.
- **Simple, Transparent Storage**:
  - Saves all entries in standard UTF-8 CSV: [`worktime.csv`](file:///C:/dev/projects/worktime/worktime.csv).
  - Click **"Open CSV"** to view and edit directly in Excel or any text editor.
- **rookieAHKcfg Ready**:
  - Encapsulated in `WorktimeLogger` class.
  - Runs standalone or seamlessly included in your main AHK configuration.

---

## Working Hours & Target Schedule

| Days | Default Hours | Gross | Lunch Deduction | Net Target |
| :--- | :--- | :--- | :--- | :--- |
| **Monday – Thursday** | 08:00 – 16:40 | 8h 40m | 20 minutes | **8h 20m** (500 min) |
| **Friday** | 08:00 – 15:00 | 7h 00m | 20 minutes | **6h 40m** (400 min) |
| **Weekly Total** | — | — | — | **40h 00m** |
| **Weekend** | — | — | — | **0h 00m** (Any work is overtime) |

*Flexible Start*: If you start at 07:15 on Monday, your planned end is automatically calculated as `07:15 + 8h 20m + 20m = 15:55`.

---

## File Structure

```text
C:\dev\projects\worktime\
├── worktime.ahk      # Main AutoHotkey v2 application
├── worktime.csv      # CSV database (Date,Start,End,Lunch,Note)
└── README.md         # Documentation
```

---

## Usage

### Standalone

Double-click [`worktime.ahk`](file:///C:/dev/projects/worktime/worktime.ahk) or run:

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\dev\projects\worktime\worktime.ahk"
```

### Shortcuts Inside the Application

- **Enter**: Save the current day's entry.
- **Ctrl + S**: Save the current day's entry.
- **Escape**: Close / hide window.

---

## Integration with [`rookieAHKcfg`](https://github.com/bceenaeiklmr/rookieAHKcfg)

To integrate into your main AutoHotkey configuration:

1. Add `#include` to your `rookieAHKcfg.ahk`:
   ```ahk
   #include C:\dev\projects\worktime\worktime.ahk
   ```
   *(or copy `worktime.ahk` into your `src/` directory)*

2. Bind to a hotkey or menu item of your choice:
   ```ahk
   ; Example: Win + Shift + W to open Worktime Logger
   #+w::WorktimeLogger.Show()
   ```

When `#include`d, `worktime.ahk` will not show on script boot; it only opens when `WorktimeLogger.Show()` is invoked, and pressing Escape or the close button simply hides the window without exiting your main script. The CSV path automatically resolves to the `worktime` project folder.
