import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    var onFrame: (CVPixelBuffer) -> Void
    
    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        context.coordinator.setup(onFrame: onFrame, previewView: v)
        return v
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private let session = AVCaptureSession()
        private let output = AVCaptureVideoDataOutput()
        private var onFrame: ((CVPixelBuffer) -> Void)?
        
        func setup(onFrame: @escaping (CVPixelBuffer) -> Void, previewView: PreviewView) {
            self.onFrame = onFrame
            session.beginConfiguration()
            session.sessionPreset = .high
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)
            
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
            output.alwaysDiscardsLateVideoFrames = true
            let settings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.videoSettings = settings
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            
            if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            previewView.videoPreviewLayer.session = session
            session.commitConfiguration()
            session.startRunning()
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            onFrame?(pb)
        }
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
