# Audiogram-Testing-System

# Auditory Training System

MATLAB-based auditory training software for critical listening practice, calibration, and hearing-profile-aware support.

## Overview

This project is a multi-step auditory training system built in MATLAB. It is designed to:

- screen users through audiogram entry and eligibility checks,
- support both `Normal` and `Adjusted` users,
- calibrate a starting boost level before training begins,
- provide guided critical-listening familiarization with pink noise,
- run progressive boost and cut discrimination training,
- persist user session state between steps,
- and export practice-session results for later analysis.

The system is best described as a **personalized critical-listening trainer with audiogram-aware support**.

## Main Workflow

The program runs in three main stages, with an additional familiarization page between Steps 1 and 2.

### Step 1: Audiogram Entry

Files:

- `Step1_Audiogram_Entry.m`
- `Step1_Audiogram_Entry_TEST.m`

What it does:

- collects the user name,
- walks the user through hearing setup,
- explains eligibility requirements,
- accepts 7 audiogram thresholds,
- treats blank fields as `0 dB HL`,
- rejects values above `20 dB HL`,
- classifies the user as `Normal` or `Adjusted`,
- logs eligibility outcomes,
- saves session state for later steps.

Classification rule:

- `Normal`: all entered values are below `10 dB HL`
- `Adjusted`: at least one value is between `10 dB HL` and `20 dB HL`

### Interim Familiarization Page

File:

- `ATS_CriticalListeningIntro.m`

What it does:

- explains what the user should listen for before calibration,
- plays an unboosted pink-noise reference,
- lets the user hear `+12 dB` pink-noise examples at each target frequency,
- prepares first-time users to recognize boosted frequency bands before scoring starts.

### Step 2: Initial Calibration

Files:

- `Step2_Calibration_10sec.m`
- `Step2_Calibration_2sec_TEST.m`

What it does:

- runs a 10-trial calibration block,
- uses **pink noise only**,
- randomly selects one target frequency per trial,
- applies a boost at that frequency,
- asks the user to identify the boosted band,
- determines the user’s starting difficulty level.

Calibration levels:

- `12 dB`
- `15 dB`
- `18 dB`
- `20 dB`

Pass criterion:

- `8 / 10` correct (`80%`)

Adjusted-user behavior:

- starts with `100%` mapped audiogram compensation,
- reduces compensation in `25%` steps when the user passes,
- increases boost level when the user fails,
- carries the resulting boost level and compensation state into Step 3.

### Step 3: Training, Test, and Results

Files:

- `Step3_Training_System_10sec.m`
- `Step3_Training_System_2sec_TEST.m`

What it does:

- runs the main training environment,
- supports both `Boost` and `Cut` listening modes,
- allows practice at unlocked levels,
- runs 10-round tests to unlock harder levels,
- stores unlock state,
- shows results and exports practice-session CSV data.

Difficulty ladder:

- `20 dB`
- `18 dB`
- `15 dB`
- `12 dB`
- `9 dB`
- `6 dB`
- `3 dB`

Unlock behavior:

- the calibration level and easier higher-dB levels are available first,
- passing a level unlocks the next lower-dB level in sequence.

Example:

- if a user starts at `12 dB`, then `20`, `18`, `15`, and `12` are available immediately,
- `9`, `6`, and `3` must be unlocked in order.

## User Groups

### Normal Users

- no audiogram compensation is applied,
- calibration only determines the starting boost level,
- Step 3 training uses the unlocked progression without hearing-loss correction.

### Adjusted Users

- audiogram values are mapped from the 7-entry audiogram frequency set to the 8-band training frequency set,
- compensation is applied during calibration and Step 3 playback,
- compensation is preserved as meaningful gain,
- task-specific boost or cut is applied after compensation,
- playback uses safety limiting rather than strong normalization.

## Signal Chain

The final signal path is designed to preserve hearing support while protecting playback peaks:

```text
source -> audiogram compensation -> target boost/cut -> safety limiter -> playback
```

