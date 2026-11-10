import SwiftUI
import AppKit
import UniformTypeIdentifiers
struct SourcesView: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 var body: some View {
  ScrollView {
   VStack(alignment: .leading, spacing: 20) {
    Text(L10n.text("Veri sizin kontrolünüzde.")).font(.largeTitle.bold())
    Text(L10n.text("Yüklü senaryonun nüfus gözlemleri ve hizmet girdileri ayrı tutulur. DEMO senaryosundaki ihtiyaç, kapsam ve maliyet varsayımları resmî ilçe ölçümleri değildir."))
    DataQualityDashboard(vm: vm)
    PopulationImportButton(vm: vm)
    Button(L10n.text("Yoksulluk profili JSON içe aktar")) {
     let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]
     if panel.runModal() == .OK, let url = panel.url { vm.importPovertyDataset(url) }
    }
    GroupBox(L10n.text("Yerel SwiftData deposu")) {
     VStack(alignment: .leading, spacing: 8) {
      Text(L10n.message(vm.loadDescription)).bold()
      Text(vm.storageLocation.path).font(.caption).textSelection(.enabled)
      if let date = vm.lastSavedAt { Text(L10n.text("Son başarılı kayıt: ") + date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(L10n.locale))).font(.caption) }
      Text(L10n.text("İçe aktarılan senaryo ve Kaydet / Uygula işlemleri yerel veritabanına kaydedilir. Formda henüz uygulanmamış değişiklikler kalıcı değildir."))
      ForEach(vm.loadNotices, id: \.self) { Text(L10n.message($0)).foregroundStyle(.orange).font(.caption) }
     }.frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    GroupBox(L10n.text("JSON aktarımı ve yedek")) {
     HStack {
      Button(L10n.text("Senaryo JSON içe aktar"), systemImage: "square.and.arrow.down") { importFile(geography: false) }
      Button(L10n.text("Coğrafya JSON içe aktar"), systemImage: "map") { importFile(geography: true) }
      Button(L10n.text("Senaryo JSON dışa aktar"), systemImage: "square.and.arrow.up") { saveFile(result: false) }
      Button(L10n.text("Sonuç JSON dışa aktar"), systemImage: "tablecells") { saveFile(result: true) }
     }.padding()
    }
    if let source = vm.geography?.source {
     GroupBox(L10n.text("Coğrafya kaynağı")) {
      VStack(alignment: .leading, spacing: 8) {
       Text(source.title).bold(); Text(L10n.text("Kaynak tarihi: ") + source.snapshot); Text(L10n.text(source.verification))
       Text(L10n.text("Revizyon: ") + source.revision).font(.caption).textSelection(.enabled)
       if let url = URL(string: source.url) { Link(L10n.text("Kaynak ve lisans"), destination: url) }
       Text(L10n.text("Kaynak kimlikleri resmî TÜİK/UAVT kodları değildir. İsimlerde yalnızca birleşik noktalı i normalizasyonu uygulandı. Resmî veri entegrasyonunda kimlik eşleme tablosu gerekir.")).font(.caption).foregroundStyle(.secondary)
      }.frame(maxWidth: .infinity, alignment: .leading).padding()
     }
    }
    GroupBox(L10n.text("Beklenen gözlem verileri")) {
     Text(L10n.text("Her kayıt bir ilçe ve hizmete aittir. Nüfus, ihtiyaç duyan, hizmet alan, hedef kapsam, yatırım/işletme maliyeti, süre, yoksulluk oranı, hizmet maliyeti ve mali kapasite endeksi, kaynak ve yıl gerekir. Fiyatlar ortak yılın sabit TRY değerleri olmalıdır. Demografik ve gelir ayrıntıları doğrulanmış kaynaklardan hazırlanmalıdır.")).frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    Text(L10n.format("sources.count", String(vm.scenario?.records.count ?? 0))).foregroundStyle(.orange)
    Text(L10n.text("Yerel kayıt ve JSON dışa aktarımı ayrıdır. İçe aktardığınız kaynak dosya değiştirilmez. JSON dışa aktarımı taşınabilir yedek oluşturur.")).font(.caption)
   }.padding(28)
  }
 }
 private func importFile(geography: Bool) { let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false; if panel.runModal() == .OK, let url = panel.url { if geography { vm.importGeography(url) } else { vm.importScenario(url) } } }
 private func saveFile(result: Bool) { let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = result ? "allocation-result.json" : "scenario.json"; if panel.runModal() == .OK, let url = panel.url { if result { vm.exportResult(url) } else { vm.saveScenario(url) } } }
}
