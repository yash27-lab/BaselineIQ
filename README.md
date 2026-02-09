# BaselineIQ

**Local-first health metrics drift detection for primary care — turn Apple Health and CSV data into actionable clinical insights**

![macOS](https://img.shields.io/badge/platform-macOS-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## What is BaselineIQ?

BaselineIQ is a macOS app that analyzes your health data to detect meaningful changes ("drift") in vital signs before they become obvious problems. All processing happens locally on your device — no cloud uploads, no data sharing.

## Benefits

### For Patients
- **Own your health data** — Import from Apple Health or CSV, processed locally (no cloud uploads)
- **Spot trends early** — See changes before they become obvious problems
- **Prepare for appointments** — One-page summary to share with your doctor

### For Primary Care Clinicians
- **Save time** — Quick visual summary instead of scrolling through raw data
- **Statistical backing** — Z-scores and percent changes, not just "it looks high"
- **Context-aware alerts** — Distinguishes noise from real drift (data density confidence)
- **Explainable** — Shows *what* changed, *when*, *how much*, and *why* it's flagged

### Key Value Proposition

| Problem | BaselineIQ Solution |
|---------|---------------------|
| Wearable data is overwhelming | Focuses on 6-8 clinically relevant signals |
| Hard to spot gradual changes | Compares last 7 days vs 30-day baseline |
| "Is this normal for me?" | Z-score shows deviation from YOUR personal baseline |
| Data gaps cause false alarms | Data density warnings when coverage is low |
| Takes too long in appointments | One-page PDF with key drifts + sparklines |

## Features

- **Import**: Apple Health `export.xml` and CSV files
- **Metrics Tracked**: Resting HR, Sleep, SpO₂, Weight, Blood Pressure, Glucose
- **Detection**: 30-day rolling baseline vs last 7 days comparison
- **Output**: Z-score, percent change, data density confidence
- **Explanations**: What changed, when, how big, why flagged, missing data warnings
- **Export**: Professional one-page PDF summary

## Example Use Cases

1. **Pre-visit prep** — Patient exports Apple Health before annual checkup
2. **Post-illness monitoring** — Track recovery after acute event
3. **Lifestyle intervention tracking** — Show progress in weight/BP over months
4. **Metabolic syndrome screening** — Catch gradual glucose/weight creep early

## Installation

1. Clone this repository
2. Open `BaselineIQ.xcodeproj` in Xcode
3. Build and run (⌘R)

```bash
git clone https://github.com/yash27-lab/BaselineIQ.git
cd BaselineIQ
open BaselineIQ.xcodeproj
```

## Usage

1. Click **Import CSV** or **Import Apple Health** to load your data
2. View detected drifts in the main dashboard
3. Click **Export PDF** to generate a one-page clinician summary

### CSV Format

```csv
date,metric,value
2025-01-01,restingHeartRate,62
2025-01-01,sleepDuration,7.5
2025-01-02,oxygenSaturation,98.2
```

Supported metrics: `restingHeartRate`, `sleepDuration`, `oxygenSaturation`, `weight`, `glucose`, `bloodPressureSystolic`, `bloodPressureDiastolic`

## How Drift Detection Works

1. **Baseline**: Calculate mean and standard deviation from last 30 days
2. **Recent**: Calculate mean from last 7 days
3. **Z-Score**: `(recent_mean - baseline_mean) / baseline_std`
4. **Flag**: Alert when |z-score| ≥ 2.0 (statistically significant)
5. **Confidence**: Adjusted based on data density (more data = higher confidence)

## Disclaimer

⚠️ **NOT MEDICAL ADVICE**

This tool is for informational purposes only. It is not a diagnosis or substitute for professional medical judgment. Clinical decisions should be made by a licensed healthcare provider with full patient context.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please open an issue or submit a pull request.
