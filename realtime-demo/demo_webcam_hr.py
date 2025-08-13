import cv2
import numpy as np
import time

# Face detector (for a stable forehead ROI)
FACE_CASCADE = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")

def estimate_hr(signal, fs=30.0):
    """
    Estimate heart rate (BPM) from a 1-D signal using FFT in the 0.7–4.0 Hz band.
    """
    x = signal.astype(np.float32)
    x = x - x.mean()
    std = x.std() + 1e-6
    x = x / std

    n = int(2 ** np.ceil(np.log2(len(x))))
    X = np.fft.rfft(np.pad(x, (0, n - len(x))))
    freqs = np.fft.rfftfreq(n, d=1.0 / fs)

    band = (freqs >= 0.7) & (freqs <= 4.0)  # ~42–240 bpm
    if band.sum() == 0:
        return None
    mag = np.abs(X)[band]
    fband = freqs[band]
    f = fband[np.argmax(mag)]
    return f * 60.0  # BPM

def main():
    # Prefer AVFoundation backend on macOS (permissions-friendly)
    cap = cv2.VideoCapture(0, cv2.CAP_AVFOUNDATION)
    if not cap.isOpened():
        cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        cap = cv2.VideoCapture(1, cv2.CAP_AVFOUNDATION)

    if not cap.isOpened():
        print("Could not open webcam")
        return

    values = []
    win_sec = 20            # seconds of history for FFT
    fs = 30.0               # target FPS
    max_len = int(win_sec * fs)
    last_est = None
    last_t = time.time()

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # --- Face/forehead ROI selection ---
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = FACE_CASCADE.detectMultiScale(
            gray, scaleFactor=1.1, minNeighbors=5, minSize=(120, 120)
        )

        if len(faces) > 0:
            (x, y, w, h) = max(faces, key=lambda f: f[2] * f[3])  # largest face
            # Forehead: upper ~20% of face, centered
            fh = int(0.18 * h)
            fw = int(0.5 * w)
            fx = x + (w - fw) // 2
            fy = y + int(0.15 * h)
            fx2, fy2 = fx + fw, fy + fh
            cv2.rectangle(frame, (fx, fy), (fx2, fy2), (0, 255, 0), 2)
            roi = frame[fy:fy2, fx:fx2]
        else:
            # Fallback centered square
            H, W = frame.shape[:2]
            size = min(H, W) // 3
            x0 = W // 2 - size // 2
            y0 = H // 2 - size // 2
            roi = frame[y0:y0 + size, x0:x0 + size]
            cv2.rectangle(frame, (x0, y0), (x0 + size, y0 + size), (0, 255, 0), 2)

        # Mean green intensity in ROI
        if roi.size > 0:
            g = roi[:, :, 1].mean() / 255.0
            values.append(g)
            if len(values) > max_len:
                values = values[-max_len:]

        # Update HR estimate ~2 Hz once we have enough data
        if time.time() - last_t > 0.5 and len(values) > max_len // 2:
            last_t = time.time()
            hr = estimate_hr(np.array(values), fs=fs)
            if hr is not None and 40 <= hr <= 220:
                last_est = hr

        # Draw label
        text = f"HR: {last_est:.0f} bpm" if last_est else "HR: --"
        cv2.putText(frame, text, (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)

        cv2.imshow("SmartHealthLens (Webcam)", frame)
        if cv2.waitKey(1) & 0xFF == 27:  # ESC to quit
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()

