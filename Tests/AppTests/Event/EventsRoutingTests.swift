

@testable import App
import XCTVapor
import VaporRouting
import XCTest
import AddaSharedModels

final class EventsRoutingTests: AppTests {
    
    let eventsId = "63075da62eb59af5700f9065"
    let query: EventPageRequest = .init()
    
    func testListEvents() throws {
        app = try! createTestApp()
        debugPrint(#line, "\(query)")
        app.mount(siteRouter) { req, route in
            
            switch route {
            case .eventEngine(.events(.list(query: .init()))):
                return "findEvent"
            default:
                return Response(status: .badRequest)
            }
        }

        try app.customTest(.GET, port: nil, path: "v1/events", token: token, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let events = try response.content.decode(EventsResponse.self)
            XCTAssertNotNil(events.items[0].id)
        })
    }
    
    func testFindEvent() throws {
        app = try! createTestApp()
        
        app.mount(siteRouter) { [self] req, route in
            switch route {
            case .eventEngine(.events(.find(eventId: eventsId, .find))):
                return "findEvent"
            default:
                return Response(status: .badRequest)
            }
        }

        try app.customTest(.GET, port: nil, path: "v1/events/\(eventsId)", token: token, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let event = try response.content.decode(EventResponse.self)
            XCTAssertNotNil(event.id)
            XCTAssertEqual(event.name, "Awesone Test")
        })
    }
    
//    func testFindEvents() throws {
//        let app = Application(.testing)
//        defer { app.shutdown() }
//
//        app.mount(eventEngineRouter) { (req, route) in
//            switch route {
//
//            case .create(eventInput: let eventInput):
//                <#code#>
//            case .find(eventId: let eventId, _):
//                <#code#>
//            case .list:
//                <#code#>
//            case .update(eventInput: let eventInput, _):
//                <#code#>
//            case .delete(eventId: let eventId, _):
//                <#code#>
//
//            default:
//                return Response(status: .badRequest)
//            }
//        }
//
//
//        try app.test(.GET, "/episodes/42/comments?count=100") { response in
//            XCTAssertEqual(response.status, .ok)
//            try XCTAssertEqual(response.content.decode(String.self), "Comments")
//        }
//    }
//
//    func testUpdateEvents() throws {
//        let app = Application(.testing)
//        defer { app.shutdown() }
//
//        app.mount(eventEngineRouter) { (req, route) in
//            switch route {
//
//            case .create(eventInput: let eventInput):
//
//
//            case .find(eventId: let eventId, _):
//                <#code#>
//            case .list:
//                <#code#>
//            case .update(eventInput: let eventInput, _):
//                <#code#>
//            case .delete(eventId: let eventId, _):
//                <#code#>
//
//            default:
//                return Response(status: .badRequest)
//            }
//        }
//
//
//        try app.test(.GET, "/episodes/42/comments?count=100") { response in
//            XCTAssertEqual(response.status, .ok)
//            try XCTAssertEqual(response.content.decode(String.self), "Comments")
//        }
//    }
//
//    func testDeleteEvents() throws {
//        let app = Application(.testing)
//        defer { app.shutdown() }
//
//        app.mount(eventEngineRouter) { (req, route) in
//            switch route {
//
//            case .create(eventInput: let eventInput):
//                <#code#>
//            case .find(eventId: let eventId, _):
//                <#code#>
//            case .list:
//                <#code#>
//            case .update(eventInput: let eventInput, _):
//                <#code#>
//            case .delete(eventId: let eventId, _):
//                <#code#>
//
//            default:
//                return Response(status: .badRequest)
//            }
//        }
//
//
//        try app.test(.GET, "/episodes/42/comments?count=100") { response in
//            XCTAssertEqual(response.status, .ok)
//            try XCTAssertEqual(response.content.decode(String.self), "Comments")
//        }
//    }
}
