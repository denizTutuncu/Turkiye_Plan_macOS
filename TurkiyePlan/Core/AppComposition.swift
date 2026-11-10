import Foundation
import AppKit
import SwiftUI
// Only the application composition root chooses concrete storage/data sources.
@main @MainActor struct TurkiyePlanApp: App {
 @NSApplicationDelegateAdaptor(PlanAppDelegate.self) var delegate
 var body: some Scene { Settings { Text("Türkiye Kamu Planı • yerel SwiftData deposu").padding() } }
}
@MainActor final class PlanAppDelegate: NSObject, NSApplicationDelegate {
 private var window: NSWindow?
 func applicationDidFinishLaunching(_ notification: Notification) {
  do {
   let config = try JSONDecoder().decode(AppConfiguration.self, from: Data(contentsOf: resource("app-config")))
   let services = try JSONDecoder().decode([Service].self, from: Data(contentsOf: resource("services")))
   let indicators = try JSONDecoder().decode([IndicatorDefinition].self, from: Data(contentsOf: resource("indicators")))
   let template = try JSONDecoder().decode(NeedRecord.self, from: Data(contentsOf: resource("record-template")))
   let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
   guard let bundleID = Bundle.main.bundleIdentifier else {
    // swift run lacks an app bundle identifier; the package route gets its own stable directory.
    #if SWIFT_PACKAGE
    try launch(config: config, services: services, indicators: indicators, template: template, storeURL: support.appendingPathComponent("TurkiyePlan-Package", isDirectory: true).appendingPathComponent("Planning.store"))
    return
    #else
    throw PlanningError.invalid("Uygulama paket kimliği bulunamadı.")
    #endif
   }
   let storeURL = support.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent("Planning.store")
   try launch(config: config, services: services, indicators: indicators, template: template, storeURL: storeURL)
  } catch {
   let alert = NSAlert(); alert.messageText = "Başlatılamadı"; alert.informativeText = "Yerel depo otomatik olarak silinmedi. " + error.localizedDescription; alert.runModal(); NSApplication.shared.terminate(nil)
  }
 }
 private func launch(config: AppConfiguration, services: [Service], indicators: [IndicatorDefinition], template: NeedRecord, storeURL: URL) throws {
  #if DEBUG
  let isUITesting = CommandLine.arguments.contains("--ui-testing") || ProcessInfo.processInfo.environment["TURKIYEPLAN_IN_MEMORY_TESTS"] == "1"
  #else
  let isUITesting = false
  #endif
  let persistence: SwiftDataPlanningPersistence
  if isUITesting { persistence = try SwiftDataPlanningPersistence.makeInMemory() }
  else { persistence = try SwiftDataPlanningPersistence.make(at: storeURL) }
  let validator = PlanningValidation(services: services, indicators: indicators, calculator: AllocationEngine())
  let remote: (any GeographyRepository)?
  if !isUITesting, let endpoint = try config.endpoint(for: config.geographyAPIURL) { remote = APIGeographyRepository(endpoint: endpoint, timeoutSeconds: config.requestTimeoutSeconds) }
  else { remote = nil }
  let remoteScenario: (any ScenarioRepository)?
  if !isUITesting, let endpoint = try config.endpoint(for: config.scenarioAPIURL) { remoteScenario = APIScenarioRepository(endpoint: endpoint, timeoutSeconds: config.requestTimeoutSeconds) }
  else { remoteScenario = nil }
  let loader = LocalFirstWorkspaceLoader(persistence: persistence, remote: remote, remoteScenario: remoteScenario,
   bundledGeography: LocalGeographyRepository(url: try resource("geography")),
   bundledScenario: LocalScenarioRepository(url: try resource("empty-scenario")), validator: validator)
  let controller = ConcretePlanningController(loader: loader, persistence: persistence, validator: validator, fileStore: JSONScenarioStore(), geographyFileStore: JSONGeographyFileStore(), observationSeed: LocalScenarioRepository(url: try resource("empty-scenario")))
  let financePresets = try JSONDecoder().decode([FinancePreset].self, from: Data(contentsOf: resource("finance-presets-2025")))
  let vm = PlanningViewModel(controller: controller, services: services, indicators: indicators, recordTemplate: template, financePresets: financePresets)
  let root = ConcreteTabViewController(viewModel: vm, router: ConcreteTabRouter())
  let window = NSWindow(contentViewController: root); window.title = "Türkiye Kamu Planı"; window.setContentSize(NSSize(width: 1280, height: 840)); window.center(); window.makeKeyAndOrderFront(nil); self.window = window
  NSApplication.shared.setActivationPolicy(.regular); NSApplication.shared.activate(ignoringOtherApps: true)
  Task { await vm.load() }
 }
 private func resource(_ name: String) throws -> URL {
  // Xcode can copy a folder as a folder reference or flatten its resource group.
  if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Resources") { return url }
  if let url = Bundle.main.url(forResource: name, withExtension: "json") { return url }
  #if SWIFT_PACKAGE
  if let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Resources") { return url }
  #endif
  throw PlanningError.invalid("Kaynak bulunamadı: " + name + ".json. Hedef üyeliğini ve Copy Bundle Resources ayarını kontrol edin.")
 }
 func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
