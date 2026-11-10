import XCTest
final class TurkiyePlanUITests: XCTestCase {
 override func setUpWithError() throws { continueAfterFailure = false }
 @MainActor func testLaunchAndRegionNavigation() throws {
  let app = XCUIApplication()
  app.launchArguments = ["--ui-testing", "-TurkiyePlan.interfaceLanguage", "tr"]
  app.launch()
  XCTAssertTrue(app.staticTexts["Kaynakları ihtiyaçla buluşturun."].waitForExistence(timeout: 20))
  let button = app.buttons["İlçe verilerini incele"]
  XCTAssertTrue(button.waitForExistence(timeout: 10)); button.click()
  XCTAssertTrue(app.staticTexts["Bir ilçe seçin"].waitForExistence(timeout: 10))
 }
}
