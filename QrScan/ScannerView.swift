import SwiftUI
import AVFoundation
import Vision
import Photos

struct ScannerView: UIViewControllerRepresentable {
    var completion: (String?) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.completion = completion
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var session: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var torchButton: UIButton?
    var completion: ((String?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            complete(nil)
            return
        }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            complete(nil)
            return
        }
        if session.canAddInput(videoInput) { session.addInput(videoInput) }
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) { session.addOutput(metadataOutput) }
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        session.startRunning()
        // 添加取消按钮
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        cancelButton.layer.cornerRadius = 6
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            cancelButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        // 添加相册按钮（右下角）
        let albumButton = UIButton(type: .system)
        albumButton.setTitle("相册", for: .normal)
        albumButton.setTitleColor(.white, for: .normal)
        albumButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        albumButton.layer.cornerRadius = 6
        albumButton.translatesAutoresizingMaskIntoConstraints = false
        albumButton.addTarget(self, action: #selector(openPhotoLibrary), for: .touchUpInside)
        view.addSubview(albumButton)
        NSLayoutConstraint.activate([
            albumButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            albumButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            albumButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            albumButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        // 添加手电按钮（左下角）
        let tButton = UIButton(type: .system)
        tButton.setTitle("手电", for: .normal)
        tButton.setTitleColor(.white, for: .normal)
        tButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        tButton.layer.cornerRadius = 6
        tButton.translatesAutoresizingMaskIntoConstraints = false
        tButton.addTarget(self, action: #selector(toggleFlashlight), for: .touchUpInside)
        view.addSubview(tButton)
        NSLayoutConstraint.activate([
            tButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            tButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            tButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        self.torchButton = tButton
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        session.stopRunning()
        if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject, object.type == .qr, let string = object.stringValue {
            complete(string)
        } else {
            complete(nil)
        }
    }
    
    @objc func cancelTapped() {
        complete(nil)
    }
    
    func complete(_ value: String?) {
        completion?(value)
        dismiss(animated: true)
    }

    // MARK: - 相册选择与识别
    @objc func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        // 暂停相机会话，释放摄像头占用
        if session.isRunning { session.stopRunning() }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            if !(self.session.isRunning) { self.session.startRunning() }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            if !(self.session.isRunning) { self.session.startRunning() }
            return
        }
        detectQRCode(in: image)
    }

    func detectQRCode(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            if !(self.session.isRunning) { self.session.startRunning() }
            complete(nil)
            return
        }
        let request = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation], let payload = results.first?.payloadStringValue {
                DispatchQueue.main.async {
                    self.complete(payload)
                }
                return
            }
            DispatchQueue.main.async {
                // 未识别到二维码：恢复相机并提示用户
                if !(self.session.isRunning) { self.session.startRunning() }
                let alert = UIAlertController(title: "未识别到二维码", message: "请选择其他图片或使用相机扫描。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
        // 限定识别类型为 QRCode 可以提高效率
        request.symbologies = [.QR]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    if !(self.session.isRunning) { self.session.startRunning() }
                    self.complete(nil)
                }
            }
        }
    }

    // MARK: - 手电筒
    @objc func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                DispatchQueue.main.async { self.torchButton?.setTitle("手电", for: .normal) }
            } else {
                try device.setTorchModeOn(level: 1.0)
                DispatchQueue.main.async { self.torchButton?.setTitle("手电•", for: .normal) }
            }
            device.unlockForConfiguration()
        } catch {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "手电操作失败", message: "无法切换手电筒。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}
