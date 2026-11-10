import AppKit
import SwiftUI
import Combine
enum AppTab: String, CaseIterable, Identifiable {
 case overview, regions, allocation, deployment, sources
 var id: String { rawValue }
 var title: String { switch self { case .overview: L10n.text("Genel Bakış"); case .regions: L10n.text("İller ve İlçeler"); case .allocation: L10n.text("Dağıtım Matematiği"); case .deployment: L10n.text("Uygulama Planı"); case .sources: "Veri ve Kaynaklar" } }
 var symbol: String { switch self { case .overview: "chart.bar.xaxis"; case .regions: "map"; case .allocation: "function"; case .deployment: "list.bullet.clipboard"; case .sources: "externaldrive" } }
}
@MainActor protocol TabRouting: AnyObject { func select(_ tab: AppTab) }
@MainActor final class ConcreteTabRouter: TabRouting {
 weak var tabController: NSTabViewController?
 private(set) var isApplyingSelection = false
 func select(_ tab: AppTab) {
  guard let controller = tabController, let index = AppTab.allCases.firstIndex(of: tab), controller.selectedTabViewItemIndex != index else { return }
  isApplyingSelection = true; defer { isApplyingSelection = false }
  controller.selectedTabViewItemIndex = index
 }
}
@MainActor protocol PlanningViewControlling: AnyObject { var viewModel: PlanningViewModel { get }; func reload() async }
@MainActor final class ConcretePlanningViewController: NSViewController, PlanningViewControlling {
 let viewModel: PlanningViewModel
 private let tab: AppTab
 init(viewModel: PlanningViewModel, tab: AppTab) { self.viewModel = viewModel; self.tab = tab; super.init(nibName: nil, bundle: nil) }
 required init?(coder: NSCoder) { fatalError("Use dependency injection") }
 override func loadView() {
  let container = NSView()
  let host = NSHostingController(rootView: LocalizedPlanningRoot(viewModel: viewModel, tab: tab).id(tab))
  addChild(host)
  let hosted = host.view; hosted.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(hosted)
  NSLayoutConstraint.activate([hosted.leadingAnchor.constraint(equalTo: container.leadingAnchor), hosted.trailingAnchor.constraint(equalTo: container.trailingAnchor), hosted.topAnchor.constraint(equalTo: container.topAnchor), hosted.bottomAnchor.constraint(equalTo: container.bottomAnchor)])
  view = container
 }
 func reload() async { await viewModel.load() }
}
@MainActor final class ConcreteTabViewController: NSTabViewController {
 private let viewModel: PlanningViewModel
 private let router: ConcreteTabRouter
 private var subscription: AnyCancellable?
 private var languageSubscription: AnyCancellable?
 private let deferredSelection = DeferredUIUpdates()
 init(viewModel: PlanningViewModel, router: ConcreteTabRouter) {
  self.viewModel = viewModel; self.router = router; super.init(nibName: nil, bundle: nil); tabStyle = .toolbar; router.tabController = self
  for tab in AppTab.allCases {
   let item = NSTabViewItem(viewController: ConcretePlanningViewController(viewModel: viewModel, tab: tab)); item.identifier = tab.rawValue; item.label = tab.title; item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: tab.title); addTabViewItem(item)
  }
  languageSubscription = LocalizationSettings.shared.$language.dropFirst().sink { [weak self] _ in
   self?.deferredSelection.enqueue(key: "language") { [weak self] in
    guard let self else { return }
    for (index, tab) in AppTab.allCases.enumerated() {
     self.tabViewItems[index].label = tab.title
     self.tabViewItems[index].image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: tab.title)
    }
    self.view.window?.title = L10n.text("Türkiye Kamu Planı")
   }
  }
  subscription = viewModel.$selectedTab.removeDuplicates().sink { [weak self] tab in
   self?.scheduleSelection(tab, fromToolbar: false)
  }
 }
 override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
  super.tabView(tabView, didSelect: tabViewItem)
  guard !router.isApplyingSelection, let id = tabViewItem?.identifier as? String, let tab = AppTab(rawValue: id), viewModel.selectedTab != tab else { return }
  scheduleSelection(tab, fromToolbar: true)
 }
 private func scheduleSelection(_ tab: AppTab, fromToolbar: Bool) {
  deferredSelection.enqueue(key: "navigation") { [weak self] in
   guard let self else { return }
   if fromToolbar {
    // Ignore stale native callbacks if another tab was selected before this turn.
    guard let index = AppTab.allCases.firstIndex(of: tab), self.selectedTabViewItemIndex == index else { return }
    if self.viewModel.selectedTab != tab { self.viewModel.selectedTab = tab }
   } else {
    // @Published emits in willSet; route only after its stored value has committed.
    guard self.viewModel.selectedTab == tab else { return }
    self.router.select(tab)
   }
  }
 }
 required init?(coder: NSCoder) { fatalError("Use dependency injection") }
}
