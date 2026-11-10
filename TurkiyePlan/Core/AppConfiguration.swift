import Foundation
nonisolated struct AppConfiguration: Decodable, Sendable {
 let geographyAPIURL: String?
 let scenarioAPIURL: String?
 let requestTimeoutSeconds: Double
 func endpoint(for raw: String?) throws -> URL? {
  guard requestTimeoutSeconds.isFinite, (1...120).contains(requestTimeoutSeconds) else { throw PlanningError.invalid("API zaman aşımı ayarı geçersiz.") }
  guard let raw, !raw.isEmpty else { return nil }
  guard let url = URL(string: raw), url.scheme == "https", url.host != nil else { throw PlanningError.invalid("API adresi geçerli bir HTTPS adresi olmalı.") }
  return url
 }
}
