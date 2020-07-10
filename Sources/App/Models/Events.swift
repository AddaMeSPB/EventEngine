//
//  Events.swift
//  
//
//  Created by Alif on 9/7/20.
//

import Vapor
import Fluent
import FluentMongoDriver

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

final class Events: Model, Content {
    static var schema = "events"

    init() {}

    @ID(custom: "id")
    var id: ObjectId?

    @Field(key: "conversations_id")
    var conversationsId: ObjectId?

    @Field(key: "name")
    var name: String

    @Field(key: "duration")
    var duration: Int

    @Field(key: "categories")
    var categories: String = "General"

    @Field(key: "geo_id")
    var geoId: ObjectId?
    
    @Field(key: "owner_id")
    var ownerID: ObjectId?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init(name: String, duration: Int, geoId: ObjectId?, categories: String, ownerID: ObjectId) {

        self.conversationsId = conversationsId
        self.name = name
        self.duration = duration
        self.categories = categories
        self.geoId = geoId
        self.ownerID = ownerID
    }
}
