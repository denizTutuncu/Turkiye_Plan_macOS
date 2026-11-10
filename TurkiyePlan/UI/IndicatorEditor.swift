import SwiftUI
struct IndicatorEditor: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 let districtID: String
 @State private var indicatorID = ""
 @State private var valueText = ""
 @State private var source = ""
 @State private var year = 0
 @State private var provinceLevel = false
 private var geographyID: String { provinceLevel ? (vm.geography?.districts.first { $0.id == districtID }?.provinceID ?? districtID) : districtID }
 var body: some View {
  ScrollView {
   VStack(alignment: .leading, spacing: 16) {
    Text(L10n.text("Bölgesel veri envanteri")).font(.title2.bold())
    Text(L10n.text("Bu göstergeler kanıt envanteridir. Kaynaklı nüfus, yeni hizmet taslağında otomatik kullanılır. Diğer göstergeler hizmet ihtiyacı veya maliyetine otomatik dönüştürülmez. Aynı nüfus ve gelir kaydını farklı hizmetlerde toplayarak mükerrer saymayın.")).font(.caption).foregroundStyle(.secondary)
    Toggle(L10n.text("İl düzeyinde kaydet (kapalıysa ilçe)"), isOn: $provinceLevel)
    Picker(L10n.text("Gösterge"), selection: $indicatorID) { ForEach(vm.indicators) { Text($0.localizedName + " • " + $0.localizedUnit).tag($0.id) } }
    TextField(L10n.text("Değer • boş = bilinmiyor • ondalık ayıracı nokta"), text: $valueText)
    TextField(L10n.text("Referans yılı"), value: $year, format: .number.locale(L10n.locale).grouping(.never))
    TextField(L10n.text("Kaynak, tanım ve fiyat yılı / yöntem"), text: $source)
    Text(L10n.text("evidence.editOriginal")).font(.caption).foregroundStyle(.secondary)
    Button(L10n.text("Göstergeyi kaydet")) {
     if !valueText.isEmpty && Double(valueText) == nil { vm.error = "Geçerli bir sayı girin veya bilinmiyor için boş bırakın."; return }
     vm.saveObservation(IndicatorObservation(geographyID: geographyID, indicatorID: indicatorID, referenceYear: year, value: Double(valueText), source: source))
    }.buttonStyle(.borderedProminent)
    Divider()
    ForEach((vm.scenario?.observations ?? []).filter { $0.geographyID == geographyID }.sorted { $0.id < $1.id }) { row in
     VStack(alignment: .leading) {
      Text((vm.indicators.first { $0.id == row.indicatorID }?.localizedName ?? row.indicatorID) + " • " + String(row.referenceYear)).bold()
      Text(row.value.map(number) ?? L10n.text("Bilinmiyor"))
      EvidenceText(original: row.source).font(.caption)
      Button(L10n.text("Düzenle")) { indicatorID = row.indicatorID; valueText = row.value.map { String($0) } ?? ""; source = row.source; year = row.referenceYear }
     }.padding(.vertical, 6)
    }
   }.textFieldStyle(.roundedBorder).padding()
  }.onAppear { indicatorID = vm.indicators.first?.id ?? ""; year = vm.scenario?.priceYear ?? 0 }
 }
}
