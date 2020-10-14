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
import AddaAPIGatewayModels

extension EventController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post(use: create)
        routes.get(use: readAll)
        routes.get("my", use: readOwnerEvents)
        routes.put(use: update)
        routes.delete(":events_id", use: delete)
    }
}

final class EventController {

    private func create(_ req: Request) throws -> EventLoopFuture<Event> {
        
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }
        
        let content = try req.content.decode(CUEvent.self)
        let ownerID = req.payload.userId

        let conversation = Conversation(title: content.name)
        return try conversation.save(on: req.db).flatMap { _ in
            conversation.addUser(userId: ownerID, req: req)
            
            guard let conversationID = conversation.id else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound))
            }
            
            let data = Event(name: content.name, imageUrl: content.imageUrl, duration: content.duration, categories: content.categories, isActive: content.isActive, ownerId: ownerID, conversationId: conversationID)
            return data.save(on: req.db).map { data }

        }
        
    }

    // EventLoopFuture<[Event]>
    private func readAll(_ req: Request) throws -> EventLoopFuture<Page<Event.Item>> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        return Event.query(on: req.db)
            .with(\.$owner)
            .with(\.$conversation)
            .with(\.$geolocations)
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
            .map { (event: Page<Event>) -> Page<Event.Item> in
                return event.map { $0.response }
            }

//        return Event.query(on: req.db)
//            .sort(\.$createdAt, .descending)
//            .paginate(for: req)
//            .map { (original: Page<Event>) -> Page<Event.Res> in
//                original.map { $0.response }
//            }

    }
    
//    func home(_ req: Request) throws -> EventLoopFuture<Page<RestaurantCategoryModel.Home>> {
//        guard let user = req.auth.get(UserModel.self) else { throw Abort(.unauthorized) }
//        return RestaurantCategoryModel.query(on: req.db)
//    .with(\.$restaurants).paginate(for: req)
//    .map { paginatedCateogries -> Page<RestaurantCategoryModel.Home> in
//          paginatedCateogries.map { category -> RestaurantCategoryModel.Home in
//            return .init(id: category.id?.uuidString ?? "NONE", title: category.title, restaurants: category.restaurants.map {
//              var listContent = $0.listContent
//              let xDist = user.longitude - $0.longitude
//              let yDist = user.latitude - $0.latitude
//              let distance = sqrt(xDist * xDist + yDist * yDist)
//              listContent.distance = "\(distance) km"
//              return listContent
//            })
//          }
//        }
//      }

    private func readOwnerEvents(_ req: Request) throws -> EventLoopFuture<[Event]> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }
        
        return Event.query(on: req.db)
            .filter(\.$owner.$id == req.payload.userId)
            .all()
    }

    private func update(_ req: Request) throws -> EventLoopFuture<Event> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }

        let origianlEvents = try req.content.decode(Event.self)

        guard let id = origianlEvents.id else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "Event id missing"))
        }

        // only owner can delete
        return Event.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$owner.$id == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Events. found! by ID: \(id)"))
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

        guard let _id = req.parameters.get("\(Event.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }

        return Event.query(on: req.db)
            .filter(\.$id == id)
            .filter(\.$owner.$id == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Events. found! by ID \(id)"))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }

}
