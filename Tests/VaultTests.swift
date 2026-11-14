import XCTest

@testable import passui

final class VaultTests: XCTestCase {
    func testVaultItemLabel() throws {
        let item = VaultItem(
            url: URL(fileURLWithPath: "/path/to/file/full-name-ID-y-_aBc"), createdAt: nil,
            modifiedAt: nil)
        XCTAssertEqual(item.label, "Full Name ID y  aBc")
    }
}
