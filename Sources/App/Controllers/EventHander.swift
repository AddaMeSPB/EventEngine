
import Vapor
import MongoKitten
import Fluent
import JWT
import AddaSharedModels

extension EventsResponse: Content {}

public func eventHander(
    request: Request,
    eventsId: String,
    origianlEvent: EventInput? = nil,
    route: EventRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .find:

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

        return event.response
        
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
