//
//  Events.swift
//  
//
//  Created by Alif on 9/7/20.
//

//enum Categories: String {
//    case Found,
//    Take off
//    Pass
//    Acquaintances
//    Work
//    Question
//    News
//    Services
//    Event
//    Meal
//    The Council
//    Children
//    Shop
//    Mood
//    Sport
//    Sell off
//    Accomplishment
//    Ugliness
//    Driver
//    Discounts
//    Warning
//    Health
//    Animals
//    Weekend
//    Education
//    Walker
//    Give away
//    Life hack
//    Looking for a company
//    Realty
//    Charity
//    Accident
//    Weather
//    I will buy
//    Accept as a gift
//}

import Vapor
import Fluent
import FluentMongoDriver

final class Events: Model, Content {
    static var schema = "events"

    init() {}

    @ID(custom: "id") var id: ObjectId?
    @Field(key: "conversations_id") var conversationsId: ObjectId?
    @Field(key: "name") var name: String
    @OptionalField(key: "image_url") var imageUrl: String?
    @Field(key: "duration") var duration: Int
    @Field(key: "categories") var categories: String
    @Field(key: "geo_id") var geoId: ObjectId?
    @Field(key: "owner_id") var ownerID: ObjectId?

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, duration
        case imageUrl = "image_url"
        case conversationsId = "conversations_id"
        case geo_id = "geo_id"
        case owner_id = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(
        conversationsId: ObjectId? = nil,
        name: String,
        imageUrl: String? = nil,
        duration: Int,
        geoId: ObjectId? = nil,
        categories: String,
        ownerID: ObjectId? = nil
    ) {
        self.conversationsId = conversationsId
        self.name = name
        self.imageUrl = imageUrl
        self.duration = duration
        self.categories = categories
        self.geoId = geoId
        self.ownerID = ownerID
    }

    var response: Res {
        .init(self)
    }

    struct Res {
        var id: String
        var conversations_id: ObjectId?
        var name: String
        var image_url: String?
        var duration: Int
        var categories: String
        var geo_id: ObjectId?
        var owner_id: ObjectId?
        var createdAt: Date?
        var updatedAt: Date?
        var deletedAt: Date?

        init(_ event: Events) {
            
            if event.id == nil {
                self.id = ObjectId().hexString
            } else {
                self.id = event.id!.hexString
            }

            self.conversations_id = event.conversationsId
            self.name = event.name
            self.image_url = event.imageUrl
            self.duration = event.duration
            self.categories = event.categories
            self.geo_id = event.geoId
            self.owner_id = event.ownerID
            self.createdAt = event.createdAt
            self.updatedAt = event.updatedAt
            self.deletedAt = event.deletedAt
        }

    }
}

