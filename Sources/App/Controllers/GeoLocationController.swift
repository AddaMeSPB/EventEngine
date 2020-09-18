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

extension GeoLocationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post(use: create)
        routes.get(use: readAll)
        routes.get(":geo_locations_id", use: read)
        routes.put(use: update)
        routes.delete(":geo_locations_id", use: delete)
    }
}

class GeoLocationController {
    private func create(_ req: Request) throws -> EventLoopFuture<GeoLocation.Res> {
        //            if req.loggedIn == false {
        //                throw Abort(.unauthorized)
        //            }
        let content = try req.content.decode(GeoLocationData.self)
        let geoLocation = GeoLocation(addressName: content.addressName, coordinates: content.coordinates, geoType: content.type, eventID: content.eventID)
        return geoLocation.save(on: req.db).map { geoLocation.response }
    }
    
    private func readAll(_ req: Request) throws -> EventLoopFuture<[GeoLocation.Res]>  {
        //            if req.loggedIn == false {
        //                throw Abort(.unauthorized)
        //            }
        
        return GeoLocation.query(on: req.db)
            //.filter(\.$ownerID == req.payload.userId)
            .all()
            .map { $0.map { $0.response } }
    }
    
    private func read(_ req: Request) throws -> EventLoopFuture<GeoLocation> {
//        if req.loggedIn == false {
//            throw Abort(.unauthorized)
//        }
        
        guard let _id = req.parameters.get("\(GeoLocation.schema)_id"), let id = ObjectId(_id) else {
            return req.eventLoop.makeFailedFuture( Abort(.notFound, reason: "GeoLocation id missing") )
        }
        
        return GeoLocation.query(on: req.db)
            .filter(\.$id == id)
            //.filter(\.$ownerID == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No GeoLocations. found!"))
        
    }
    
    private func update(_ req: Request) throws -> EventLoopFuture<GeoLocation> {
        //            if req.loggedIn == false {
        //                throw Abort(.unauthorized)
        //            }
        
        let origianlGeoLocations = try req.content.decode(GeoLocationData.self)
        
        guard let id = origianlGeoLocations.id else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "GeoLocation id missing"))
        }
        
        // only owner can update
        return GeoLocation.query(on: req.db)
            .filter(\.$id == id)
            //.filter(\.$ownerID == req.payload.userId)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No GeoLocations. found!"))
            .flatMap { geoLocation in
                geoLocation.addressName = origianlGeoLocations.addressName
                geoLocation.coordinates = origianlGeoLocations.coordinates
                geoLocation.$event.id = origianlGeoLocations.eventID
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


struct GeoLocationData: Content {
    var id: ObjectId?
    var addressName: String
    var type: GeoType
    var coordinates: [Double]
    var eventID: ObjectId
    
    enum CodingKeys: String, CodingKey {
        case id, type, coordinates
        case eventID = "event_id"
        case addressName = "address_name"
    }
}

//{
//    "address_name": "улица Вавиловых, 8Дк1",
//    "type": "Point",
//    "coordinates": [60.020532, 30.388016],
//    "event_id": "5eaaadf1bcf84b0f97a55b84"
//}
