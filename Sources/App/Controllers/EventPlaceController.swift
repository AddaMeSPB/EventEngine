//
//  EventPlaceController.swift
//  
//
//  Created by Saroar Khandoker on 15.09.2020.
//

import Vapor
import MongoKitten
import Fluent
import JWT
import AddaAPIGatewayModels

extension EventPlaceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post(use: create)
        routes.get(use: readAll) // "users", ":users_id",
//        routes.get(":geolocationsId", use: read)
//        routes.put(":events_id", use: update)
//        routes.delete(":geolocationsId", use: delete)
    }
}

class EventPlaceController {
    private func create(_ req: Request) throws -> EventLoopFuture<EventPlace.Item> {
        if req.loggedIn == false { throw Abort(.unauthorized) }
        let data = try req.content.decode(EventPlace.Create.self)
      let content = EventPlace.init(addressName: data.addressName, geoType: data.type, coordinates: data.swapCoordinatesForMongoDB(), image: data.image, details: data.image, sponsored: data.sponsored, overlay: data.overlay, eventID: data.eventId)
        return content.save(on: req.db).map { content.response }
    }

    private func readAll(_ req: Request) throws -> EventLoopFuture<Page<EventPlace.Item>> {
        if req.loggedIn == false { throw Abort(.unauthorized) }
        
//        guard let _id = req.parameters.get("\(User.schema)_id"), let eventID = ObjectId(_id) else {
//            return req.eventLoop
//                .makeFailedFuture(Abort(.notFound, reason: "User id is not found!"))
//        }

        let db = req.mongoDB
        let geoLocations = db[EventPlace.schema]
        // db.categories.findOne( { _id: "MongoDB" } ).parent
//        let event: Document = [
//            "_id":
//        ]
//
//        let elemMatcher: Document = [
//            "user_id": req.payload.userId,
//            "role": Role.owner.rawValue
//        ]

          //{coordinates: {$geoWithin: { $centerSphere: [ [ -122.47884750366212, 37.80312504252575 ], 0.002060787442307114 ]}}}
      
        // get user cordinate and distanceField
        geoLocations.aggregate([.geoNear(longitude: -122.47884750366212, latitude: 37.80312504252575, distanceField: "0.002060787442307114", spherical: true)]).decode(EventPlace.self).allResults()
            .map { ePlaces in
              let events = ePlaces.map {
                $0.event
              }
              
              debugPrint(#line, events)
                //geoLocations.map { $0.response }
                //geoLocations.map { $0 }
            }
      
      
      return EventPlace.query(on: req.db)
//          .with(\.$event)
//          {
//              $0.with(\.$owner).with(\.$conversation)
//          }
          .sort(\.$createdAt, .descending)
          .paginate(for: req)
          .map { (original: Page<EventPlace>) -> Page<EventPlace.Item> in
              return original.map {
                  $0.response
              }
          }
    }
    
    private func update(_ req: Request) throws -> EventLoopFuture<EventPlace> {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        let origianlEventPlace = try req.content.decode(EventPlace.self)
        
        guard let id = origianlEventPlace.id else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "EventPlace id missing"))
        }
        
        // only owner can update
        return EventPlace.query(on: req.db)
            .filter(\.$id == id)
            //.filter(\.$event.id == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No EventPlace. found!"))
            .flatMap { eventPlace in
              eventPlace.addressName = origianlEventPlace.addressName
              eventPlace.coordinates = origianlEventPlace.coordinates
              eventPlace.$event.id = origianlEventPlace.event.id!
              eventPlace._$id.exists = true
                return eventPlace.update(on: req.db).map { eventPlace }
            }
    }
    
    private func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        //            if req.loggedIn == false {
        //                throw Abort(.unauthorized)
        //            }
        
        guard let _id = req.parameters.get("\(EventPlace.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "EventPlace id missing"))
        }
        
        // only owner can delete
        return EventPlace.query(on: req.db)
            .filter(\.$id == id)
            //.filter(\.$ownerID == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No EventPlace. found!"))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }
}

