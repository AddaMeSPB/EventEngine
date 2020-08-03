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
        routes.post(use: create)
        routes.get(use: readAll)
        routes.get(":events_id", use: read)
        routes.put(":events_id", use: update)
        routes.delete(":events_id", use: delete)
    }
}

final class EventController {

    private func create(_ req: Request) throws -> EventLoopFuture<Events> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }
        let content = try req.content.decode(Events.self)
        content.ownerID = req.payload.userId
        //Events.init(conversationsId: ObjectId(), name: "Walk with son", duration: 36000, geoId: ObjectId(), categories: "sports", ownerID: req.payload.userId)
        return content.save(on: req.db).map { content }

        // version 2
//        let collection = req.mongoDB[Events.schema]
//        let content = try req.content.decode(Events.self)
//        let event = Events(name: content.name, ownerID: ObjectId())
//        return collection.insertEncoded(event).map { _ in event }
    }

    private func readAll(_ req: Request) throws -> EventLoopFuture<[Events]>  {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        return Events.query(on: req.db)
            .filter(\.$ownerID == req.payload.userId)
            .all().map { $0 }
    }

    private func read(_ req: Request) throws -> EventLoopFuture<Events> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        guard let _id = req.parameters.get("\(Events.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        return Events.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$ownerID == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Events. found!"))

    }

    private func update(_ req: Request) throws -> EventLoopFuture<Events> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        let origianlEvents = try req.content.decode(Events.self)

        guard let _id = req.parameters.get("\(Events.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        // only owner can delete
        return Events.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$ownerID == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Events. found!"))
            .flatMap { event in
                origianlEvents.id = event.id
                origianlEvents._$id.exists = true
                return origianlEvents.update(on: req.db).map { origianlEvents }

        // anyone can delete if he know id
//        return Events.find(id, on: req.db)
//            .unwrap(or: Abort(.notFound))
//            //.filter(\.$ownerID == req.payload.userId)
//            .flatMap { event in
//                origianlEvents.id = event.id
//                origianlEvents._$id.exists = true
//                return origianlEvents.update(on: req.db).map { origianlEvents }
        }
    }

    private func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        guard let _id = req.parameters.get("\(Events.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        return Events.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$ownerID == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Events. found!"))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }

}
