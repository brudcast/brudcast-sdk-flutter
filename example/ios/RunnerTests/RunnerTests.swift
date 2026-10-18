import XCTest
import Brudcast
@testable import brudcast_flutter

/// The core plugin's action router: actions held for a Dart handler after launch, and the default
/// once the window ends.
final class ActionRouterTests: XCTestCase {
    private final class RecordingTarget: ActionRouterTarget {
        let answer: BrudcastActionResult
        var received: [BrudcastAction] = []

        init(answer: BrudcastActionResult) {
            self.answer = answer
        }

        func handle(_ action: BrudcastAction, decide: @escaping (BrudcastActionResult) -> Void) {
            received.append(action)
            decide(answer)
        }
    }

    private var now: TimeInterval = 0
    private var scheduled: [(at: TimeInterval, block: () -> Void)] = []
    private var installed: BrudcastAsyncActionHandler?
    private var defaults: [BrudcastAction] = []
    private var router: ActionRouter!

    private let tap = BrudcastAction(kind: .deeplink, value: "myapp://checkout", source: .push(messageId: "m1"))

    override func setUp() {
        super.setUp()
        router = ActionRouter(
            clock: { [unowned self] in self.now },
            schedule: { [unowned self] delay, block in self.scheduled.append((self.now + delay, block)) },
            install: { [unowned self] in self.installed = $0 },
            performDefault: { [unowned self] in self.defaults.append($0) }
        )
    }

    private func advance(to time: TimeInterval) {
        now = time
        let due = scheduled.filter { $0.at <= now }
        scheduled.removeAll { $0.at <= now }
        due.forEach { $0.block() }
    }

    private func route(_ action: BrudcastAction) -> BrudcastActionResult? {
        var result: BrudcastActionResult?
        installed?(action) { result = $0 }
        return result
    }

    func testHoldsALaunchTapUntilDartSetsAHandler() {
        router.engineAttached()
        XCTAssertEqual(route(tap), .handled)

        let target = RecordingTarget(answer: .handled)
        advance(to: 1)
        router.setTarget(target)

        XCTAssertEqual(target.received, [tap])
        XCTAssertTrue(defaults.isEmpty)
    }

    func testRunsTheDefaultWhenTheReplayedHandlerDeclines() {
        router.engineAttached()
        _ = route(tap)
        let target = RecordingTarget(answer: .useDefault)
        router.setTarget(target)

        XCTAssertEqual(defaults, [tap])
    }

    func testRunsTheDefaultForHeldTapsWhenTheWindowEnds() {
        router.engineAttached()
        _ = route(tap)
        advance(to: ActionRouter.holdInterval)

        XCTAssertEqual(defaults, [tap])
        XCTAssertNil(installed)
    }

    func testSendsActionsStraightToASetHandler() {
        router.engineAttached()
        let target = RecordingTarget(answer: .handled)
        router.setTarget(target)
        advance(to: ActionRouter.holdInterval)

        XCTAssertEqual(route(tap), .handled)
        XCTAssertEqual(target.received, [tap])
        XCTAssertNotNil(installed)
    }

    func testRemovesTheNativeHandlerWhenDartClearsItAfterTheWindow() {
        router.engineAttached()
        let target = RecordingTarget(answer: .handled)
        router.setTarget(target)
        advance(to: ActionRouter.holdInterval)
        router.clearTarget(target)

        XCTAssertNil(installed)
    }
}
