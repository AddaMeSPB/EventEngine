//
//  GeoLocationController.swift
//  
//
//  Created by Saroar Khandoker on 15.09.2020.
//

import Vapor
import MongoKitten
import Fluent
import JWT
import AddaAPIGatewayModels

extension GeoLocationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post(use: create)
        routes.get(use: readAll) // "users", ":users_id",
//        routes.get(":geolocationsId", use: read)
//        routes.put(":events_id", use: update)
//        routes.delete(":geolocationsId", use: delete)
    }
}

class GeoLocationController {
    private func create(_ req: Request) throws -> EventLoopFuture<GeoLocation.Item> {
        if req.loggedIn == false { throw Abort(.unauthorized) }
        let data = try req.content.decode(GeoLocation.Create.self)
        let content = GeoLocation.init(addressName: data.addressName, coordinates: data.coordinates, geoType: data.type, eventID: data.eventId)
        return content.save(on: req.db).map { content.response }
    }

    private func readAll(_ req: Request) throws -> EventLoopFuture<Page<GeoLocation.Item>> {
        if req.loggedIn == false { throw Abort(.unauthorized) }
        
//        guard let _id = req.parameters.get("\(User.schema)_id"), let eventID = ObjectId(_id) else {
//            return req.eventLoop
//                .makeFailedFuture(Abort(.notFound, reason: "User id is not found!"))
//        }
        
        return GeoLocation.query(on: req.db)
            .with(\.$event) {
                $0.with(\.$owner).with(\.$conversation)
            }
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
            .map { (original: Page<GeoLocation>) -> Page<GeoLocation.Item> in
                return original.map {
                    $0.response
                }
            }

//        let db = req.mongoDB
//        let geoLocations = db[GeoLocation.schema]
//        // db.categories.findOne( { _id: "MongoDB" } ).parent
//        let event: Document = [
//            "_id":
//        ]
//
//        let elemMatcher: Document = [
//            "user_id": req.payload.userId,
//            "role": Role.owner.rawValue
//        ]
//
//        // get user cordinate and distanceField
//        return geoLocations
//            .aggregate([.geoNear(longitude: 30.382588544043315, latitude: 60.016162458854915, distanceField: "0.000019431548775687755", spherical: true)])
//            .decode(GeoLocation.self)
//            .allResults()
//            .map { geoLocations in
//                geoLocations.map {
//                    $0.event.id
//                }
//                //geoLocations.map { $0.response }
//                //geoLocations.map { $0 }
//            }
    }
    
    private func update(_ req: Request) throws -> EventLoopFuture<GeoLocation> {
        
        if req.loggedIn == false { throw Abort(.unauthorized) }
        let origianlGeoLocations = try req.content.decode(GeoLocation.self)
        
        guard let id = origianlGeoLocations.id else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "GeoLocation id missing"))
        }
        
        // only owner can update
        return GeoLocation.query(on: req.db)
            .filter(\.$id == id)
            //.filter(\.$event.id == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No GeoLocations. found!"))
            .flatMap { geoLocation in
                geoLocation.addressName = origianlGeoLocations.addressName
                geoLocation.coordinates = origianlGeoLocations.coordinates
                geoLocation.$event.id = origianlGeoLocations.event.id!
                geoLocation._$id.exists = true
                return geoLocation.update(on: req.db).map { geoLocation }
            }
    }
    
    private func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        //            if req.loggedIn == false {
        //                throw Abort(.unauthorized)
        //            }
        
        guard let _id = req.parameters.get("\(GeoLocation.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "GeoLocation id missing"))
        }
        
        // only owner can delete
        return GeoLocation.query(on: req.db)
            .filter(\.$id == id)
            //.filter(\.$ownerID == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No GeoLocations. found!"))
            .flatMap { $0.delete(on: req.db) }
            .map { .ok }
    }
}

