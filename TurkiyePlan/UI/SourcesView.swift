import SwiftUI
import AppKit
import UniformTypeIdentifiers
struct SourcesView: View {
 @ObservedObject var vm: PlanningViewModel
 var body: some View {
  ScrollView {
   VStack(alignment: .leading, spacing: 20) {
    Text("Veri sizin kontrolünüzde.").font(.largeTitle.bold())
    Text("Yüklü senaryonun nüfus gözlemleri ve hizmet girdileri ayrı tutulur. DEMO senaryosundaki ihtiyaç, kapsam ve maliyet varsayımları resmî ilçe ölçümleri değildir.")
    PopulationImportButton(vm: vm)
    Button("Yoksulluk profili JSON içe aktar") {
     let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]
     if panel.runModal() == .OK, let url = panel.url { vm.importPovertyDataset(url) }
    }
    GroupBox("Yerel SwiftData deposu") {
     VStack(alignment: .leading, spacing: 8) {
      Text(vm.loadDescription).bold()
      Text(vm.storageLocation.path).font(.caption).textSelection(.enabled)
      if let date = vm.lastSavedAt { Text("Son başarılı kayıt: " + date.formatted()).font(.caption) }
      Text("İçe aktarılan senaryo ve Kaydet / Uygula işlemleri yerel veritabanına kaydedilir. Formda henüz uygulanmamış değişiklikler kalıcı değildir.")
      ForEach(vm.loadNotices, id: \.self) { Text($0).foregroundStyle(.orange).font(.caption) }
     }.frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    GroupBox("JSON aktarımı ve yedek") {
     HStack {
      Button("Senaryo JSON içe aktar", systemImage: "square.and.arrow.down") { importFile(geography: false) }
      Button("Coğrafya JSON içe aktar", systemImage: "map") { importFile(geography: true) }
      Button("Senaryo JSON dışa aktar", systemImage: "square.and.arrow.up") { saveFile(result: false) }
      Button("Sonuç JSON dışa aktar", systemImage: "tablecells") { saveFile(result: true) }
     }.padding()
    }
    if let source = vm.geography?.source {
     GroupBox("Coğrafya kaynağı") {
      VStack(alignment: .leading, spacing: 8) {
       Text(source.title).bold(); Text("Kaynak tarihi: " + source.snapshot); Text(source.verification)
       Text("Revizyon: " + source.revision).font(.caption).textSelection(.enabled)
       if let url = URL(string: source.url) { Link("Kaynak ve lisans", destination: url) }
       Text("Kaynak kimlikleri resmî TÜİK/UAVT kodları değildir. İsimlerde yalnızca birleşik noktalı i normalizasyonu uygulandı. Resmî veri entegrasyonunda kimlik eşleme tablosu gerekir.").font(.caption).foregroundStyle(.secondary)
      }.frame(maxWidth: .infinity, alignment: .leading).padding()
     }
    }
    GroupBox("Beklenen gözlem verileri") {
     Text("Her kayıt bir ilçe ve hizmete aittir. Nüfus, ihtiyaç duyan, hizmet alan, hedef kapsam, yatırım/işletme maliyeti, süre, yoksulluk oranı, hizmet maliyeti ve mali kapasite endeksi, kaynak ve yıl gerekir. Fiyatlar ortak yılın sabit TRY değerleri olmalıdır. Demografik ve gelir ayrıntıları doğrulanmış kaynaklardan hazırlanmalıdır.").frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    Text("Yüklü ilçe–hizmet kaydı: " + String(vm.scenario?.records.count ?? 0) + ". Paket senaryosunu içe aktarırken source ve isDemo açıklamalarını inceleyin.").foregroundStyle(.orange)
    Text("Yerel kayıt ve JSON dışa aktarımı ayrıdır. İçe aktardığınız kaynak dosya değiştirilmez. JSON dışa aktarımı taşınabilir yedek oluşturur.").font(.caption)
   }.padding(28)
  }
 }
 private func importFile(geography: Bool) { let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false; if panel.runModal() == .OK, let url = panel.url { if geography { vm.importGeography(url) } else { vm.importScenario(url) } } }
 private func saveFile(result: Bool) { let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = result ? "allocation-result.json" : "scenario.json"; if panel.runModal() == .OK, let url = panel.url { if result { vm.exportResult(url) } else { vm.saveScenario(url) } } }
}
