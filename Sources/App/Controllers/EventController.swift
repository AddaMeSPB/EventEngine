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
import AddaSharedModels

//extension EventController: RouteCollection {
//    func boot(routes: RoutesBuilder) throws {
//        routes.post(use: create)
//        routes.get(use: readAll)
//        routes.get("my", use: readOwnerEvents)
//        routes.put(use: update)
//        routes.delete(":eventsId", use: delete)
//    }
//}
//
//final class EventController {
//
//    private func create(_ req: Request) async throws -> EventResponse {
//        
//        if req.loggedIn == false { throw Abort(.unauthorized) }
//        
//        let content = try req.content.decode(EventInput.self)
//        let ownerID = req.payload.userId
//        
//        let conversation = Conversation(title: content.name, type: .group)
//        try await conversation.save(on: req.db)
//        
//        let owner = try await User.find(ownerID, on: req.db)
//            .unwrap(or: Abort(.notFound, reason: "Cant find member or admin by userID \(ownerID)") )
//            .get()
//        
//        try await conversation.$admins.attach(owner, method: .ifNotExists, on: req.db)
//        try await conversation.$members.attach(owner, method: .ifNotExists, on: req.db)
//        
//        guard let conversationsID = conversation.id else {
//            throw Abort(.notFound, reason: "missing conversation id")
//        }
//        
//        let categoriesID = content.categoriesId
//        let data = Event(content: content, ownerID: ownerID, conversationsID: conversationsID, categoriesID: categoriesID)
//        try await data.save(on: req.db)
//        
//        return data.response.recreateEventWithSwapCoordinatesForMongoDB
//    }
//
//    private func readAll(_ req: Request) throws -> EventLoopFuture<EventPage> {
//
//      if req.loggedIn == false { throw Abort(.unauthorized) }
//      let page = try req.query.decode(EventPageRequest.self)
//      let skipItems = page.per * (page.page - 1)
//
//      // The equatorial radius of the Earth is
//      // approximately 3,963.2 miles or 6,378.1 kilometers.
//
//      let maxDistanceInMiles = Double(page.distance)
//
//      let events = req.mongoDB[Event.schema]
//
//      let numberOfItems = events
//        .aggregate([.
//          geoNear(
//            longitude: page.long,
//            latitude: page.lat,
//            distanceField: "distance",
//            spherical: true,
//            maxDistance: maxDistanceInMiles
//          )]
//        ).count()
//
//      let eventsPipeline = events
//        .aggregate([.
//          geoNear(
//            longitude: page.long,
//            latitude: page.lat,
//            distanceField: "distance",
//            spherical: true,
//            maxDistance: maxDistanceInMiles
//          ),
//          sort(["distance": .ascending, "createdAt": .descending]),
//          skip(skipItems),
//          limit(page.per)
//        ])
//
//      return numberOfItems.flatMap { count -> EventLoopFuture<EventPage> in
//        return eventsPipeline.decode(EventResponse.self)
//          .allResults()
//          .map { results in
//            let newResults = results.map { $0.recreateEventWithSwapCoordinatesForMongoDB }
//            let meta = PageMetadata(page: page.page, per: page.per, total: count)
//            let page = EventPage(items: newResults, metadata: meta)
//            return page
//          }
//        }
//      }
//
//    private func readOwnerEvents(_ req: Request) async throws -> Page<EventResponse> {
//        if req.loggedIn == false { throw Abort(.unauthorized) }
//        
//        let page = try await Event.query(on: req.db)
//            .filter(\.$owner.$id == req.payload.userId)
//            .with(\.$conversation) {
//                $0.with(\.$admins).with(\.$members)
//            }
//            .sort(\.$createdAt, .descending)
//            .paginate(for: req)
//            .get()
//        
//            
//        return page.map { $0.response.recreateEventWithSwapCoordinatesForMongoDB }
//            
//    }
//
//    private func update(_ req: Request) async throws -> EventResponse {
//        if req.loggedIn == false {
//            throw Abort(.unauthorized)
//        }
//
//        let origianlEvents = try req.content.decode(Event.self)
//
//        guard let id = origianlEvents.id else {
//            throw Abort(.notFound, reason: "Event id missing for update")
//        }
//
//        guard let event = try await Event.query(on: req.db)
//            .filter(\.$id == id)
//            .filter(\.$owner.$id == req.payload.userId)
//            .first()
//            .get()
//        else {
//            throw Abort(.notFound, reason: "No Events. found! by ID: \(id) for update")
//        }
//        
//        origianlEvents.id = event.id
//        origianlEvents._$id.exists = true
//        try await origianlEvents.update(on: req.db)
//        return origianlEvents.response
//
//    }
//
//    private func delete(_ req: Request) async throws -> HTTPStatus {
//        if req.loggedIn == false {
//            throw Abort(.unauthorized)
//        }
//
//        guard let _id = req.parameters.get("\(Event.schema)Id"), let id = ObjectId(_id) else {
//            throw Abort(.notFound, reason: "Event id not found for delete!")
//        }
//
//        let event = try await Event.query(on: req.db)
//            .filter(\.$id == id)
//            .filter(\.$owner.$id == req.payload.userId)
//            .first()
//            .unwrap(or: Abort(.notFound, reason: "No Events. found! by ID \(id)"))
//            .get()
//        
//          try await event.delete(on: req.db)
//        
//        return HTTPStatus.ok
//    }
//
//}

