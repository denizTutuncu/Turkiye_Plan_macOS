import SwiftUI
struct AllocationView: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 @State private var visibleLimit = 100
 @State private var budgetText = ""
 @State private var weight = 0.0
 var body: some View {
  let matchingRows = vm.filteredAllocationRows
  ScrollView {
   LazyVStack(alignment: .leading, spacing: 20) {
    Text(L10n.text("Her tahsisin hesabı açık.")).font(.largeTitle.bold())
    FinanceEditor(vm: vm)
    Text(L10n.format("poverty.count.note", String(vm.povertyDistrictCount))).font(.caption).foregroundStyle(.secondary)
    GroupBox(L10n.text("Senaryo parametreleri")) {
     HStack {
      VStack(alignment: .leading) {
       Text(L10n.text("Dağıtılacak plan bütçesi (kuruş)")).font(.caption)
       TextField(L10n.text("Toplam bütçe • kuruş"), text: $budgetText).textFieldStyle(.roundedBorder)
      }
      Button(L10n.text("Bütçeyi uygula")) { if let cents = Int64(budgetText) { vm.updateBudget(cents) } else { vm.error = "Bütçeyi tam sayı kuruş olarak girin." } }
      Text(L10n.text("Yoksulluk ağırlığı"))
      Slider(value: $weight, in: 0...2, step: 0.05) { Text(L10n.text("Ağırlık")) }.frame(width: 140)
      Text(number(weight)).monospacedDigit()
      Button(L10n.text("Ağırlığı uygula")) { vm.updateWeight(weight) }
     }.padding()
    }
    GroupBox(L10n.text("Formül • önerilen deneysel dağıtım, resmî politika değildir")) {
     VStack(alignment: .leading, spacing: 8) {
      Text(L10n.text("Açık = max(0, ceil(ihtiyaç duyan × hedef kapsam) − yeterli hizmet alan)"))
      Text(L10n.text("Gereksinim = açık × (birim yatırım + yıllık işletme × yıl) × maliyet endeksi"))
      Text(L10n.text("Öncelik puanı = gereksinim × (1 + yoksulluk ağırlığı × yoksulluk oranı) ÷ mali kapasite endeksi"))
      Text(L10n.text("Tahsis = kalan bütçe × puan ÷ aktif kayıtların toplam puanı"))
      Text(L10n.text("Tahsis gereksinimde sınırlanır. Fazla pay diğer kayıtlara yeniden dağıtılır; gereksinimler karşılanınca kalan bütçe tutulur. Kuruş kalanı kimlik sırasına göre dağıtılır."))
      Text(L10n.text("Birim tahmini = açık × tahsis ÷ gereksinim. Kesirli tahmin bir inşaat veya satın alma taahhüdü değildir.")).foregroundStyle(.secondary)
     }.font(.system(.body, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    RegionResultsSearch(query: $vm.allocationSearch, fieldIdentifier: "allocationRegionSearch")
    Text(L10n.format("search.count", String(min(visibleLimit, matchingRows.count)), String(matchingRows.count), String(vm.result?.rows.count ?? 0))).font(.caption).foregroundStyle(.secondary)
    if matchingRows.isEmpty && !(vm.result?.rows.isEmpty ?? true) {
     ContentUnavailableView(L10n.text("Eşleşen kayıt yok"), systemImage: "magnifyingglass", description: Text(L10n.text("İl veya ilçe adını kontrol edin ya da aramayı temizleyin.")))
    }
    ForEach(Array(matchingRows.prefix(visibleLimit))) { row in
     VStack(alignment: .leading, spacing: 8) {
      HStack { Text(vm.districtName(row)).font(.headline); Spacer(); Text(vm.services.first { $0.id == row.serviceID }?.localizedName ?? row.serviceID) }
      HStack { Text(L10n.text("Açık: ") + number(row.gap)); Spacer(); Text(L10n.text("Puan: ") + number(row.score)); Spacer(); Text(L10n.text("Gereksinim: ") + money(row.requirementCents)) }
      ProgressView(value: row.requirementCents == 0 ? 0 : Double(row.allocatedCents) / Double(row.requirementCents)).tint(.teal)
      HStack { Text(L10n.text("Tahsis: ") + money(row.allocatedCents)).bold(); Spacer(); Text(L10n.text("Tahmini ek hizmet: ") + number(row.estimatedUnits)) }
     }.padding().background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
    if visibleLimit < matchingRows.count { Button(L10n.text("Sonraki 100 kaydı göster")) { visibleLimit += 100 } }
    if vm.result?.rows.isEmpty != false { Text(L10n.text("Hesaplama için kaynaklı ihtiyaç ve maliyet kayıtları ekleyin.")).foregroundStyle(.secondary) }
   }.padding(28)
  }.onAppear { syncParameters() }
   .onChange(of: vm.allocationSearch) { _, _ in visibleLimit = 100 }
   .onChange(of: vm.scenario?.budgetCents) { _, _ in syncParameters() }
   .onChange(of: vm.scenario?.povertyWeight) { _, _ in syncParameters() }
 }
 private func syncParameters() { budgetText = String(vm.scenario?.budgetCents ?? 0); weight = vm.scenario?.povertyWeight ?? 0 }
}
struct DeploymentView: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 @State private var visibleLimit = 100
 var body: some View {
  let matchingRows = vm.filteredDeploymentRows
  ScrollView {
   LazyVStack(alignment: .leading, spacing: 20) {
    Text(L10n.text("Tahsis → uygulanabilir hizmet")).font(.largeTitle.bold())
    Text(L10n.text("Bu ekran finansman kapsamını gösterir. Proje onayı, ihale, personel temini ve teslim takvimi ayrıca doğrulanmalıdır.")).foregroundStyle(.secondary)
    RegionResultsSearch(query: $vm.deploymentSearch, fieldIdentifier: "deploymentRegionSearch")
    Text(L10n.format("search.count", String(min(visibleLimit, matchingRows.count)), String(matchingRows.count), String(vm.result?.rows.count ?? 0))).font(.caption).foregroundStyle(.secondary)
    if matchingRows.isEmpty && !(vm.result?.rows.isEmpty ?? true) {
     ContentUnavailableView(L10n.text("Eşleşen kayıt yok"), systemImage: "magnifyingglass", description: Text(L10n.text("İl veya ilçe adını kontrol edin ya da aramayı temizleyin.")))
    }
    ForEach(Array(matchingRows.prefix(visibleLimit))) { row in
     GroupBox(vm.districtName(row) + " • " + (vm.services.first { $0.id == row.serviceID }?.localizedName ?? row.serviceID)) {
      VStack(alignment: .leading, spacing: 12) {
       Text(L10n.text("Karşılanmayan finansman: ") + money(row.requirementCents - row.allocatedCents)).font(.headline)
       if let record = vm.scenario?.records.first(where: { $0.districtID + ":" + $0.serviceID == row.id }) {
        Text(L10n.format("deployment.horizon", String(record.horizonYears), String(record.referenceYear)))
        Text(L10n.text("Tam birim maliyeti: ") + number((Double(record.capitalUnitCents) + Double(record.annualUnitCents) * Double(record.horizonYears)) * record.deliveryCostIndex / 100) + " TRY")
        Text(L10n.text("Yatırım için tahmini pay: ") + money(Int64((row.estimatedUnits * Double(record.capitalUnitCents) * record.deliveryCostIndex).rounded())))
        Text(L10n.text("Yıllık işletme için tahmini pay: ") + money(Int64((row.estimatedUnits * Double(record.annualUnitCents) * record.deliveryCostIndex).rounded())))
       }
       Label(L10n.text("Planlama aşaması • uygulama onayı bekliyor"), systemImage: "clock")
       Text(L10n.text("Sorumlu kurum • saha ve izinler • satın alma • işe alım • bakım • çıktı doğrulama: henüz atanmadı.")).font(.caption).foregroundStyle(.secondary)
      }.frame(maxWidth: .infinity, alignment: .leading).padding()
     }
    }
    if visibleLimit < matchingRows.count { Button(L10n.text("Sonraki 100 kaydı göster")) { visibleLimit += 100 } }
    Text(L10n.text("Mevcut model, ayrılmış bir bütçeyi dağıtır. Gelir tahmini, borç sürdürülebilirliği ve makroekonomik etkiler bu sürümde hesaplanmaz. Tasarruflar veya sosyal faydalar bütçe geliri olarak eklenmez.")).font(.callout).foregroundStyle(.secondary)
   }.padding(28)
  }.onChange(of: vm.deploymentSearch) { _, _ in visibleLimit = 100 }
 }
}

struct FinanceEditor: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 @State private var selectedPresetID = ""
 @State private var envelope = FinancialEnvelope(ownRevenueCents: 0, externalTransfersCents: 0, committedSpendingCents: 0, debtServiceCents: 0, reserveCents: 0)
 private var isCentralBudget: Bool { envelope.provenance?.scope == "central_government_budget" }
 var body: some View {
  GroupBox(L10n.text("Gelirden kullanılabilir bütçeye • 2025 verileri / kuruş")) {
   VStack(alignment: .leading, spacing: 12) {
    if !vm.financePresets.isEmpty {
     HStack {
      Picker(L10n.text("JSON veri seti"), selection: $selectedPresetID) { Text(L10n.text("Veri seti seçin")).tag(""); ForEach(vm.financePresets) { Text(L10n.text($0.name)).tag($0.id) } }
      Button(L10n.text("2025 JSON verisini uygula")) { if let preset = vm.financePresets.first(where: { $0.id == selectedPresetID }) { vm.applyFinancePreset(preset) } }
       .disabled(vm.scenario == nil)
     }
    }
    Text(L10n.text("Kullanılabilir = max(0, gelir + ek transfer − faiz dışı gider/taahhüt − faiz/borç gideri − ek rezerv). Açık ayrıca gösterilir. Konsolidasyon içi transferleri tekrar eklemeyin.")).font(.caption)
    HStack(alignment: .top, spacing: 10) {
     FinanceAmountField(title: isCentralBudget ? L10n.text("Bütçe gelirleri") : L10n.text("Öz gelir"), cents: $envelope.ownRevenueCents)
     FinanceAmountField(title: L10n.text("Ek dış transfer"), cents: $envelope.externalTransfersCents)
     FinanceAmountField(title: isCentralBudget ? L10n.text("Faiz dışı gider") : L10n.text("Taahhütler"), cents: $envelope.committedSpendingCents)
     FinanceAmountField(title: isCentralBudget ? L10n.text("Faiz (anapara hariç)") : L10n.text("Borç servisi"), cents: $envelope.debtServiceCents)
     FinanceAmountField(title: L10n.text("Ek rezerv kesintisi"), cents: $envelope.reserveCents)
    }
    Button(L10n.text("Finansman değişikliklerini uygula")) {
     var updated = envelope
     if updated != vm.scenario?.finances, updated.provenance != nil {
      updated.provenance?.status = "user_edited"
      updated.provenance?.title = "Kullanıcı tarafından düzenlenen finansman"
      updated.provenance?.assumptions = nil
      updated.provenance?.notes.insert("Tutarlar kullanıcı tarafından düzenlendi; önceki kaynak oranları artık bu tutarları açıklamayabilir.", at: 0)
     }
     vm.updateFinances(updated)
    }
    if let f = vm.scenario?.finances {
     HStack {
      Text(L10n.text("Kullanılabilir planlama zarfı: ") + money(f.availableCents)).bold()
      Spacer()
      if f.fundingGapCents > 0 { Text(L10n.text("Finansman açığı: ") + money(f.fundingGapCents)).bold().foregroundStyle(.orange) }
     }
     if let metadata = f.provenance {
      Text(metadata.title + " • " + String(metadata.referenceYear)).font(.headline)
      Text(metadata.status == "reported" ? L10n.text("YAYIMLANAN GERÇEKLEŞME • merkezi yönetim bütçesi") : L10n.text("VARSAYIM / KULLANICI GİRDİSİ • doğrulanmış serbest ödenek değildir")).font(.caption.bold()).foregroundStyle(metadata.status == "reported" ? Color.secondary : Color.orange)
      if let url = URL(string: metadata.sourceURL) { Link(L10n.text("Kaynak tablo"), destination: url) }
      DisclosureGroup(L10n.text("Kapsam, eşleme ve varsayımlar")) { ForEach(metadata.notes, id: \.self) { Text($0).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 3) } }
     }
    } else { Text(L10n.text("Finansman verisi yok. Yukarıdan 2025 JSON veri setini uygulayın.")).foregroundStyle(.orange) }
   }.padding()
  }.onAppear { sync() }
   .onChange(of: vm.scenario?.finances) { _, _ in sync() }
 }
 private func sync() {
  if let current = vm.scenario?.finances { envelope = current }
  if selectedPresetID.isEmpty { selectedPresetID = vm.financePresets.first?.id ?? "" }
 }
}
struct FinanceAmountField: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let title: String
 @Binding var cents: Int64
 var body: some View {
  VStack(alignment: .leading, spacing: 4) {
   Text(L10n.text(title)).font(.caption).lineLimit(2)
   TextField(L10n.text(title), value: $cents, format: .number.locale(L10n.locale)).textFieldStyle(.roundedBorder).accessibilityLabel(L10n.text(title))
   Text(L10n.text("kuruş • ") + money(cents)).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
  }.frame(maxWidth: .infinity, alignment: .leading)
 }
}

struct RegionResultsSearch: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @Binding var query: String
 let fieldIdentifier: String
 var body: some View {
  GroupBox(L10n.text("İl / ilçe ara")) {
     VStack(alignment: .leading, spacing: 8) {
      HStack {
       Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
       TextField(L10n.text("İl veya ilçe adı • ör. İzmir, Urla, İzmir Urla"), text: $query)
        .textFieldStyle(.roundedBorder).accessibilityIdentifier(fieldIdentifier)
       if !query.isEmpty { Button(L10n.text("Temizle"), systemImage: "xmark.circle.fill") { query = "" } }
      }
      Text(L10n.text("Arama yalnızca görünen kayıtları filtreler; bütçe ve hesaplamalar tüm ilçeleri kapsamaya devam eder.")).font(.caption).foregroundStyle(.secondary)
     }.padding(8)
    }
 }
}