This means:

- compensation remains meaningful for `Adjusted` users,
- task difficulty still comes from the active boost or cut,
- the system avoids flattening the signal with aggressive post-processing normalization,
- peak protection is only applied when needed.

## Pink Noise Helpers

Files:

- `ATS_generatePinkNoise.m`
- `ATS_makePinkNoiseStimulus.m`
- `ATS_applySafetyLimiter.m`

These helpers generate pink-noise signals for familiarization and calibration, apply multiband EQ gains, and protect the final waveform from clipping.

## Session Persistence

Files:

- `ATS_getProjectDir.m`
- `ATS_getSessionFile.m`
- `ATS_loadSessionData.m`
- `ATS_saveSessionData.m`

These helpers manage shared session state across the full workflow.

Session data includes:

- user name,
- user group,
- audiogram data,
- maximum audiogram value,
- mapped baseline audiogram,
- calibration completion,
- calibration boost level,
- audiogram compensation percentage,
- unlocked boost levels,
- unlocked cut levels.

## Quick Launch Scripts

Files:

- `QuickTest_10sec.m`
- `QuickTest_2sec.m`

These skip the earlier workflow and open Step 3 directly for rapid testing.

## Repository File Guide

### Core MATLAB files

- `Step1_Audiogram_Entry.m`
- `Step1_Audiogram_Entry_TEST.m`
- `Step2_Calibration_10sec.m`
- `Step2_Calibration_2sec_TEST.m`
- `Step3_Training_System_10sec.m`
- `Step3_Training_System_2sec_TEST.m`

### Helper MATLAB files

- `ATS_CriticalListeningIntro.m`
- `ATS_generatePinkNoise.m`
- `ATS_makePinkNoiseStimulus.m`
- `ATS_applySafetyLimiter.m`
- `ATS_getProjectDir.m`
- `ATS_getSessionFile.m`
- `ATS_loadSessionData.m`
- `ATS_saveSessionData.m`

### Convenience files

- `QuickTest_10sec.m`
- `QuickTest_2sec.m`

### Documentation

- `README.md`

## Requirements

- MATLAB with App Designer-compatible UI support (`uifigure`, `uibutton`, `uipanel`, etc.)
- Audio Toolbox functionality used by `multibandParametricEQ`
- Local audio playback support

## Audio Asset Requirement

Step 3 still depends on external `.wav` files referenced inside the training scripts.

Those files are not included in this repo snapshot. To run the full music-based training workflow, you must either:

1. place the expected `.wav` files at the paths referenced in the scripts, or
2. update the `Audio_Files{}` paths inside the Step 3 scripts to match your environment.

Calibration and familiarization use generated pink noise and do not require those external music files.

See:

- `audio/README.md`

## How to Run

### Full production flow

Run:

```matlab
Step1_Audiogram_Entry
```

### Full short test flow

Run:

```matlab
Step1_Audiogram_Entry_TEST
```

### Direct training launch

Run one of:

```matlab
QuickTest_10sec
QuickTest_2sec
```

## Current Status

The project is functionally complete as a MATLAB auditory training workflow.

Strongest completed features:

- coherent multi-step workflow,
- stabilized session handoff,
- familiarization before calibration,
- pink-noise-only initial calibration,
- shared unlock progression,
- aligned interface aesthetics,
- hearing-support-oriented compensation behavior.

Main remaining limitations:

- Step 3 still uses hard-coded external audio file paths,
- test-mode export is not as rich as a full research trial log,
- production and test scripts are still duplicated rather than parameterized.

## Recommended Future Improvements

- replace hard-coded audio asset paths with project-relative loading,
- add richer per-trial logging for both practice and test modes,
- refactor duplicated production and test scripts into shared functions,
- centralize constants into a single configuration file,
- add automated logic validation for classification, mapping, unlock progression, and session persistence.

## Notes for GitHub Users

If you are cloning this project for the first time:

- start by reading this file,
- check the Step 3 audio paths before trying to run the full training workflow.
