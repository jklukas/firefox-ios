/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let testBasicHTTPAuthURL = "https://jigsaw.w3.org/HTTP/Basic/"

class AuthenticationTest: BaseTestCase {

    fileprivate func setInterval(_ interval: String = "Immediately") {
        navigator.goto(PasscodeIntervalSettings)
        let table = app.tables["AuthenticationManager.settingsTableView"]
        app.staticTexts[interval].tap()
        navigator.goto(PasscodeSettings)
        waitForExistence(table.staticTexts[interval])
    }

    func testTurnOnOff() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)
        setInterval("Immediately")
        XCTAssertTrue(app.staticTexts["Immediately"].exists)
        navigator.performAction(Action.DisablePasscode)
    }

    func testChangePassCode() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)

        userState.newPasscode = "222222"
        navigator.performAction(Action.ChangePasscode)
        waitForExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
        navigator.performAction(Action.DisablePasscode)
    }

    // Smoketest
    func testPromptPassCodeUponReentry() {
        waitForExistence(app.textFields["url"], timeout: 5)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)        
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        app.cells["Search"].swipeUp()
        navigator.performAction(Action.SetPasscode)
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.UnlockLoginsSettings)
        waitForExistence(app.tables["Login List"], timeout: 5)

        //send app to background, and re-enter
        XCUIDevice.shared.press(.home)

        // Let's be sure the app is backgrounded
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitForExistence(springboard.icons["XCUITests-Runner"], timeout: 10)
        app.activate()

        // Disable this part do to Issue 8333
        // Need to be sure the app is ready
        // navigator.nowAt(LockedLoginsSettings)
        // waitForExistence(app.navigationBars["Enter Passcode"], timeout: 10)
    }

    func testPromptPassCodeUponReentryWithDelay() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)
        setInterval("After 5 minutes")
        navigator.performAction(Action.UnlockLoginsSettings)
        waitForExistence(app.tables["Login List"])

        // Send app to background, and re-enter
        XCUIDevice.shared.press(.home)
        app.activate()

        // Login List is shown since the delay is set to 5min
        navigator.nowAt(LockedLoginsSettings)
        waitForExistence(app.tables["Login List"], timeout: 3)
    }

    func testChangePasscodeShowsErrorStates() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)

        userState.passcode = "222222"
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)
        waitForExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)
        waitForExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])

        userState.passcode = "111111"
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)
        waitForExistence(app.staticTexts["Enter a new passcode"])

        // Enter same passcode as new one
        userState.newPasscode = "111111"
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        waitForExistence(app.staticTexts["New passcode must be different than existing code."])

        // Enter mismatched passcode
        userState.newPasscode = "444444"
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        waitForExistence(app.staticTexts["Re-enter passcode"])
        userState.newPasscode = "444445"
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        waitForExistence(app.staticTexts["Passcodes didn’t match. Try again."])

        // Put proper password
        userState.newPasscode = "555555"
        XCTAssertTrue(app.staticTexts["Enter a new passcode"].exists)
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        waitForExistence(app.staticTexts["Re-enter passcode"])
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        waitForExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
    }

    func testChangeRequirePasscodeInterval() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)
        navigator.goto(PasscodeIntervalSettings)

        waitForExistence(app.staticTexts["Immediately"])
        XCTAssertTrue(app.staticTexts["After 1 minute"].exists)
        XCTAssertTrue(app.staticTexts["After 5 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 10 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 15 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 1 hour"].exists)

        app.staticTexts["After 15 minutes"].tap()
        navigator.goto(PasscodeSettings)
        let table = app.tables["AuthenticationManager.settingsTableView"]
        waitForExistence(table.staticTexts["After 15 minutes"])

        // Since we set to 15 min, it shouldn't ask for password again, but it skips verification
        // only when timing isn't changed. (could be due to timer reset?)
        // For clarification, raised Bug 1325439
        navigator.goto(PasscodeIntervalSettings)
        navigator.goto(PasscodeSettings)
        waitForExistence(table.staticTexts["After 15 minutes"])
        navigator.performAction(Action.DisablePasscode)
    }

    func testEnteringLoginsUsingPasscode() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)

        // Enter login
        navigator.performAction(Action.UnlockLoginsSettings)
        waitForExistence(app.tables["Login List"])
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabScreen)
        // Trying again should display passcode screen since we've set the interval to be immediately.
        navigator.goto(LockedLoginsSettings)
        waitForExistence(app.navigationBars["Enter Passcode"], timeout: 3)
        app.buttons["Cancel"].tap()
        navigator.nowAt(SettingsScreen)
        navigator.goto(PasscodeSettings)
        navigator.performAction(Action.DisablePasscode)
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)
        setInterval("After 5 minutes")

        // Now we've changed the timeout, we should prompt next time for passcode.
        navigator.performAction(Action.UnlockLoginsSettings)
        waitForExistence(app.tables["Login List"])

        // Trying again should not display the passcode screen since the interval is 5 minutes
        navigator.goto(SettingsScreen)
        navigator.goto(LockedLoginsSettings)
        waitForExistence(app.tables["Login List"])

        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)

        navigator.goto(PasscodeSettings)
        waitForExistence(app.staticTexts["After 5 minutes"])
        navigator.performAction(Action.DisablePasscode)
    }

    func testEnteringLoginsWithNoPasscode() {
        // It is disabled
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(PasscodeSettings)
        waitForExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])

        navigator.goto(LoginsSettings)
        waitForExistence(app.tables["Login List"])
    }

    func testWrongPasscodeDisplaysAttemptsAndMaxError() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)
        setInterval("After 5 minutes")

        // Enter wrong passcode
        navigator.goto(LockedLoginsSettings)
        waitForExistence(app.navigationBars["Enter Passcode"])

        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        waitForExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        navigator.nowAt(LockedLoginsSettings)
        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        waitForExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        navigator.nowAt(LockedLoginsSettings)
        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        waitForExistence(app.staticTexts["Maximum attempts reached. Please try again later."])
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)

        // Enter wrong passcode on Logins
        navigator.goto(LockedLoginsSettings)
        waitForExistence(app.navigationBars["Enter Passcode"])

        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        waitForExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        app.buttons["Cancel"].tap()

        // Go back to Passcode, and enter a wrong passcode, notice the error count
        navigator.goto(PasscodeSettings)
        userState.passcode = "222222"
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)

        waitForExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        app.buttons["Cancel"].tap()

        userState.passcode = "111111"
        navigator.nowAt(PasscodeSettings)
        navigator.performAction(Action.DisablePasscode)
        waitForExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testChangedPasswordMustBeNew() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)
        userState.newPasscode = "111111"

        navigator.performAction(Action.ChangePasscode)
        waitForExistence(app.staticTexts["New passcode must be different than existing code."])
        app.navigationBars["Change Passcode"].buttons["Cancel"].tap()

        navigator.performAction(Action.DisablePasscode)
        waitForExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testPasscodesMustMatchWhenCreating() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscodeTypeOnce)
        waitForExistence(app.staticTexts["Re-enter passcode"])

        // Enter a passcode that does not match
        userState.newPasscode = "333333"
        navigator.performAction(Action.SetPasscodeTypeOnce)
        waitForExistence(app.staticTexts["Passcodes didn’t match. Try again."])
        waitForExistence(app.staticTexts["Enter a passcode"])
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)
        XCTAssertTrue(app.staticTexts["Immediately"].exists)

        navigator.performAction(Action.DisablePasscodeTypeIncorrectPasscode)
        waitForExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])

        navigator.performAction(Action.DisablePasscode)
        waitForExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testChangingIntervalResetsValidationTimer() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SetPasscode)

        // Enter login, since the default is 'set immediately,' it will ask for passcode
        navigator.performAction(Action.UnlockLoginsSettings)
        waitForExistence(app.tables["Login List"])

        // Change it to 15 minutes
        navigator.goto(PasscodeSettings)
        setInterval("After 15 minutes")

        // Enter login, since the interval is reset, it will ask for password again
        navigator.goto(LockedLoginsSettings)
        waitForExistence(app.navigationBars["Enter Passcode"])
        navigator.performAction(Action.UnlockLoginsSettings)
    }

    func testBasicHTTPAuthenticationPromptVisible() {
        waitForExistence(app.textFields["url"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.openURL(testBasicHTTPAuthURL)

        waitForExistence(app.staticTexts["Authentication required"], timeout: 5)
        waitForExistence(app.staticTexts["A username and password are being requested by jigsaw.w3.org. The site says: test"])

        let placeholderValueUsername = app.alerts.textFields.element(boundBy: 0).value as! String
        let placeholderValuePassword = app.alerts.secureTextFields.element(boundBy: 0).value as! String

        XCTAssertEqual(placeholderValueUsername, "Username")
        XCTAssertEqual(placeholderValuePassword, "Password")

        waitForExistence(app.alerts.buttons["Cancel"])
        waitForExistence(app.alerts.buttons["Log in"])

        // Skip login due to HTTP Basic Authentication crash in #5757

        // Dismiss authentication prompt
        app.alerts.buttons["Cancel"].tap()
        waitForNoExistence(app.alerts.buttons["Cancel"], timeoutValue:5)
    }
}
