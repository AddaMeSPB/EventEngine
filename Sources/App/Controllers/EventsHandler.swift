import Vapor
import MongoKitten
import Fluent
import JWT
import AddaSharedModels
import AppKit

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
        
        try await owner.$adminConversations.attach(conversation, method: .ifNotExists, on: request.db)
        try await owner.$memberConversaions.attach(conversation, method: .ifNotExists, on: request.db)
        
        guard let conversationsID = conversation.id else {
            throw Abort(.notFound, reason: "Missing conversation id")
        }
        
        let categoriesID = content.categoriesId
        
        let data = Event(content: content, ownerID: ownerID, conversationsID: conversationsID, categoriesID: categoriesID)
        try await data.save(on: request.db)
        return data.response.recreateEventWithSwapCoordinatesForMongoDB
        
    case let .find(eventsId, eventRoute):
        return try await eventHander(
            request: request,
            eventsId: eventsId,
            route: eventRoute
        )
    case .list:
       
        if request.loggedIn == false { throw Abort(.unauthorized) }
        let page = try request.query.decode(EventPageRequest.self)
        let skipItems = page.par * (page.page - 1)

        // The equatorial radius of the Earth is
        // approximately 3,963.2 miles or 6,378.1 kilometers.

        debugPrint(page)
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
            limit(page.par)
          ])

        
          let results = try await eventsPipeline.decode(EventOputput.self)
            .allResults()
            .get()
        
          let newResults = results.map { eventRes -> EventResponse in
              var withURLEvent = eventRes.recreateEventWithSwapCoordinatesForMongoDB
            _ = withURLEvent.url = request.application.router.url(
                for: .eventEngine(.events(.find(eventId: withURLEvent.id.hexString, EventRoute.find)))
              )
              return withURLEvent
          }
        
          let meta = Metadata(per: page.par, total: numberOfItems, page: page.page)
          let eventPage = EventsResponse(items: newResults, metadata: meta)
          return eventPage

    case let .update(eventInput):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        let eventDecode = eventInput
        let id = eventDecode.id
        let ownerID = request.payload.userId
        
        
        let event = try await Event.query(on: request.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Conversation. found! by id: \(id)"))
            .get()
        
        if event.owner.id != ownerID {
            throw Abort(.unauthorized, reason: "Only Owner can update this event!")
        }
        
        do {
//            try await event.update(eventInput)
            try await event.update(on: request.db)
        } catch {
            throw Abort(.noContent, reason: "cant update event: \(error)")
        }
          
//        conversation.id = conversation.id
//        conversation._$id.exists = true
//        try await conversation.update(on: request.db)
//        return conversation
  
        return event.response
        
    case let .delete(eventsId, eventRoute):
        return try await eventHander(
            request: request,
            eventsId: eventsId,
            origianlEvent: .empty,
            route: eventRoute
        )
    }
    
}
