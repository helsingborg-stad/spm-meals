import XCTest
@testable import Meals
import Combine

var cancellables = Set<AnyCancellable>()
final class MealsTests: XCTestCase {
    func testSkolmatenFirstSchool() {
        let expectation = XCTestExpectation(description: "Fetch schools")
        
        Skolmaten.first(county: "skåne", municipality: "helsingborg", school: "råå").sink { compl in
            switch compl {
            case .failure(let error):
                XCTFail(error.localizedDescription)
                debugPrint(error)
                expectation.fulfill()
            case .finished:
                debugPrint("finished resources")
            }
        } receiveValue: { school in
            XCTAssert(school.title.contains("Råå förskola"))
            expectation.fulfill()
        }.store(in: &cancellables)
        wait(for: [expectation], timeout: 20.0)
    }
}
