import SwiftUI
struct PlanningScreen: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 let tab: AppTab
 var body: some View {
  VStack(alignment: .leading, spacing: 0) {
   HStack {
    Label(L10n.text("Türkiye • Kamu Planı"), systemImage: "building.2.crop.circle").font(.title2.bold())
    Spacer()
    LanguageMenu()
    if vm.scenario?.isDemo == true { Text(L10n.text("SENTETİK DEMO")).font(.caption.bold()).foregroundStyle(.orange) }
    Text(L10n.text(vm.scenario?.name ?? L10n.text("Yükleniyor…"))).foregroundStyle(.secondary).lineLimit(1)
   }.padding()
   Divider()
   if let error = vm.error { Text(L10n.message(error)).foregroundStyle(.red).padding().textSelection(.enabled) }
   if let notice = vm.dataNotice { Text(L10n.message(notice)).font(.caption).foregroundStyle(.secondary).padding(.horizontal) }
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
   HStack { Text(L10n.text("Eksik veri sıfır değildir. Sonuçlar yalnızca girilmiş ilçe–hizmet kayıtlarını kapsar.")); Spacer(); Text("TRY • " + String(vm.scenario?.priceYear ?? 0)) }.font(.caption).foregroundStyle(.secondary).padding(10)
  }.frame(minWidth: 1100, minHeight: 720)
 }
 private var overview: some View {
  ScrollView {
   VStack(alignment: .leading, spacing: 24) {
    Text(L10n.text("Kaynakları ihtiyaçla buluşturun.")).font(.largeTitle.bold())
    Text(L10n.text("Önce veriyi doğrulayın; sonra hizmet açığını, maliyeti ve finansmanı birlikte değerlendirin.")).foregroundStyle(.secondary)
    HStack(spacing: 16) {
     MetricCard(title: L10n.text("İl"), value: String(vm.geography?.provinces.count ?? 0), symbol: "map")
     MetricCard(title: L10n.text("İlçe"), value: String(vm.geography?.districts.count ?? 0), symbol: "building.2")
     MetricCard(title: L10n.text("İlçe–hizmet kaydı"), value: String(vm.scenario?.records.count ?? 0), symbol: "tablecells")
     MetricCard(title: L10n.text("Nüfus verisi olan ilçe"), value: String(vm.populationDistrictCount), symbol: "person.3")
    }
    DataQualityDashboard(vm: vm)
    ScenarioLibraryView(vm: vm)
    PopulationImportButton(vm: vm)
    Text(L10n.text("Nüfus gözlemleri ve hizmet ihtiyacı kayıtları ayrıdır. Nüfusun bilinmesi, sağlık ihtiyacı veya mevcut hizmet kapsamının bilindiği anlamına gelmez.")).font(.caption).foregroundStyle(.secondary)
    HStack(spacing: 16) {
     MetricCard(title: L10n.text("Plan bütçesi"), value: money(vm.scenario?.budgetCents ?? 0), symbol: "banknote")
     MetricCard(title: L10n.text("Dağıtılan"), value: money((vm.scenario?.budgetCents ?? 0) - (vm.result?.unallocatedCents ?? 0)), symbol: "arrow.triangle.branch")
     MetricCard(title: L10n.text("Dağıtılmayan"), value: money(vm.result?.unallocatedCents ?? 0), symbol: "tray")
    }
    GroupBox(L10n.text("Hizmetlere göre tahsis • yalnızca mevcut kayıtlar")) {
     if (vm.result?.rows ?? []).isEmpty { ContentUnavailableView(L10n.text("Henüz planlama verisi yok"), systemImage: "tray", description: Text(L10n.text("İller ve İlçeler sekmesinden kayıt ekleyin veya Veri ve Kaynaklar sekmesinden JSON içe aktarın."))) }
     else { AllocationBarChart(rows: vm.serviceTotals).padding() }
    }
    Button(L10n.text("İlçe verilerini incele"), systemImage: "arrow.right") { vm.selectedTab = .regions }.buttonStyle(.borderedProminent)
   }.padding(28)
  }
 }
}
struct MetricCard: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let title: String; let value: String; let symbol: String
 var body: some View { VStack(alignment: .leading, spacing: 10) { Label(L10n.text(title), systemImage: symbol).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.bold()).minimumScaleFactor(0.6).lineLimit(1) }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14)) }
}
struct RegionsView: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 var body: some View {
  HSplitView {
   VStack {
    Picker(L10n.text("İl"), selection: Binding(get: { vm.selectedProvinceID }, set: { vm.requestProvinceSelection($0) })) {
     Text(L10n.text("Tüm iller")).tag(String?.none)
     ForEach(vm.geography?.provinces ?? []) { Text($0.name).tag(Optional($0.id)) }
    }.padding([.horizontal, .top])
    TextField(L10n.text("İlçe ara"), text: $vm.search).textFieldStyle(.roundedBorder).padding(.horizontal)
    List(vm.districts, selection: Binding(get: { vm.selectedDistrictID }, set: { vm.requestDistrictSelection($0) })) { district in
     HStack { Text(district.name); Spacer(); if vm.populationObservation(for: district.id) != nil { Image(systemName: "person.fill.checkmark").foregroundStyle(.teal).help(L10n.text("Nüfus gözlemi mevcut")) } }.tag(district.id)
    }
    Text(L10n.format("district.count", String(vm.districts.count))).font(.caption).padding(8)
   }.frame(minWidth: 250, idealWidth: 300, maxWidth: 380)
   VStack(alignment: .leading) {
    if let district = vm.selectedDistrict {
     Text(district.name).font(.largeTitle.bold())
     Text(L10n.text("Kimlik: ") + district.id).font(.caption).foregroundStyle(.secondary)
     PopulationSummary(vm: vm, district: district)
     DisclosureGroup(L10n.text("İlçe yoksulluk profili")) { PovertyProfileEditor(vm: vm, geographyID: district.id).id(district.id) }
     Picker(L10n.text("Hizmet"), selection: Binding(get: { vm.selectedServiceID }, set: { vm.requestServiceSelection($0) })) { ForEach(vm.services) { Text(L10n.text($0.name)).tag($0.id) } }
     TabView {
      RecordEditor(vm: vm, districtID: district.id, serviceID: vm.selectedServiceID).id(district.id + vm.selectedServiceID).tabItem { Text(L10n.text("Hizmet girdileri")) }
      IndicatorEditor(vm: vm, districtID: district.id).id(district.id).tabItem { Text(L10n.text("Sosyal ve mali göstergeler")) }
     }
    } else { ContentUnavailableView(L10n.text("Bir ilçe seçin"), systemImage: "map", description: Text(L10n.text("Coğrafya kayıtları hazır. Mali ve sosyal göstergeler ayrıca girilir."))) }
   }.padding(24).frame(minWidth: 600, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
 }
}
struct RecordEditor: View {
 @ObservedObject private var localization = LocalizationSettings.shared
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
   Section(L10n.text("Talep ve erişim")) {
    if vm.currentRecord == nil { Text(L10n.text("Yeni hizmet taslağı: yalnızca nüfus gözlemden doldurulur. Diğer alanlar ölçülmüş veri değildir; ihtiyaç ve maliyet kaynağı girilmelidir.")).font(.caption).foregroundStyle(.secondary) }
    if let observed = vm.populationObservation(for: districtID), let value = observed.value {
     HStack { Text(L10n.format("population.observed", String(observed.referenceYear), number(value))); Spacer(); Button(L10n.text("Nüfusu kullan")) { record.population = Int(value) } }
    }
    TextField(L10n.text("Nüfus"), value: $record.population, format: .number.locale(L10n.locale))
    TextField(L10n.text("Hizmete ihtiyaç duyan"), value: $record.eligible, format: .number.locale(L10n.locale))
    TextField(L10n.text("Yeterli hizmet alan"), value: $record.served, format: .number.locale(L10n.locale))
    TextField(L10n.text("Hedef kapsam (0–1)"), value: $record.targetCoverage, format: .number.locale(L10n.locale))
    Text(vm.currentRecord == nil && record.source.isEmpty ? L10n.text("Hizmet açığı: henüz hesaplanmadı") : L10n.text("Hizmet açığı: ") + number(record.gap))
   }
   Section(L10n.text("Maliyet ve eşitleme • parasal girdiler kuruş")) {
    TextField(L10n.text("Birim yatırım maliyeti"), value: $record.capitalUnitCents, format: .number.locale(L10n.locale))
    TextField(L10n.text("Birim yıllık işletme maliyeti"), value: $record.annualUnitCents, format: .number.locale(L10n.locale))
    TextField(L10n.text("İşletme süresi (yıl)"), value: $record.horizonYears, format: .number.locale(L10n.locale))
    if let profile = vm.povertyProfile(for: districtID) {
     Text(L10n.format("poverty.summary", profile.rate.map { number($0 * 100) + "%" } ?? L10n.text("Veri yok"), L10n.text(profile.status), String(profile.referenceYear)))
     Text(L10n.text("Tüm hizmetler aynı ilçe profilini kullanır. Düzenleme üstteki İlçe yoksulluk profili bölümündedir.")).font(.caption).foregroundStyle(.secondary)
    } else { Text(L10n.text("İlçe yoksulluk profili yok. Eski kayıttaki 0, yoksulluğun sıfır olduğu anlamına gelmez.")).font(.caption).foregroundStyle(.orange) }
    TextField(L10n.text("Hizmet maliyeti endeksi (>0)"), value: $record.deliveryCostIndex, format: .number.locale(L10n.locale))
    TextField(L10n.text("Mali kapasite endeksi (>0)"), value: $record.fiscalCapacityIndex, format: .number.locale(L10n.locale))
   }
   Section(L10n.text("Kaynak")) {
    TextField(L10n.text("Kaynak / veri seti / yöntem"), text: $record.source)
    TextField(L10n.text("Maliyetlerin fiyat yılı"), value: $record.referenceYear, format: .number.locale(L10n.locale).grouping(.never))
    Text(L10n.format("price.year.note", String(vm.scenario?.priceYear ?? 0))).font(.caption).foregroundStyle(.secondary)
    Text(L10n.text("Yeni alanlardaki sıfırlar gözlem değildir. Kaynak girilmeden kayıt kabul edilmez.")).font(.caption).foregroundStyle(.secondary)
   }
   if !validationIssues.isEmpty {
    Section(L10n.text("Kaydetmeden önce tamamlayın")) {
     ForEach(validationIssues, id: \.self) { Text(L10n.message($0)).font(.caption).foregroundStyle(.orange) }
    }
   }
   HStack {
    Button(L10n.text("Kaydet ve hesapla")) { vm.upsert(record) }.buttonStyle(.borderedProminent).disabled(!validationIssues.isEmpty).help(validationIssues.first.map { L10n.message($0) } ?? L10n.text("Doğrulanmış girdileri yerel depoya kaydet ve hesapla"))
    Button(L10n.text("Kaydı kaldır"), role: .destructive) { vm.removeSelectedRecord() }
   }
  }.formStyle(.grouped).onChange(of: vm.populationObservation(for: districtID)) { _, value in
   if vm.currentRecord == nil, let population = value?.value { record.population = Int(population) }
  }.onChange(of: vm.currentRecord) { _, value in record = value ?? vm.newRecord(districtID: districtID, serviceID: serviceID) }
 }
}

