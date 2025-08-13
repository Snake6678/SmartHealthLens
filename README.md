# SmartHealthLens — On‑Device Health Insights (Camera + Sensors)

Real-time, privacy-first health analytics using camera and sensors. This repo includes:
- **iOS (SwiftUI + AVFoundation + CoreMotion)**: Real-time camera capture, rPPG signal extraction (green-channel), FFT-based heart-rate estimate, step cadence, and a clean SwiftUI dashboard. *(Add these files into an Xcode iOS App project — directions below.)*
- **Realtime Demo (Python/OpenCV)**: A Mac-ready demo that estimates heart rate from your webcam using non-ML rPPG and displays the live estimate.
- **Model Training (Python/PyTorch)**: A training scaffold for a tiny CNN/GRU that predicts HR/BR from short rPPG windows, with Core ML conversion hooks.

> Why this impresses Apple: It showcases on-device signal processing, efficient UI, privacy-by-design, and a clear path to **Core ML** deployment.

---

## Quick Start (Mac)

### 1) Run the webcam demo (no Xcode needed)
```bash
cd realtime-demo
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python demo_webcam_hr.py
```
- Move your face or fingertip into view with decent light. The HR estimate stabilizes after ~20–40 seconds.
- This demo is **non-ML** (pure signal processing) to stay entirely on-device and transparent.

### 2) iOS app (SwiftUI)
1. Open Xcode → File → New → Project → iOS App (SwiftUI, Swift).
2. Name it **SmartHealthLens**, Interface **SwiftUI**, Lifecycle **SwiftUI App**.
3. In the new project, add the files from `ios/SmartHealthLens/` (drag the entire folder into Xcode, select "Copy items if needed").
4. Add to **Info.plist**:
   - `Privacy - Camera Usage Description` = "Needed to analyze subtle color changes for heart rate."
   - `Privacy - Motion Usage Description` = "Used for activity/cadence insights."
5. Run on device (recommended). The app shows live camera feed, signal plot, and HR estimate.

### 3) Train a tiny model (optional)
```bash
cd model-training
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python train_stub.py
```
- This provides a training pipeline scaffold. Replace the `Dataset` with your data loader.
- Use `export_coreml.py` to convert your trained model to Core ML for iOS.

---

## Repository Structure

```
SmartHealthLens/
├── README.md
├── LICENSE
├── ios/
│   └── SmartHealthLens/
│       ├── SmartHealthLensApp.swift
│       ├── ContentView.swift
│       ├── CameraView.swift
│       ├── SignalProcessor.swift
│       ├── HeartRateEstimator.swift
│       ├── SensorManager.swift
│       └── Utilities.swift
├── realtime-demo/
│   ├── requirements.txt
│   └── demo_webcam_hr.py
└── model-training/
    ├── requirements.txt
    ├── train_stub.py
    └── export_coreml.py
```

---

## Roadmap / Stretch
- Add **Core ML** model for HR/BR inference (replace or augment FFT estimator).
- **Apple Watch** extension: fuse PPG and accelerometer.
- **AR overlay** with ARKit.
- Quantization-aware training + Core ML Tools conversion.

## License
MIT
