import SwiftUI
struct PlanningScreen: View {
 @ObservedObject var vm: PlanningViewModel
 let tab: AppTab
 var body: some View {
  VStack(alignment: .leading, spacing: 0) {
   HStack {
    Label("Türkiye • Kamu Planı", systemImage: "building.2.crop.circle").font(.title2.bold())
    Spacer()
    if vm.scenario?.isDemo == true { Text("SENTETİK DEMO").font(.caption.bold()).foregroundStyle(.orange) }
    Text(vm.scenario?.name ?? "Yükleniyor…").foregroundStyle(.secondary).lineLimit(1)
   }.padding()
   Divider()
   if let error = vm.error { Text(error).foregroundStyle(.red).padding().textSelection(.enabled) }
   if let notice = vm.dataNotice { Text(notice).font(.caption).foregroundStyle(.secondary).padding(.horizontal) }
   Group {
    switch tab {
    case .overview: overview
    case .regions: RegionsView(vm: vm)
    case .allocation: AllocationView(vm: vm)
    case .deployment: DeploymentView(vm: vm)
    case .sources: SourcesView(vm: vm)
    }
   }.frame(maxWidth: .infinity, maxHeight: .infinity)
   Divider()
   HStack { Text("Eksik veri sıfır değildir. Sonuçlar yalnızca girilmiş ilçe–hizmet kayıtlarını kapsar."); Spacer(); Text("TRY • " + String(vm.scenario?.priceYear ?? 0)) }.font(.caption).foregroundStyle(.secondary).padding(10)
  }.frame(minWidth: 1100, minHeight: 720)
 }
 private var overview: some View {
  ScrollView {
   VStack(alignment: .leading, spacing: 24) {
    Text("Kaynakları ihtiyaçla buluşturun.").font(.largeTitle.bold())
    Text("Önce veriyi doğrulayın; sonra hizmet açığını, maliyeti ve finansmanı birlikte değerlendirin.").foregroundStyle(.secondary)
    HStack(spacing: 16) {
     MetricCard(title: "İl", value: String(vm.geography?.provinces.count ?? 0), symbol: "map")
     MetricCard(title: "İlçe", value: String(vm.geography?.districts.count ?? 0), symbol: "building.2")
     MetricCard(title: "İlçe–hizmet kaydı", value: String(vm.scenario?.records.count ?? 0), symbol: "tablecells")
     MetricCard(title: "Nüfus verisi olan ilçe", value: String(vm.populationDistrictCount), symbol: "person.3")
    }
    PopulationImportButton(vm: vm)
    Text("Nüfus gözlemleri ve hizmet ihtiyacı kayıtları ayrıdır. Nüfusun bilinmesi, sağlık ihtiyacı veya mevcut hizmet kapsamının bilindiği anlamına gelmez.").font(.caption).foregroundStyle(.secondary)
    HStack(spacing: 16) {
     MetricCard(title: "Plan bütçesi", value: money(vm.scenario?.budgetCents ?? 0), symbol: "banknote")
     MetricCard(title: "Dağıtılan", value: money((vm.scenario?.budgetCents ?? 0) - (vm.result?.unallocatedCents ?? 0)), symbol: "arrow.triangle.branch")
     MetricCard(title: "Dağıtılmayan", value: money(vm.result?.unallocatedCents ?? 0), symbol: "tray")
    }
    GroupBox("Hizmetlere göre tahsis • yalnızca mevcut kayıtlar") {
     if (vm.result?.rows ?? []).isEmpty { ContentUnavailableView("Henüz planlama verisi yok", systemImage: "tray", description: Text("İller ve İlçeler sekmesinden kayıt ekleyin veya Veri ve Kaynaklar sekmesinden JSON içe aktarın.")) }
     else { AllocationBarChart(rows: vm.serviceTotals).padding() }
    }
    Button("İlçe verilerini incele", systemImage: "arrow.right") { vm.selectedTab = .regions }.buttonStyle(.borderedProminent)
   }.padding(28)
  }
 }
}
struct MetricCard: View {
 let title: String; let value: String; let symbol: String
 var body: some View { VStack(alignment: .leading, spacing: 10) { Label(title, systemImage: symbol).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.bold()).minimumScaleFactor(0.6).lineLimit(1) }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14)) }
}
struct RegionsView: View {
 @ObservedObject var vm: PlanningViewModel
 var body: some View {
  HSplitView {
   VStack {
    Picker("İl", selection: Binding(get: { vm.selectedProvinceID }, set: { vm.requestProvinceSelection($0) })) {
     Text("Tüm iller").tag(String?.none)
     ForEach(vm.geography?.provinces ?? []) { Text($0.name).tag(Optional($0.id)) }
    }.padding([.horizontal, .top])
    TextField("İlçe ara", text: $vm.search).textFieldStyle(.roundedBorder).padding(.horizontal)
    List(vm.districts, selection: Binding(get: { vm.selectedDistrictID }, set: { vm.requestDistrictSelection($0) })) { district in
     HStack { Text(district.name); Spacer(); if vm.populationObservation(for: district.id) != nil { Image(systemName: "person.fill.checkmark").foregroundStyle(.teal).help("Nüfus gözlemi mevcut") } }.tag(district.id)
    }
    Text("\(vm.districts.count) ilçe").font(.caption).padding(8)
   }.frame(minWidth: 250, idealWidth: 300, maxWidth: 380)
   VStack(alignment: .leading) {
    if let district = vm.selectedDistrict {
     Text(district.name).font(.largeTitle.bold())
     Text("Kimlik: " + district.id).font(.caption).foregroundStyle(.secondary)
     PopulationSummary(vm: vm, district: district)
     DisclosureGroup("İlçe yoksulluk profili") { PovertyProfileEditor(vm: vm, geographyID: district.id).id(district.id) }
     Picker("Hizmet", selection: Binding(get: { vm.selectedServiceID }, set: { vm.requestServiceSelection($0) })) { ForEach(vm.services) { Text($0.name).tag($0.id) } }
     TabView {
      RecordEditor(vm: vm, districtID: district.id, serviceID: vm.selectedServiceID).id(district.id + vm.selectedServiceID).tabItem { Text("Hizmet girdileri") }
      IndicatorEditor(vm: vm, districtID: district.id).id(district.id).tabItem { Text("Sosyal ve mali göstergeler") }
     }
    } else { ContentUnavailableView("Bir ilçe seçin", systemImage: "map", description: Text("Coğrafya kayıtları hazır. Mali ve sosyal göstergeler ayrıca girilir.")) }
   }.padding(24).frame(minWidth: 600, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
 }
}
struct RecordEditor: View {
 @ObservedObject var vm: PlanningViewModel
 let districtID: String; let serviceID: String
 @State private var record: NeedRecord
 private var validationIssues: [String] { NeedRecordValidation().issues(record, priceYear: vm.scenario?.priceYear ?? 0) }
 init(vm: PlanningViewModel, districtID: String, serviceID: String) {
  self.vm = vm; self.districtID = districtID; self.serviceID = serviceID
  _record = State(initialValue: vm.currentRecord ?? vm.newRecord(districtID: districtID, serviceID: serviceID))
 }
 var body: some View {
  Form {
   Section("Talep ve erişim") {
    if vm.currentRecord == nil { Text("Yeni hizmet taslağı: yalnızca nüfus gözlemden doldurulur. Diğer alanlar ölçülmüş veri değildir; ihtiyaç ve maliyet kaynağı girilmelidir.").font(.caption).foregroundStyle(.secondary) }
    if let observed = vm.populationObservation(for: districtID), let value = observed.value {
     HStack { Text("Gözlenen nüfus (" + String(observed.referenceYear) + "): " + number(value)); Spacer(); Button("Nüfusu kullan") { record.population = Int(value) } }
    }
    TextField("Nüfus", value: $record.population, format: .number)
    TextField("Hizmete ihtiyaç duyan", value: $record.eligible, format: .number)
    TextField("Yeterli hizmet alan", value: $record.served, format: .number)
    TextField("Hedef kapsam (0–1)", value: $record.targetCoverage, format: .number)
    Text(vm.currentRecord == nil && record.source.isEmpty ? "Hizmet açığı: henüz hesaplanmadı" : "Hizmet açığı: " + number(record.gap))
   }
   Section("Maliyet ve eşitleme • parasal girdiler kuruş") {
    TextField("Birim yatırım maliyeti", value: $record.capitalUnitCents, format: .number)
    TextField("Birim yıllık işletme maliyeti", value: $record.annualUnitCents, format: .number)
    TextField("İşletme süresi (yıl)", value: $record.horizonYears, format: .number)
    if let profile = vm.povertyProfile(for: districtID) {
     Text("İlçe yoksulluk oranı: " + (profile.rate.map { number($0 * 100) + "%" } ?? "Veri yok") + " • " + profile.status + " • " + String(profile.referenceYear))
     Text("Tüm hizmetler aynı ilçe profilini kullanır. Düzenleme üstteki İlçe yoksulluk profili bölümündedir.").font(.caption).foregroundStyle(.secondary)
    } else { Text("İlçe yoksulluk profili yok. Eski kayıttaki 0, yoksulluğun sıfır olduğu anlamına gelmez.").font(.caption).foregroundStyle(.orange) }
    TextField("Hizmet maliyeti endeksi (>0)", value: $record.deliveryCostIndex, format: .number)
    TextField("Mali kapasite endeksi (>0)", value: $record.fiscalCapacityIndex, format: .number)
   }
   Section("Kaynak") {
    TextField("Kaynak / veri seti / yöntem", text: $record.source)
    TextField("Maliyetlerin fiyat yılı", value: $record.referenceYear, format: .number.grouping(.never))
    Text("Plan fiyat yılı: " + String(vm.scenario?.priceYear ?? 0) + ". Nüfus tarihi ayrı bir gözlemdir; maliyetler ortak fiyat bazında olmalıdır.").font(.caption).foregroundStyle(.secondary)
    Text("Yeni alanlardaki sıfırlar gözlem değildir. Kaynak girilmeden kayıt kabul edilmez.").font(.caption).foregroundStyle(.secondary)
   }
   if !validationIssues.isEmpty {
    Section("Kaydetmeden önce tamamlayın") {
     ForEach(validationIssues, id: \.self) { Text($0).font(.caption).foregroundStyle(.orange) }
    }
   }
   HStack {
    Button("Kaydet ve hesapla") { vm.upsert(record) }.buttonStyle(.borderedProminent).disabled(!validationIssues.isEmpty).help(validationIssues.first ?? "Doğrulanmış girdileri yerel depoya kaydet ve hesapla")
    Button("Kaydı kaldır", role: .destructive) { vm.removeSelectedRecord() }
   }
  }.formStyle(.grouped).onChange(of: vm.populationObservation(for: districtID)) { _, value in
   if vm.currentRecord == nil, let population = value?.value { record.population = Int(population) }
  }.onChange(of: vm.currentRecord) { _, value in record = value ?? vm.newRecord(districtID: districtID, serviceID: serviceID) }
 }
}

struct PopulationImportButton: View {
 @ObservedObject var vm: PlanningViewModel
 var body: some View {
  Button(vm.isLoadingPopulation ? "Nüfus yükleniyor…" : "Paket nüfus verilerini ekle", systemImage: "square.and.arrow.down") {
   Task { await vm.loadBundledPopulation() }
  }.disabled(vm.isLoadingPopulation || vm.scenario == nil)
 }
}
struct PopulationSummary: View {
 @ObservedObject var vm: PlanningViewModel
 let district: District
 var body: some View {
  GroupBox("Kaynaklı nüfus gözlemi") {
   VStack(alignment: .leading, spacing: 6) {
    if let observed = vm.populationObservation(for: district.id), let value = observed.value {
     HStack {
      Text("İlçe: " + number(value)).font(.title3.bold())
      Text("• " + String(observed.referenceYear)).foregroundStyle(.secondary)
      Spacer()
      if let province = vm.populationObservation(for: district.provinceID), let total = province.value { Text("İl toplamı: " + number(total)).font(.caption) }
     }
     Text(observed.source).font(.caption2).foregroundStyle(.secondary).lineLimit(2).help(observed.source).textSelection(.enabled)
    } else {
     Text("Nüfus gözlemi yüklenmemiş; 0 kişi olduğu anlamına gelmez.").foregroundStyle(.orange)
     PopulationImportButton(vm: vm)
    }
   }.frame(maxWidth: .infinity, alignment: .leading).padding(6)
  }
 }
}

struct AllocationBarChart: View {
 let rows: [ServiceAllocationSummary]
 private var maximum: Double { max(1, Double(rows.map(\.allocatedCents).max() ?? 0)) }
 var body: some View {
  VStack(spacing: 14) {
   ForEach(rows) { row in
    HStack(spacing: 14) {
     Text(row.name).font(.caption).frame(width: 160, alignment: .leading)
     GeometryReader { geometry in
      ZStack(alignment: .leading) {
       Capsule().fill(.quaternary)
       Capsule().fill(.teal).frame(width: geometry.size.width * Double(row.allocatedCents) / maximum)
      }
     }.frame(height: 12)
     Text(money(row.allocatedCents)).font(.caption.monospacedDigit()).frame(width: 200, alignment: .trailing)
    }.accessibilityElement(children: .combine)
   }
  }.frame(maxWidth: .infinity).accessibilityElement(children: .contain).accessibilityIdentifier("serviceAllocationChart")
 }
}
