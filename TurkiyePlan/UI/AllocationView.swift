import SwiftUI
struct AllocationView: View {
 @ObservedObject var vm: PlanningViewModel
 @State private var visibleLimit = 100
 @State private var budgetText = ""
 @State private var weight = 0.0
 var body: some View {
  let matchingRows = vm.filteredAllocationRows
  ScrollView {
   LazyVStack(alignment: .leading, spacing: 20) {
    Text("Her tahsisin hesabı açık.").font(.largeTitle.bold())
    FinanceEditor(vm: vm)
    Text("Oranı tanımlı ilçe: " + String(vm.povertyDistrictCount) + ". Tahmini oranlar resmî ölçüm değildir; bilinmeyen oranlarla pozitif yoksulluk ağırlığı uygulanamaz.").font(.caption).foregroundStyle(.secondary)
    GroupBox("Senaryo parametreleri") {
     HStack {
      VStack(alignment: .leading) {
       Text("Dağıtılacak plan bütçesi (kuruş)").font(.caption)
       TextField("Toplam bütçe • kuruş", text: $budgetText).textFieldStyle(.roundedBorder)
      }
      Button("Bütçeyi uygula") { if let cents = Int64(budgetText) { vm.updateBudget(cents) } else { vm.error = "Bütçeyi tam sayı kuruş olarak girin." } }
      Text("Yoksulluk ağırlığı")
      Slider(value: $weight, in: 0...2, step: 0.05) { Text("Ağırlık") }.frame(width: 140)
      Text(number(weight)).monospacedDigit()
      Button("Ağırlığı uygula") { vm.updateWeight(weight) }
     }.padding()
    }
    GroupBox("Formül • önerilen deneysel dağıtım, resmî politika değildir") {
     VStack(alignment: .leading, spacing: 8) {
      Text("Açık = max(0, ceil(ihtiyaç duyan × hedef kapsam) − yeterli hizmet alan)")
      Text("Gereksinim = açık × (birim yatırım + yıllık işletme × yıl) × maliyet endeksi")
      Text("Öncelik puanı = gereksinim × (1 + yoksulluk ağırlığı × yoksulluk oranı) ÷ mali kapasite endeksi")
      Text("Tahsis = kalan bütçe × puan ÷ aktif kayıtların toplam puanı")
      Text("Tahsis gereksinimde sınırlanır. Fazla pay diğer kayıtlara yeniden dağıtılır; gereksinimler karşılanınca kalan bütçe tutulur. Kuruş kalanı kimlik sırasına göre dağıtılır.")
      Text("Birim tahmini = açık × tahsis ÷ gereksinim. Kesirli tahmin bir inşaat veya satın alma taahhüdü değildir.").foregroundStyle(.secondary)
     }.font(.system(.body, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding()
    }
    GroupBox("İl / ilçe ara") {
     VStack(alignment: .leading, spacing: 8) {
      HStack {
       Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
       TextField("İl veya ilçe adı • ör. İzmir, Urla, İzmir Urla", text: $vm.allocationSearch)
        .textFieldStyle(.roundedBorder).accessibilityIdentifier("allocationRegionSearch")
       if !vm.allocationSearch.isEmpty { Button("Temizle", systemImage: "xmark.circle.fill") { vm.allocationSearch = "" } }
      }
      Text("Arama yalnızca görünen kayıtları filtreler; bütçe ve hesaplamalar tüm ilçeleri kapsamaya devam eder.").font(.caption).foregroundStyle(.secondary)
     }.padding(8)
    }
    Text("Gösterilen: " + String(min(visibleLimit, matchingRows.count)) + " / " + String(matchingRows.count) + " eşleşme • Toplam " + String(vm.result?.rows.count ?? 0) + " kayıt").font(.caption).foregroundStyle(.secondary)
    if matchingRows.isEmpty && !(vm.result?.rows.isEmpty ?? true) {
     ContentUnavailableView("Eşleşen kayıt yok", systemImage: "magnifyingglass", description: Text("İl veya ilçe adını kontrol edin ya da aramayı temizleyin."))
    }
    ForEach(Array(matchingRows.prefix(visibleLimit))) { row in
     VStack(alignment: .leading, spacing: 8) {
      HStack { Text(vm.districtName(row)).font(.headline); Spacer(); Text(vm.services.first { $0.id == row.serviceID }?.name ?? row.serviceID) }
      HStack { Text("Açık: " + number(row.gap)); Spacer(); Text("Puan: " + number(row.score)); Spacer(); Text("Gereksinim: " + money(row.requirementCents)) }
      ProgressView(value: row.requirementCents == 0 ? 0 : Double(row.allocatedCents) / Double(row.requirementCents)).tint(.teal)
      HStack { Text("Tahsis: " + money(row.allocatedCents)).bold(); Spacer(); Text("Tahmini ek hizmet: " + number(row.estimatedUnits)) }
     }.padding().background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
    if visibleLimit < matchingRows.count { Button("Sonraki 100 kaydı göster") { visibleLimit += 100 } }
    if vm.result?.rows.isEmpty != false { Text("Hesaplama için kaynaklı ihtiyaç ve maliyet kayıtları ekleyin.").foregroundStyle(.secondary) }
   }.padding(28)
  }.onAppear { syncParameters() }
   .onChange(of: vm.allocationSearch) { _, _ in visibleLimit = 100 }
   .onChange(of: vm.scenario?.budgetCents) { _, _ in syncParameters() }
   .onChange(of: vm.scenario?.povertyWeight) { _, _ in syncParameters() }
 }
 private func syncParameters() { budgetText = String(vm.scenario?.budgetCents ?? 0); weight = vm.scenario?.povertyWeight ?? 0 }
}
struct DeploymentView: View {
 @ObservedObject var vm: PlanningViewModel
 @State private var visibleLimit = 100
 var body: some View {
  ScrollView {
   LazyVStack(alignment: .leading, spacing: 20) {
    Text("Tahsis → uygulanabilir hizmet").font(.largeTitle.bold())
    Text("Bu ekran finansman kapsamını gösterir. Proje onayı, ihale, personel temini ve teslim takvimi ayrıca doğrulanmalıdır.").foregroundStyle(.secondary)
    Text("Gösterilen: " + String(min(visibleLimit, vm.result?.rows.count ?? 0)) + " / " + String(vm.result?.rows.count ?? 0) + ". Tüm kayıtlar hesaplamaya dahildir.").font(.caption).foregroundStyle(.secondary)
    ForEach(Array((vm.result?.rows ?? []).prefix(visibleLimit))) { row in
     GroupBox(vm.districtName(row) + " • " + (vm.services.first { $0.id == row.serviceID }?.name ?? row.serviceID)) {
      VStack(alignment: .leading, spacing: 12) {
       Text("Karşılanmayan finansman: " + money(row.requirementCents - row.allocatedCents)).font(.headline)
       if let record = vm.scenario?.records.first(where: { $0.districtID + ":" + $0.serviceID == row.id }) {
        Text("Yatırım + \(record.horizonYears) yıllık işletme kapsamı • \(record.referenceYear) sabit fiyatları")
        Text("Tam birim maliyeti: " + number((Double(record.capitalUnitCents) + Double(record.annualUnitCents) * Double(record.horizonYears)) * record.deliveryCostIndex / 100) + " TRY")
        Text("Yatırım için tahmini pay: " + money(Int64((row.estimatedUnits * Double(record.capitalUnitCents) * record.deliveryCostIndex).rounded())))
        Text("Yıllık işletme için tahmini pay: " + money(Int64((row.estimatedUnits * Double(record.annualUnitCents) * record.deliveryCostIndex).rounded())))
       }
       Label("Planlama aşaması • uygulama onayı bekliyor", systemImage: "clock")
       Text("Sorumlu kurum • saha ve izinler • satın alma • işe alım • bakım • çıktı doğrulama: henüz atanmadı.").font(.caption).foregroundStyle(.secondary)
      }.frame(maxWidth: .infinity, alignment: .leading).padding()
     }
    }
    if visibleLimit < (vm.result?.rows.count ?? 0) { Button("Sonraki 100 kaydı göster") { visibleLimit += 100 } }
    Text("Mevcut model, ayrılmış bir bütçeyi dağıtır. Gelir tahmini, borç sürdürülebilirliği ve makroekonomik etkiler bu sürümde hesaplanmaz. Tasarruflar veya sosyal faydalar bütçe geliri olarak eklenmez.").font(.callout).foregroundStyle(.secondary)
   }.padding(28)
  }
 }
}

struct FinanceEditor: View {
 @ObservedObject var vm: PlanningViewModel
 @State private var selectedPresetID = ""
 @State private var envelope = FinancialEnvelope(ownRevenueCents: 0, externalTransfersCents: 0, committedSpendingCents: 0, debtServiceCents: 0, reserveCents: 0)
 private var isCentralBudget: Bool { envelope.provenance?.scope == "central_government_budget" }
 var body: some View {
  GroupBox("Gelirden kullanılabilir bütçeye • 2025 verileri / kuruş") {
   VStack(alignment: .leading, spacing: 12) {
    if !vm.financePresets.isEmpty {
     HStack {
      Picker("JSON veri seti", selection: $selectedPresetID) { Text("Veri seti seçin").tag(""); ForEach(vm.financePresets) { Text($0.name).tag($0.id) } }
      Button("2025 JSON verisini uygula") { if let preset = vm.financePresets.first(where: { $0.id == selectedPresetID }) { vm.applyFinancePreset(preset) } }
       .disabled(vm.scenario == nil)
     }
    }
    Text("Kullanılabilir = max(0, gelir + ek transfer − faiz dışı gider/taahhüt − faiz/borç gideri − ek rezerv). Açık ayrıca gösterilir. Konsolidasyon içi transferleri tekrar eklemeyin.").font(.caption)
    HStack(alignment: .top, spacing: 10) {
     FinanceAmountField(title: isCentralBudget ? "Bütçe gelirleri" : "Öz gelir", cents: $envelope.ownRevenueCents)
     FinanceAmountField(title: "Ek dış transfer", cents: $envelope.externalTransfersCents)
     FinanceAmountField(title: isCentralBudget ? "Faiz dışı gider" : "Taahhütler", cents: $envelope.committedSpendingCents)
     FinanceAmountField(title: isCentralBudget ? "Faiz (anapara hariç)" : "Borç servisi", cents: $envelope.debtServiceCents)
     FinanceAmountField(title: "Ek rezerv kesintisi", cents: $envelope.reserveCents)
    }
    Button("Finansman değişikliklerini uygula") {
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
      Text("Kullanılabilir planlama zarfı: " + money(f.availableCents)).bold()
      Spacer()
      if f.fundingGapCents > 0 { Text("Finansman açığı: " + money(f.fundingGapCents)).bold().foregroundStyle(.orange) }
     }
     if let metadata = f.provenance {
      Text(metadata.title + " • " + String(metadata.referenceYear)).font(.headline)
      Text(metadata.status == "reported" ? "YAYIMLANAN GERÇEKLEŞME • merkezi yönetim bütçesi" : "VARSAYIM / KULLANICI GİRDİSİ • doğrulanmış serbest ödenek değildir").font(.caption.bold()).foregroundStyle(metadata.status == "reported" ? Color.secondary : Color.orange)
      if let url = URL(string: metadata.sourceURL) { Link("Kaynak tablo", destination: url) }
      DisclosureGroup("Kapsam, eşleme ve varsayımlar") { ForEach(metadata.notes, id: \.self) { Text($0).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 3) } }
     }
    } else { Text("Finansman verisi yok. Yukarıdan 2025 JSON veri setini uygulayın.").foregroundStyle(.orange) }
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
 let title: String
 @Binding var cents: Int64
 var body: some View {
  VStack(alignment: .leading, spacing: 4) {
   Text(title).font(.caption).lineLimit(2)
   TextField(title, value: $cents, format: .number).textFieldStyle(.roundedBorder).accessibilityLabel(title)
   Text("kuruş • " + money(cents)).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
  }.frame(maxWidth: .infinity, alignment: .leading)
 }
}
