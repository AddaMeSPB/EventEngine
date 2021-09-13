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
        routes.delete(":eventsId", use: delete)
    }
}

final class EventController {

    private func create(_ req: Request) throws -> EventLoopFuture<Event> {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        
        let content = try req.content.decode(CUEvent.self)
        let ownerID = req.payload.userId

        let conversation = Conversation(title: content.name, type: .group)
        return conversation.save(on: req.db).flatMap { _ in
            conversation.addUserAsAMemberAndAdmin(userId: ownerID, req: req)
            
            guard let conversationsID = conversation.id else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound))
            }
            
          let data = Event(content: content, ownerID: ownerID, conversationsID: conversationsID)
          return data.save(on: req.db).map { data }

        }
        
    }

    private func readAll(_ req: Request) throws -> EventLoopFuture<EventPage> {

      if req.loggedIn == false { throw Abort(.unauthorized) }
      let page = try req.query.decode(EventPageRequest.self)
      let skipItems = page.per * (page.page - 1)

      // The equatorial radius of the Earth is
      // approximately 3,963.2 miles or 6,378.1 kilometers.

      let maxDistanceInMiles = Double(page.distance)

      let events = req.mongoDB[Event.schema]

      let numberOfItems = events
        .aggregate([.
          geoNear(
            longitude: page.long,
            latitude: page.lat,
            distanceField: "distance",
            spherical: true,
            maxDistance: maxDistanceInMiles
          )]
        ).count()

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

      return numberOfItems.flatMap { count -> EventLoopFuture<EventPage> in
        return eventsPipeline.decode(Event.Item.self)
          .allResults()
          .map { results in
            let newResults = results.map { $0.recreateEventWithSwapCoordinatesForMongoDB }
            let meta = PageMetadata(page: page.page, per: page.per, total: count)
            let page = EventPage(items: newResults, metadata: meta)
            return page
          }
        }
      }

    private func readOwnerEvents(_ req: Request) throws -> EventLoopFuture<Page<Event.Item>> {
        if req.loggedIn == false {
            throw Abort(.unauthorized)
        }
        
        return Event.query(on: req.db)
            .filter(\.$owner.$id == req.payload.userId)
            .with(\.$conversation) {
                $0.with(\.$admins).with(\.$members)
            }
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
            .map { (event: Page<Event>) -> Page<Event.Item> in
              return event.map { $0.response.recreateEventWithSwapCoordinatesForMongoDB }
            }
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

        guard let _id = req.parameters.get("\(Event.schema)Id"), let id = ObjectId(_id) else {
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

public struct Item: Content {
  public init(_id: ObjectId? = nil, name: String, details: String? = nil, imageUrl: String? = nil, duration: Int, isActive: Bool, conversationsId: ObjectId, categories: String, addressName: String, sponsored: Bool? = nil, overlay: Bool? = nil, type: GeoType, coordinates: [Double], distance: Double? = nil, updatedAt: Date?, createdAt: Date?, deletedAt: Date?) {
    self._id = _id
    self.name = name
    self.details = details
    self.imageUrl = imageUrl
    self.duration = duration
    self.isActive = isActive
    self.conversationsId = conversationsId
    self.categories = categories
    self.addressName = addressName
    self.sponsored = sponsored
    self.overlay = overlay
    self.type = type
    self.coordinates = coordinates
    self.distance = distance
    self.updatedAt = updatedAt
    self.createdAt = createdAt
    self.deletedAt = deletedAt
  }

  public var recreateEventWithSwapCoordinatesForMongoDB: Item {
    .init(
      _id: _id, name: name, details: details, imageUrl: imageUrl,
      duration: duration, isActive: isActive, conversationsId: conversationsId,
      categories: categories, addressName: addressName, sponsored: sponsored,
      overlay: overlay, type: type, coordinates: swapCoordinatesForMongoDB(),
      distance: distance, updatedAt: updatedAt,
      createdAt: createdAt, deletedAt: deletedAt
    )
  }

  public var _id: ObjectId?
  public var name: String
  public var details: String?
  public var imageUrl: String?
  public var duration: Int
  public var isActive: Bool
  public var categories: String
  public var conversationsId: ObjectId

  // Place Information
  public var addressName: String
  public var sponsored: Bool?
  public var overlay: Bool?
  public var type: GeoType
  public var coordinates: [Double]
  public var distance: Double?
  public let updatedAt, createdAt, deletedAt: Date?

  public func swapCoordinatesForMongoDB() -> [Double] {
    return [coordinates[1], coordinates[0]]
  }
}
