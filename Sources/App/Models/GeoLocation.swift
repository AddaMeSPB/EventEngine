//
//  GeoLocation.swift
//  
//
//  Created by Saroar Khandoker on 14.09.2020.
//

import Foundation
import Vapor
import Fluent
import FluentMongoDriver

final class GeoLocation: Model {
    static var schema = "geo_locations"

    init() {}
    
    init(id: ObjectId? = nil, addressName: String, coordinates: [Double], geoType: GeoType, eventID: Event.IDValue) {
        self.id = id
        self.addressName = addressName
        self.coordinates = coordinates
        self.geoType = geoType
        self.$event.id = eventID
    }

    @ID(custom: "id") var id: ObjectId?
    @Field(key: "address_name") var addressName: String
    @Field(key: "type") var geoType: GeoType
    @Field(key: "coordinates") var coordinates: [Double]
    @Parent(key: "eventID") var event: Event

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, coordinates
        case geoType = "geo_type"
        case addressName = "address_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

}

extension GeoLocation: Content {
    
    var response: Res {
       .init(self)
    }
    
    struct Res: Content {
        var id: String
        var eventID: ObjectId
        var addressName: String
        var geoType: GeoType
        var coordinates: [Double]
        var createdAt: Date?
        var updatedAt: Date?
        var deletedAt: Date?
        
        enum CodingKeys: String, CodingKey {
            case id, coordinates
            case eventID = "event_id"
            case geoType = "type"
            case addressName = "address_name"
        }

        init(_ geoLocation: GeoLocation) {

            if geoLocation.id == nil {
                self.id = ObjectId().hexString
            } else {
                self.id = geoLocation.id!.hexString
            }

            self.eventID = geoLocation.$event.id
            self.addressName = geoLocation.addressName
            self.geoType = geoLocation.geoType
            self.coordinates = geoLocation.coordinates
            self.createdAt = geoLocation.createdAt
            self.updatedAt = geoLocation.updatedAt
            self.deletedAt = geoLocation.deletedAt
        }

    }
}

enum GeoType: String {
    case Point
    case LineString
    case Polygon
    case MultiPoint
    case MultiLineString
    case MultiPolygon
    case GeometryCollection
}

extension GeoType: Encodable {}
extension GeoType: Decodable {}
