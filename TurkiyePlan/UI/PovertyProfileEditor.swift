import SwiftUI
struct PovertyProfileEditor: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 let geographyID: String
 @State private var rate = ""
 @State private var status = "estimated"
 @State private var year = 0
 @State private var definition = "relative_income_poverty_national_median_50pct"
 @State private var source = ""
 @State private var method = ""
 var body: some View {
  VStack(alignment: .leading, spacing: 8) {
   TextField(L10n.text("Oran (0–1); bilinmiyor için boş"), text: $rate)
   Picker(L10n.text("Durum"), selection: $status) { Text(L10n.text("Kaynağa dayalı gözlem")).tag("observed"); Text(L10n.text("Tahmin / senaryo")).tag("estimated"); Text(L10n.text("Veri yok")).tag("missing") }
   TextField(L10n.text("Referans yılı"), value: $year, format: .number.locale(L10n.locale).grouping(.never))
   TextField(L10n.text("Karşılaştırılabilir tanım kimliği"), text: $definition)
   TextField(L10n.text("Kaynak URL"), text: $source)
   TextField(L10n.text("Ölçüm / tahmin yöntemi ve sınırları"), text: $method)
   Text(L10n.text("evidence.editOriginal")).font(.caption).foregroundStyle(.secondary)
   Text(L10n.text("Gözlem olarak işaretlemek, uygulamanın kaynağı bağımsız doğruladığı anlamına gelmez. Harcama veya SEGE skoru doğrudan bir yoksulluk yüzdesi değildir.")).font(.caption).foregroundStyle(.secondary)
   Button(L10n.text("İlçe yoksulluk profilini kaydet ve hesapla")) {
    if !rate.isEmpty && Double(rate) == nil { vm.error = "Oranı 0–1 arasında noktalı ondalık olarak girin."; return }
    vm.updatePovertyProfile(PovertyProfile(geographyID: geographyID, rate: status == "missing" ? nil : Double(rate), status: status, referenceYear: year, definitionID: definition, sourceURL: source, method: method))
   }
  }.textFieldStyle(.roundedBorder).padding().onAppear {
   if let p = vm.povertyProfile(for: geographyID) { rate = p.rate.map { String($0) } ?? ""; status = p.status; year = p.referenceYear; definition = p.definitionID; source = p.sourceURL; method = p.method }
  }
 }
}
