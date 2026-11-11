import XCTest

@testable import passui

final class ttTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods

        let out =
            """
            gpg (GnuPG) 2.5.20
            libgcrypt 1.12.2
            Copyright (C) 2026 g10 Code GmbH
            License GNU GPL-3.0-or-later <https://gnu.org/licenses/gpl.html>
            This is free software: you are free to change and redistribute it.
            There is NO WARRANTY, to the extent permitted by law.

            Home: /Users/someuser/.gnupg
            Supported algorithms:
            Pubkey: RSA, Kyber, ELG, DSA, ECDH, ECDSA, EDDSA
            Cipher: IDEA, 3DES, CAST5, BLOWFISH, AES, AES192, AES256, TWOFISH,
                    CAMELLIA128, CAMELLIA192, CAMELLIA256
            Hash: SHA1, RIPEMD160, SHA256, SHA384, SHA512, SHA224
            Compression: Uncompressed, ZIP, ZLIB, BZIP2
            """

        let version = out.split(whereSeparator: \.isNewline)[0...1].joined(separator: "/")
        XCTAssertEqual(version, "gpg (GnuPG) 2.5.20/libgcrypt 1.12.2", "Version does not match")
    }
}
