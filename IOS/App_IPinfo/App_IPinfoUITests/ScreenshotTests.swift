import XCTest

final class ScreenshotTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testCaptureScreenshots() throws {
        // Screenshot 1: Home screen
        sleep(1)
        let homeScreenshot = XCUIScreen.main.screenshot()
        let homeAttachment = XCTAttachment(screenshot: homeScreenshot)
        homeAttachment.name = "01_Home"
        homeAttachment.lifetime = .keepAlways
        add(homeAttachment)

        // Tap "My IP Address" button
        let myIPButton = app.buttons["My IP Address"]
        if myIPButton.waitForExistence(timeout: 5) {
            myIPButton.tap()
            sleep(3) // Wait for API response

            // Screenshot 2: Results screen
            let resultsScreenshot = XCUIScreen.main.screenshot()
            let resultsAttachment = XCTAttachment(screenshot: resultsScreenshot)
            resultsAttachment.name = "02_Results"
            resultsAttachment.lifetime = .keepAlways
            add(resultsAttachment)

            // Scroll down to see more content
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                sleep(1)

                // Screenshot 3: Results with map
                let mapScreenshot = XCUIScreen.main.screenshot()
                let mapAttachment = XCTAttachment(screenshot: mapScreenshot)
                mapAttachment.name = "03_Map"
                mapAttachment.lifetime = .keepAlways
                add(mapAttachment)
            }

            // Go back
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // Enter a domain name
        let searchField = app.textFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("google.com")

            // Screenshot 4: With domain entered
            let domainScreenshot = XCUIScreen.main.screenshot()
            let domainAttachment = XCTAttachment(screenshot: domainScreenshot)
            domainAttachment.name = "04_Domain_Entry"
            domainAttachment.lifetime = .keepAlways
            add(domainAttachment)

            // Tap Lookup
            let lookupButton = app.buttons["Lookup"]
            if lookupButton.waitForExistence(timeout: 3) {
                lookupButton.tap()
                sleep(3)

                // Screenshot 5: Domain results
                let domainResultsScreenshot = XCUIScreen.main.screenshot()
                let domainResultsAttachment = XCTAttachment(screenshot: domainResultsScreenshot)
                domainResultsAttachment.name = "05_Domain_Results"
                domainResultsAttachment.lifetime = .keepAlways
                add(domainResultsAttachment)
            }
        }
    }
}
