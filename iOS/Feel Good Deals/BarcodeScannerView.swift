import SwiftUI
import AVFoundation

// MARK: - SwiftUI wrapper

struct BarcodeScannerView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = ScannerViewController
    
    /// Called when a code is scanned or the scanner is dismissed
    let completion: (String?) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    } // func makeUIViewController
    
    func updateUIViewController(_ uiViewController: ScannerViewController,
                                context: Context) {
        // Nothing to update
    } // func updateUIViewController
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    } // func makeCoordinator
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        
        let parent: BarcodeScannerView
        
        init(parent: BarcodeScannerView) {
            self.parent = parent
        } // init
        
        func scannerViewController(_ controller: ScannerViewController,
                                   didScanCode code: String) {
            parent.completion(code)
        } // func scannerViewController
        
        func scannerViewControllerDidCancel(_ controller: ScannerViewController) {
            parent.completion(nil)
        } // func scannerViewControllerDidCancel
        
    } // class Coordinator
    
} // struct BarcodeScannerView

// MARK: - Delegate protocol

protocol ScannerViewControllerDelegate: AnyObject {
    
    func scannerViewController(_ controller: ScannerViewController,
                               didScanCode code: String)
    
    func scannerViewControllerDidCancel(_ controller: ScannerViewController)
    
} // protocol ScannerViewControllerDelegate

// MARK: - UIKit scanner implementation

class ScannerViewController: UIViewController {
    
    weak var delegate: ScannerViewControllerDelegate?
    
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let scanBoxView = UIView()
    private let scanLineView = UIView()
    private var videoDevice: AVCaptureDevice?
    
    // Track zoom
    private var lastZoomFactor: CGFloat = 1.0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        checkCameraAuthorization()
        setupCancelButton()
        setupPinchGesture()
        setupScanBox()
        
    } // override func viewDidLoad
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer?.frame = view.bounds
        
        updateScanBoxFrame()
        updateRectOfInterest()
        
    } // override func viewDidLayoutSubviews
    
    // MARK: - Camera permission
    
    private func checkCameraAuthorization() {
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
            
        case .authorized:
            setupCaptureSession()
            
        case .notDetermined:
            
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                
                DispatchQueue.main.async {
                    
                    guard let self = self else {
                        return
                    } // guard let self
                    
                    if granted {
                        self.setupCaptureSession()
                    } else {
                        self.delegate?.scannerViewControllerDidCancel(self)
                    } // if granted
                    
                } // DispatchQueue.main.async
                
            } // AVCaptureDevice.requestAccess
            
        case .denied,
             .restricted:
            
            delegate?.scannerViewControllerDidCancel(self)
            
        @unknown default:
            delegate?.scannerViewControllerDidCancel(self)
            
        } // switch status
        
    } // func checkCameraAuthorization
    
    // MARK: - Capture setup
    
    private func setupCaptureSession() {
        
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            return
        } // guard let videoDevice
        
        self.videoDevice = videoDevice
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        } // guard let videoInput
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        } // if captureSession.canAddInput
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self,
                                                      queue: DispatchQueue.main)
            
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,   // UPC-A appears as EAN13 with leading 0
                .upce,
                .qr
            ] // metadataOutput.metadataObjectTypes
            
        } else {
            return
        } // if captureSession.canAddOutput
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        previewLayer.videoGravity = .resizeAspectFill
        
        self.previewLayer = previewLayer
        
        view.layer.insertSublayer(previewLayer, at: 0)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        } // DispatchQueue.global
        
    } // func setupCaptureSession
    
    // MARK: - Zoom support
    
    private func setupPinchGesture() {
        
        let pinchGesture = UIPinchGestureRecognizer(target: self,
                                                    action: #selector(handlePinch(_:)))
        
        view.addGestureRecognizer(pinchGesture)
        
    } // func setupPinchGesture
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        
        guard let device = videoDevice else {
            return
        } // guard let device
        
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            
            return min(
                max(factor, 1.0),
                min(device.activeFormat.videoMaxZoomFactor, 8.0)
            )
            
        } // func minMaxZoom
        
        let newScaleFactor = minMaxZoom(gesture.scale * lastZoomFactor)
        
        switch gesture.state {
            
        case .began,
             .changed:
            
            do {
                
                try device.lockForConfiguration()
                
                device.videoZoomFactor = newScaleFactor
                
                device.unlockForConfiguration()
                
            } catch {
                return
            } // do
            
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            
        default:
            break
            
        } // switch gesture.state
        
    } // func handlePinch
    
    // MARK: - Cancel button
    
    private func setupCancelButton() {
        
        let button = UIButton(type: .system)
        
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 8
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self,
                         action: #selector(cancelTapped),
                         for: .touchUpInside)
        
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            ),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 120),
            button.heightAnchor.constraint(equalToConstant: 44)
        ]) // NSLayoutConstraint.activate
        
    } // func setupCancelButton
    
    @objc private func cancelTapped() {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        } // DispatchQueue.global
        
        delegate?.scannerViewControllerDidCancel(self)
        
    } // func cancelTapped
    
    // MARK: - Scan box overlay

    private func setupScanBox() {
        
        scanBoxView.layer.borderColor = UIColor.systemGreen.cgColor
        scanBoxView.layer.borderWidth = 3
        scanBoxView.backgroundColor = UIColor.clear
        
        view.addSubview(scanBoxView)
        
        scanLineView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        
        scanBoxView.addSubview(scanLineView)
        
    } // func setupScanBox

    private func updateScanBoxFrame() {
        
        let width = view.bounds.width * 0.7
        let height = width
        
        let originX = (view.bounds.width - width) / 2
        let originY = (view.bounds.height - height) / 2
        
        scanBoxView.frame = CGRect(x: originX,
                                   y: originY,
                                   width: width,
                                   height: height)
        
        scanLineView.frame = CGRect(x: 0,
                                    y: (height / 2) - 1,
                                    width: width,
                                    height: 2)
        
    } // func updateScanBoxFrame

    private func updateRectOfInterest() {
        
        guard let previewLayer = previewLayer,
              let metadataOutput = captureSession.outputs.first
                as? AVCaptureMetadataOutput else {
            return
        } // guard let
        
        let rect = previewLayer.metadataOutputRectConverted(
            fromLayerRect: scanBoxView.frame
        )
        
        metadataOutput.rectOfInterest = rect
        
    } // func updateRectOfInterest
    
} // class ScannerViewController

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        guard let object = metadataObjects.first
                as? AVMetadataMachineReadableCodeObject,
              var code = object.stringValue else {
            return
        } // guard let object
        
        // Convert UPC-A properly
        if object.type == .ean13,
           code.count == 13,
           code.first == "0" {
            code.removeFirst()
        } // if object.type
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        } // DispatchQueue.global
        
        delegate?.scannerViewController(self,
                                        didScanCode: code)
        
    } // func metadataOutput
    
} // extension ScannerViewController
