import Foundation
import Dispatch
import XCTest
@testable import TurkiyePlan
@MainActor private final class SelectionLog { var values: [String] = [] }
final class DeferredUIUpdatesTests: XCTestCase {
 @MainActor func testLatestSelectionWinsAndDoesNotPublishInline() async {
  let updates = DeferredUIUpdates(); let log = SelectionLog()
  updates.enqueue(key: "tab") { log.values.append("old") }
  updates.enqueue(key: "tab") { log.values.append("latest") }
  XCTAssertTrue(log.values.isEmpty)
  await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
   DispatchQueue.main.async { continuation.resume() }
  }
  XCTAssertEqual(log.values, ["latest"])
 }
 @MainActor func testIndependentSelectionChannelsAreNotDropped() async {
  let updates = DeferredUIUpdates(); let log = SelectionLog()
  updates.enqueue(key: "province") { log.values.append("province") }
  updates.enqueue(key: "district") { log.values.append("district") }
  await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
   DispatchQueue.main.async { continuation.resume() }
  }
  XCTAssertEqual(log.values, ["province", "district"])
 }
}
