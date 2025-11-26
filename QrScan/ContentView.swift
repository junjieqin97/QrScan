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
    private let photoSaveHelper = PhotoSaveHelper()
    @State private var showSaveError = false  // 保持 showSaveError 提示
    @Binding var showScanner: Bool
    @State private var scannedText: String = ""
    @AppStorage("devtools_scan_history") private var scanHistoryRaw: String = "[]" // JSON 字符串存储
    @State private var generatedQRCode: UIImage? = nil
    @State private var showCopySuccess = false
    @State private var showSaveSuccess = false  // 新增保存成功提示
    // --- 新增: 纠错级别相关 ---
    @State private var qrCorrectionLevel: String = "M"  // 默认中等纠错
    let qrCorrectionLevels = [
        (label: "低", value: "L"),
        (label: "中", value: "M"),
        (label: "高", value: "H"),
        (label: "超高", value: "Q")
    ]

    init(showScanner: Binding<Bool> = .constant(false)) {
        self._showScanner = showScanner
    }

    // 反转后的历史数组（便于按时间倒序显示）
    var reversedHistory: [String] { Array(scanHistory.reversed()) }

    // 当前显示“复制”按钮的历史项索引（基于 reversedHistory 的索引）
    @State private var visibleCopyIndex: Int? = nil

    // 工具方法: 数组转JSON反序列化
    var scanHistory: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(scanHistoryRaw.utf8))) ?? []
    }
    
    // 辅助方法: 添加历史记录
    private func appendToHistory(_ text: String) {
        // 确保在主线程更新 AppStorage，以触发视图刷新
        DispatchQueue.main.async {
            var history = scanHistory
            history.append(text)
            // 可选：限制历史记录长度，防止无限增长（例如只保留最近 200 条）
            if history.count > 200 {
                history = Array(history.suffix(200))
            }
            if let data = try? JSONEncoder().encode(history) {
                scanHistoryRaw = String(data: data, encoding: .utf8) ?? "[]"
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 可编辑的文本输入/扫码区
                    TextEditor(text: $scannedText)
                        .frame(height: 80)
                        .padding(6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                        .background(Color(.systemBackground))
                        .onChange(of: scannedText) { newValue in
                            generatedQRCode = generateQRCode(
                                from: newValue, correctionLevel: qrCorrectionLevel)
                        }
                        // 联动：纠错级别变化实时重新生成二维码
                        .onChange(of: qrCorrectionLevel) { newLevel in
                            generatedQRCode = generateQRCode(
                                from: scannedText, correctionLevel: newLevel)
                        }
                        .onAppear {
                            if let clipboardString = UIPasteboard.general.string, clipboardString.count <= 100 {
                                scannedText = clipboardString
                            }
                        }

                    // 新增：二维码纠错级别选项
                    VStack(alignment: .leading, spacing: 4) {
                        Text("纠错级别：")
                            .font(.subheadline)
                        Picker("纠错级别", selection: $qrCorrectionLevel) {
                            ForEach(qrCorrectionLevels, id: \.value) { item in
                                Text(item.label).tag(item.value)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.trailing, 16)
                    }
                    // 二维码展示区：根据TextEditor内容实时生成
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
                                .overlay(Text("二维码预览").foregroundColor(.secondary))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                    // 按钮区
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
                            Label("保存", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .disabled(generatedQRCode == nil)

                        Button(action: {
                            showScanner = true
                        }) {
                            Label("扫描", systemImage: "qrcode.viewfinder")
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
                            Label("复制", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .disabled(scannedText.isEmpty)
                    }

                    if showCopySuccess {
                        Text("复制成功!")
                            .foregroundColor(.green)
                            .transition(.opacity)
                            .padding(.top, 8)
                    }
                    if showSaveSuccess {
                        Text("保存成功!")
                            .foregroundColor(.green)
                            .transition(.opacity)
                            .padding(.top, 8)
                    }
                    if showSaveError {
                        Text("保存失败，请检查权限设置或重试")
                            .foregroundColor(.red)
                            .transition(.opacity)
                            .padding(.top, 8)
                    }

                    Divider()

                    // 历史记录区（含右侧“清空”按钮）
                    HStack {
                        Text("历史记录")
                            .font(.headline)
                        Spacer()
                        Button(role: .destructive) {
                            // 清空历史记录
                            DispatchQueue.main.async {
                                scanHistoryRaw = "[]"
                                visibleCopyIndex = nil
                            }
                        } label: {
                            Label("清空", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                    // 因为外层已经是 ScrollView，嵌套使用 List 可能导致渲染/滚动问题，改用 ForEach
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(reversedHistory.indices, id: \.self) { idx in
                            let item = reversedHistory[idx]
                            HStack(spacing: 12) {
                                Text(item)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if visibleCopyIndex == idx {
                                    Button("复制") {
                                        UIPasteboard.general.string = item
                                        // 给出全局复制成功提示（与顶部复制按钮复用）
                                        showCopySuccess = true
                                        // 隐藏复制提示
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showCopySuccess = false
                                        }
                                        // 隐藏该行的复制按钮
                                        visibleCopyIndex = nil
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(6)
                            .onTapGesture {
                                withAnimation {
                                    if visibleCopyIndex == idx {
                                        visibleCopyIndex = nil
                                    } else {
                                        visibleCopyIndex = idx
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .safeAreaInset(edge: .top) {
                    Spacer().frame(height: 8)
                }
            }
            .sheet(isPresented: $showScanner) {
                // 扫码弹窗，扫码后覆盖文本框并加入历史
                ScannerView { result in
                    showScanner = false
                    if let text = result, !text.isEmpty {
                        DispatchQueue.main.async {
                            scannedText = text
                            appendToHistory(text)
                        }
                    }
                }
            }
            .onChange(of: showScanner) { newValue in
                if newValue {
                    // 确保扫描器立即显示
                    // 这里不需要额外操作，因为 .sheet 会自动处理
                }
            }
        }
    }
}

// MARK: - 文本转二维码工具方法
extension ContentView {
    func generateQRCode(from string: String, correctionLevel: String = "M") -> UIImage? {
        guard !string.isEmpty else { return nil }
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        // 新增纠错级别
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
        ContentView(showScanner: .constant(false))
    }
}