struct PopulationImportButton: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 var body: some View {
  Button(vm.isLoadingPopulation ? L10n.text("Nüfus yükleniyor…") : L10n.text("Paket nüfus verilerini ekle"), systemImage: "square.and.arrow.down") {
   Task { await vm.loadBundledPopulation() }
  }.disabled(vm.isLoadingPopulation || vm.scenario == nil)
 }
}
struct PopulationSummary: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 let district: District
 var body: some View {
  GroupBox(L10n.text("Kaynaklı nüfus gözlemi")) {
   VStack(alignment: .leading, spacing: 6) {
    if let observed = vm.populationObservation(for: district.id), let value = observed.value {
     HStack {
      Text(L10n.text("İlçe: ") + number(value)).font(.title3.bold())
      Text("• " + String(observed.referenceYear)).foregroundStyle(.secondary)
      Spacer()
      if let province = vm.populationObservation(for: district.provinceID), let total = province.value { Text(L10n.text("İl toplamı: ") + number(total)).font(.caption) }
     }
     Text(observed.source).font(.caption2).foregroundStyle(.secondary).lineLimit(2).help(observed.source).textSelection(.enabled)
    } else {
     Text(L10n.text("Nüfus gözlemi yüklenmemiş; 0 kişi olduğu anlamına gelmez.")).foregroundStyle(.orange)
     PopulationImportButton(vm: vm)
    }
   }.frame(maxWidth: .infinity, alignment: .leading).padding(6)
  }
 }
}

struct AllocationBarChart: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let rows: [ServiceAllocationSummary]
 private var maximum: Double { max(1, Double(rows.map(\.allocatedCents).max() ?? 0)) }
 var body: some View {
  VStack(spacing: 14) {
   ForEach(rows) { row in
    HStack(spacing: 14) {
     Text(L10n.text(row.name)).font(.caption).frame(width: 160, alignment: .leading)
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
