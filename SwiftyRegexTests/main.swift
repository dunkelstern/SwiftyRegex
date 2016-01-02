//
//  SwiftyRegex_Tests.swift
//  SwiftyRegex Tests
//
//  Created by Johannes Schriewer on 08/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import XCTest
@testable import SwiftyRegex

class TestSwiftyRegex: XCTestCase {

    var allTests : [(String, () -> Void)] {
        return [
            ("testCompileFailed", testCompileFailed),
            ("testEmptyPattern", testEmptyPattern),
            ("testEmptyString", testEmptyString),
            ("testNumberedMatch", testNumberedMatch),
            ("testNumberedNoMatch", testNumberedNoMatch),
            ("testNamedMatch", testNamedMatch),
            ("testNamedNoMatch", testNamedNoMatch),
            ("testMixedMatch", testMixedMatch)
        ]
    }

    func testCompileFailed() {
        do {
            let _ = try RegEx(pattern: "([0")
            XCTFail("Pattern should not compile")
        } catch RegEx.Error.InvalidPattern(let offset, let message) {
            print("Pattern invalid @ \(offset): \(message)")
        } catch {

        }
    }

    func testEmptyPattern() {
        do {
            let re = try RegEx(pattern: "")
            let matches = re.match("1234 : Hallo Welt")

            let numbered = matches.numberedParams
            let named = matches.namedParams

            XCTAssert(numbered.count == 1, "Expected count of 1, got \(numbered.count)")
            if numbered.count == 1 {
                XCTAssert(numbered[0] == "")
            }
            XCTAssert(named.count == 0, "Expected count of 0, got \(named.count)")
        } catch {
            XCTFail("Could not compile regex pattern")
        }
    }

    func testEmptyString() {
        do {
            let re = try RegEx(pattern: "([0-9]+)[\\s]*:[\\s]*(.*)")
            let matches = re.match("")

            let numbered = matches.numberedParams
            let named = matches.namedParams

            XCTAssert(numbered.count == 0, "Expected count of 0, got \(numbered.count)")
            XCTAssert(named.count == 0, "Expected count of 0, got \(named.count)")
        } catch {
            XCTFail("Could not compile regex pattern")
        }
    }

    func testNumberedMatch() {
        do {
            let re = try RegEx(pattern: "([0-9]+)[\\s]*:[\\s]*(.*)")
            let matches = re.match("1234 : Hallo Welt")

            let numbered = matches.numberedParams
            let named = matches.namedParams

            XCTAssert(numbered.count == 3, "Expected count of 3, got \(numbered.count)")
            if numbered.count == 3 {
                XCTAssert(numbered[1] == "1234")
                XCTAssert(numbered[2] == "Hallo Welt")
            }

            XCTAssert(named.count == 0, "Expected count of 0, got \(named.count)")
        } catch {
            XCTFail("Could not compile regex pattern")
        }
    }

    func testNumberedNoMatch() {
        do {
            let re = try RegEx(pattern: "([0-9]+)[\\s]*:[\\s]*(.*)")
            let matches = re.match("Hallo Welt Blafasel 1234")

            let numbered = matches.numberedParams
            let named = matches.namedParams

            XCTAssert(numbered.count == 0, "Expected count of 0, got \(numbered.count)")
            XCTAssert(named.count == 0, "Expected count of 0, got \(named.count)")
        } catch {
            XCTFail("Could not compile regex pattern")
        }
    }

    func testNamedMatch() {
        do {
            let re = try RegEx(pattern: "(?P<num>[0-9]+)[\\s]*:[\\s]*(?P<text>.*)")
            let matches = re.match("1234 : Hallo Welt")

            let numbered = matches.numberedParams
            let named = matches.namedParams

            XCTAssert(numbered.count == 3, "Expected count of 1, got \(numbered.count)")
            XCTAssert(named.count == 2, "Expected count of 2, got \(named.count)")
            XCTAssert(named["num"] == "1234")
            XCTAssert(named["text"] == "Hallo Welt")
        } catch {
            XCTFail("Could not compile regex pattern")
        }
    }

    func testNamedNoMatch() {
        do {
            let re = try RegEx(pattern: "(?P<num>[0-9]+)[\\s]*:[\\s]*(?P<text>.*)")
            let matches = re.match("Hallo Welt Blafasel 1234")

            let numbered = matches.numberedParams
            let named = matches.namedParams

            XCTAssert(numbered.count == 0, "Expected count of 0, got \(numbered.count)")
            XCTAssert(named.count == 0, "Expected count of 0, got \(named.count)")
        } catch {
            XCTFail("Could not compile regex pattern")
        }
    }

    func testMixedMatch() {
        do {
            let re = try RegEx(pattern: "(?P<num>[0-9]+)[\\s]*:[\\s]*(.*)")
            let matches = re.match("1234 : Hallo Welt")

            let numbered = matches.numberedParams
            let named = matches.namedParams

            XCTAssert(numbered.count == 3, "Expected count of 3, got \(numbered.count)")
            if numbered.count == 3 {
                XCTAssert(numbered[1] == "1234")
                XCTAssert(numbered[2] == "Hallo Welt")
            }

            XCTAssert(named.count == 1, "Expected count of 1, got \(named.count)")
            XCTAssert(named["num"] == "1234")
        } catch {
            XCTFail("Could not compile regex pattern")
        }
    }
}

print("Starting tests...")
XCTMain([TestSwiftyRegex()])
