import Foundation
import Dispatch
/// Coalesces framework selection callbacks onto the next main-queue turn.
/// Data edits and persistence are deliberately not routed through this helper.
@MainActor final class DeferredUIUpdates {
 private var revisions: [String: UInt64] = [:]
 func enqueue(key: String, action: @escaping @MainActor () -> Void) {
  let revision = (revisions[key] ?? 0) &+ 1
  revisions[key] = revision
  DispatchQueue.main.async { [weak self] in
   guard self?.revisions[key] == revision else { return }
   action()
  }
 }
}
