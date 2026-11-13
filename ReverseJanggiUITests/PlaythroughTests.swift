import XCTest

/// 시뮬레이터에서 실제로 앱을 눌러 보며 주요 흐름을 확인하고 App Store용 스크린샷을 남긴다.
/// 스크린샷은 xcresult 첨부로 저장되어 ui-tests 워크플로가 아티팩트로 올린다.
final class PlaythroughTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        launch(language: "ko", locale: "ko_KR")
    }

    // MARK: - 도우미

    private func launch(language: String, locale: String) {
        app.terminate()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func button(containing text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func tapButton(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = button(containing: text)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "버튼 없음: \(text)", file: file, line: line)
        element.tap()
    }

    private func point(_ sq: Int) -> XCUIElement {
        app.descendants(matching: .any)["pt-\(sq)"]
    }

    /// 내 기물(라벨이 "한 …" / "Han …"로 시작하는 교차점)
    private func myPieces(sidePrefix: String) -> [XCUIElement] {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'pt-' AND label BEGINSWITH %@", sidePrefix + " ")
        return app.descendants(matching: .any).matching(predicate).allElementsBoundByIndex
    }

    private func targets(forcedOnly: Bool) -> XCUIElementQuery {
        let values = forcedOnly ? ["강제 캡처", "Forced capture"] : ["강제 캡처", "Forced capture", "갈 수 있음", "Can move here"]
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'pt-' AND value IN %@", values)
        return app.descendants(matching: .any).matching(predicate)
    }

    /// 움직일 수 있는 내 기물을 하나 골라 선택한다. 강제 캡처가 있으면 그 기물을 고른다.
    @discardableResult
    private func selectMovablePiece(sidePrefix: String, timeout: TimeInterval = 15) -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            var fallback: XCUIElement?
            for piece in myPieces(sidePrefix: sidePrefix) {
                piece.tap()
                if targets(forcedOnly: true).firstMatch.exists { return true }
                if fallback == nil, targets(forcedOnly: false).firstMatch.exists { fallback = piece }
            }
            if let fallback {
                fallback.tap()
                if targets(forcedOnly: false).firstMatch.exists { return true }
            }
            usleep(500_000) // 컴퓨터가 생각 중
        }
        return false
    }

    /// 한 수 둔다. 강제 캡처 대상이 있으면 그쪽, 아니면 갈 수 있는 첫 자리.
    private func playOneMove(sidePrefix: String = "한") {
        XCTAssertTrue(selectMovablePiece(sidePrefix: sidePrefix), "움직일 수 있는 기물이 없습니다")
        let forced = targets(forcedOnly: true).firstMatch
        (forced.exists ? forced : targets(forcedOnly: false).firstMatch).tap()
    }

    private var isGameOver: Bool { button(containing: "한 판 더").exists }

    // MARK: - 시나리오

    func test1_HomeAndRules() {
        XCTAssertTrue(app.staticTexts["리버스 장기"].waitForExistence(timeout: 5))
        shot("01 홈")

        tapButton("규칙 한 장 보기")
        XCTAssertTrue(app.staticTexts["규칙 한 장"].waitForExistence(timeout: 5))
        shot("02 규칙")
    }

    func test2_VsComputer() {
        tapButton("보통")
        tapButton("컴퓨터 대전")
        XCTAssertTrue(point(0).waitForExistence(timeout: 5))

        XCTAssertTrue(selectMovablePiece(sidePrefix: "한"))
        shot("03 대국 시작 (갈 수 있는 자리 표시)")
        targets(forcedOnly: false).firstMatch.tap()

        var forcedShot = false
        for move in 0..<16 where !isGameOver {
            playOneMove()
            if move == 5 { shot("04 대국 중반") }
            // 강제 캡처 상황이 오면 선택한 상태로 한 장
            if !forcedShot, app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '강제 캡처'")).firstMatch.waitForExistence(timeout: 4) {
                if selectMovablePiece(sidePrefix: "한"), targets(forcedOnly: true).firstMatch.exists {
                    shot("05 강제 캡처")
                    forcedShot = true
                }
            }
        }
        shot("06 대국 후반")

        tapButton("무르기")
        shot("07 무르기 후")
    }

    func test3_Tutorial() {
        tapButton("배우기")
        let start = app.buttons["시작"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        shot("08 배우기 소개")
        start.tap()

        // 레슨 1: 아무 수나
        tapButton("미션 시작")
        playOneMove()
        XCTAssertTrue(app.staticTexts["정답입니다."].waitForExistence(timeout: 5))
        tapButton("다음 레슨")

        // 레슨 2: 병(3,5)으로 졸(3,4)을 잡는 수가 유일한 합법수
        tapButton("미션 시작")
        point(48).tap()
        XCTAssertEqual(point(39).value as? String, "강제 캡처")
        shot("09 미션: 잡을 수 있으면 잡아야 해요")
        point(39).tap()
        XCTAssertTrue(app.staticTexts["정답입니다."].waitForExistence(timeout: 5))
        shot("10 미션 정답")
    }

    func test4_TwoPlayer() {
        tapButton("함께 하기")
        XCTAssertTrue(point(0).waitForExistence(timeout: 5))
        for index in 0..<6 {
            playOneMove(sidePrefix: index.isMultiple(of: 2) ? "한" : "초")
        }
        shot("11 함께 하기")
    }

    func test5_English() {
        launch(language: "en", locale: "en_US")
        XCTAssertTrue(app.staticTexts["Reverse Janggi"].waitForExistence(timeout: 5))
        shot("12 English home")

        tapButton("Normal")
        tapButton("vs Computer")
        XCTAssertTrue(point(0).waitForExistence(timeout: 5))
        for _ in 0..<4 { playOneMove(sidePrefix: "Han") }
        XCTAssertTrue(selectMovablePiece(sidePrefix: "Han"))
        shot("13 English game")
    }
}
