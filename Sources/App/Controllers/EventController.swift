//
//  EventController.swift
//  
//
//  Created by Alif on 9/7/20.
//

import Vapor
import MongoKitten
import Fluent
import JWT

extension EventController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("", use: create)
    }
}

final class EventController {
    private func create(_ req: Request) throws -> EventLoopFuture<Events> {
        var content = try req.content.decode(Events.self)
        //content.ownerID = req.payload.userId

        let event = Events(name: content.name, ownerID: ObjectId()) // req.payload.userId
        return event.save(on: req.db).map { event }

        // version 2
//        let collection = req.mongoDB[Events.schema]
//        let content = try req.content.decode(Events.self)
//        let event = Events(name: content.name, ownerID: ObjectId())
//        return collection.insertEncoded(event).map { _ in event }
    }
}
