//
//  QrScanTests.swift
//  QrScanTests
//
//  Created by Junjie Qin on 2025/11/26.
//

import Testing
@testable import QrScan

struct QrScanTests {
    @Test func resolveCNAsChinese() async throws {
        #expect(AppLanguage.resolve(regionCode: "CN") == .zhHans)
    }

    @Test func resolveLowercaseCNAsChinese() async throws {
        #expect(AppLanguage.resolve(regionCode: "cn") == .zhHans)
    }

    @Test func resolveUSAsEnglish() async throws {
        #expect(AppLanguage.resolve(regionCode: "US") == .en)
    }

    @Test func resolveNilAsEnglish() async throws {
        #expect(AppLanguage.resolve(regionCode: nil) == .en)
    }
}
