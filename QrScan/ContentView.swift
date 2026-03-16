import CoreImage.CIFilterBuiltins
import SwiftUI

import UIKit
import Foundation

class PhotoSaveHelper: NSObject {
    var completion: ((Error?) -> Void)?

    func saveImage(_ image: UIImage, completion: @escaping (Error?) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(
            image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(
        _ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?
    ) {
        completion?(error)
        completion = nil  // 防止循环引用
    }
}

struct ContentView: View {
    let appLanguage: AppLanguage
    private let photoSaveHelper = PhotoSaveHelper()
    @State private var showSaveError = false
    @Binding var showScanner: Bool
    @State private var scannedText: String = ""
    @State private var generatedQRCode: UIImage? = nil
    @State private var showCopySuccess = false
    @State private var showSaveSuccess = false
    @State private var qrCorrectionLevel: String = "M"
    @State private var visibleCopyIndex: Int? = nil

    private let qrCorrectionLevels = [
        (labelKey: "home.correction.low", value: "L"),
        (labelKey: "home.correction.medium", value: "M"),
        (labelKey: "home.correction.high", value: "H"),
        (labelKey: "home.correction.max", value: "Q")
    ]

    init(showScanner: Binding<Bool> = .constant(false), appLanguage: AppLanguage = .en) {
        self._showScanner = showScanner
        self.appLanguage = appLanguage
    }

    private func t(_ key: String) -> String {
        L10n.tr(key, language: appLanguage)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TextEditor(text: $scannedText)
                        .frame(height: 80)
                        .padding(6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                        .background(Color(.systemBackground))
                        .onChange(of: scannedText) { _, newValue in
                            generatedQRCode = generateQRCode(
                                from: newValue, correctionLevel: qrCorrectionLevel)
                        }
                        .onChange(of: qrCorrectionLevel) { _, newLevel in
                            generatedQRCode = generateQRCode(
                                from: scannedText, correctionLevel: newLevel)
                        }
                        .onAppear {
                            if let clipboardString = UIPasteboard.general.string, clipboardString.count <= 100 {
                                scannedText = clipboardString
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(t("home.correction.title"))
                            .font(.subheadline)
                        Picker(t("home.correction.title"), selection: $qrCorrectionLevel) {
                            ForEach(qrCorrectionLevels, id: \.value) { item in
                                Text(t(item.labelKey)).tag(item.value)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.trailing, 16)
                    }
                    VStack(alignment: .center, spacing: 8) {
                        if let qrImg = generatedQRCode {
                            Image(uiImage: qrImg)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Rectangle()
                                .frame(width: 160, height: 160)
                                .foregroundColor(Color.secondary.opacity(0.08))
                                .overlay(Text(t("home.qr.preview")).foregroundColor(.secondary))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                    HStack(spacing: 16) {
                        Button(action: {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
                                for: nil)
                            if let qrImage = generatedQRCode {
                                photoSaveHelper.saveImage(qrImage) { error in
                                    if error != nil {
                                        showSaveError = true
                                    } else {
                                        showSaveSuccess = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showSaveSuccess = false
                                        showSaveError = false
                                    }
                                }
                            }
                        }) {
                            Label(t("action.save"), systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .disabled(generatedQRCode == nil)

                        Button(action: {
                            showScanner = true
                        }) {
                            Label(t("action.scan"), systemImage: "qrcode.viewfinder")
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: {
                            UIPasteboard.general.string = scannedText
                            showCopySuccess = true
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
                                for: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopySuccess = false
                            }
                        }) {
                            Label(t("action.copy"), systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .disabled(scannedText.isEmpty)
                    }

                    if showCopySuccess {
                        Text(t("home.copy.success"))
                            .foregroundColor(.green)
                            .transition(.opacity)
                            .padding(.top, 8)
                    }
                    if showSaveSuccess {
                        Text(t("home.save.success"))
                            .foregroundColor(.green)
                            .transition(.opacity)
                            .padding(.top, 8)
                    }
                    if showSaveError {
                        Text(t("home.save.failed"))
                            .foregroundColor(.red)
                            .transition(.opacity)
                            .padding(.top, 8)
                    }

                    Divider()

                    ScanHistorySection(
                        title: t("home.history.title"),
                        clearButtonTitle: t("action.clear"),
                        copyButtonTitle: t("action.copy"),
                        visibleCopyIndex: $visibleCopyIndex,
                        onCopy: { item in
                            UIPasteboard.general.string = item
                            showCopySuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCopySuccess = false
                            }
                            visibleCopyIndex = nil
                        }
                    )
                }
                .padding()
                .safeAreaInset(edge: .top) {
                    Spacer().frame(height: 8)
                }
            }
            .sheet(isPresented: $showScanner) {
                ScannerView(language: appLanguage) { result in
                    showScanner = false
                    if let text = result, !text.isEmpty {
                        DispatchQueue.main.async {
                            scannedText = text
                            ScanHistoryStorage.append(text)
                        }
                    }
                }
            }
        }
    }
}

extension ContentView {
    func generateQRCode(from string: String, correctionLevel: String = "M") -> UIImage? {
        guard !string.isEmpty else { return nil }
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        if let outputImage = filter.outputImage?.transformed(by: transform) {
            let context = CIContext()
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(showScanner: .constant(false), appLanguage: .en)
    }
}
