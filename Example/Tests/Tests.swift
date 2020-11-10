import Logsene
import XCTest

class LogseneTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        XCTAssertTrue(true)
    }
    
    func testLogsene() {
        try! LogseneInit("du72esds-s21s-xws2-2sww-sas1dwsa12sa", type: "example")
        LLogInfo("Sample message")
        XCTAssertTrue(true)
    }
}
