//
//  EventApiTests.swift
//  
//
//  Created by Alif on 10/7/20.
//

@testable import App
import XCTVapor
import Fluent
import FluentMongoDriver

final class EventApiTests: AppTestCase {
    func testCreateEvent() throws {
        let app = try self.createTestApp()
        let token = try self.getToken()
        defer { app.shutdown() }

        let headers = HTTPHeaders([("Authorization", "Bearer \(token)")])

        struct EventInput: Content {
            var id: ObjectId?
            var conversationsId: ObjectId?
            var name: String
            var duration: Int
            var categories: String
            var geoId: ObjectId?
            var ownerID: ObjectId?
            var createdAt: Date?
            var updatedAt: Date?
            var deletedAt: Date?
        }


        let eventsBody = Events(conversationsId: ObjectId(), name: "Walk with son", duration: 9000, geoId: ObjectId(), categories: "sports", ownerID: ObjectId())
        try eventsBody.save(on: app.db)

        try app.test(.POST, "/v1/events", headers: headers, content: eventsBody) { res in
            XCTAssertEqual(res.status, .ok)
            let contentType = try XCTUnwrap(res.headers.contentType)
            XCTAssertEqual(contentType, .json)
            XCTAssertContent(Events.self, res) { content in
                    XCTAssertEqual(content.name, eventsBody.name)

            }
        }


    }
}