public func eventHander(
    request: Request,
    eventsId: String,
    origianlEvent: EventInput,
    route: EventRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .fetch:
        if request.loggedIn == false { throw Abort(.unauthorized) }

        guard let id = ObjectId(eventsId) else {
            throw Abort(.notFound, reason: "fetch: ObjectId cant be create with invalid string!")
        }

        guard let event = try await Event.query(on: request.db)
            .with(\.$conversation)
            .with(\.$category)
            .filter(\.$id == id)
            .first()
            .get()
        else {
           throw Abort(.notFound, reason: "No Events. found! by ID \(id)")
        }
        
        var eventRes = event.response
        eventRes.url = request.application.router.url(for: .eventEngine(.events(.event(eventRes.id!, .fetch))))
        return eventRes
        
//        EventResponse(
//            id: event.id, name: event.name, details: event.details, imageUrl: event.imageUrl,
//            duration: event.duration, distance: event.distance, isActive: event.isActive,
//            conversationsId: event.conversation.id, categoriesId: event.category.id,
//            addressName: event.addressName, sponsored: event.sponsored, overlay: event.overlay,
//            type: event.type, coordinates: [event.coordinates[1], event.coordinates[0]],
//            createdAt: event.createdAt, updatedAt: event.updatedAt, deletedAt: event.deletedAt,
//            url: request.application.router.url(for: .eventEngine(.events(.event(event.id, .fetch))))
//        )
        
    case .update:
        if request.loggedIn == false { throw Abort(.unauthorized) }

        guard let id = ObjectId(eventsId) else {
            throw Abort(.notFound, reason: "update: ObjectId cant be create with invalid string!")
        }

        guard let event = try await Event.query(on: request.db)
            .filter(\.$id == id)
            .filter(\.$owner.$id == request.payload.userId)
            .first()
            .get()
        else {
            throw Abort(.notFound, reason: "No Events. found! by ID: \(id) for update")
        }
        
        do {
            try await event.update(origianlEvent)
            try await event.update(on: request.db)
        } catch {
            throw Abort(.noContent, reason: "cant update event: \(error)")
        }
        
        return HTTPStatus.ok
        
    case .delete:
        if request.loggedIn == false { throw Abort(.unauthorized) }

        guard let id = ObjectId(eventsId) else {
            throw Abort(.notFound, reason: "delete: ObjectId cant be create with invalid string!")
        }

        guard let event = try await Event.query(on: request.db)
            .filter(\.$id == id)
            .filter(\.$owner.$id == request.payload.userId)
            .first()
            .get()
        else {
           throw Abort(.notFound, reason: "No Events. found! by ID \(id)")
        }
        
        try await event.delete(on: request.db)
        
        return HTTPStatus.ok
    }
}

public func eventsHandler(
    request: Request,
    route: EventsRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .create(let createEvent):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        
        let content = createEvent
        let ownerID = request.payload.userId
        
        let conversation = Conversation(title: content.name, type: .group)
        try await conversation.save(on: request.db)
        
        let owner = try await User.find(ownerID, on: request.db)
            .unwrap(or: Abort(.notFound, reason: "Cant find member or admin by userID \(ownerID)") )
            .get()
        
        try await conversation.$admins.attach(owner, method: .ifNotExists, on: request.db)
        try await conversation.$members.attach(owner, method: .ifNotExists, on: request.db)
        
        guard let conversationsID = conversation.id else {
            throw Abort(.notFound, reason: "missing conversation id")
        }
        
        let categoriesID = content.categoriesId
        
        let data = Event(content: content, ownerID: ownerID, conversationsID: conversationsID, categoriesID: categoriesID)
        try await data.save(on: request.db)
        
        return data.response.recreateEventWithSwapCoordinatesForMongoDB
    case let .event(eventsId, eventRoute):
        return try await eventHander(
            request: request,
            eventsId: eventsId,
            origianlEvent: EventInput.empty,
            route: eventRoute
        )
    case .list:
        if request.loggedIn == false { throw Abort(.unauthorized) }
        let page = try request.query.decode(EventPageRequest.self)
        let skipItems = page.per * (page.page - 1)

        // The equatorial radius of the Earth is
        // approximately 3,963.2 miles or 6,378.1 kilometers.

        let maxDistanceInMiles = Double(page.distance)

        let events = request.mongoDB[Event.schema]

        let numberOfItems = try await events
          .aggregate([.
            geoNear(
              longitude: page.long,
              latitude: page.lat,
              distanceField: "distance",
              spherical: true,
              maxDistance: maxDistanceInMiles
            )]
          ).count().get()

        let eventsPipeline = events
          .aggregate([.
            geoNear(
              longitude: page.long,
              latitude: page.lat,
              distanceField: "distance",
              spherical: true,
              maxDistance: maxDistanceInMiles
            ),
            sort(["distance": .ascending, "createdAt": .descending]),
            skip(skipItems),
            limit(page.per)
          ])

        
          let results = try await eventsPipeline.decode(EventResponse.self)
            .allResults()
            .get()
        
          let newResults = results.map { $0.recreateEventWithSwapCoordinatesForMongoDB }
          let meta = PageMetadata(page: page.page, per: page.per, total: numberOfItems)
          let eventPage = EventPage(items: newResults, metadata: meta)
          return eventPage

    case let .update(originalEvent, eventRoute):
        return try await eventHander(
            request: request,
            eventsId: "",
            origianlEvent: originalEvent,
            route: eventRoute
        )
        
    case let .delete(eventsId, eventRoute):
        return try await eventHander(
            request: request,
            eventsId: eventsId,
            origianlEvent: .empty,
            route: eventRoute
        )
    }
    
}
