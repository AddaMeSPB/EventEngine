import Vapor
import JWT

func routes(_ app: Application) throws {
    app.get { req in
        return "EventEngine works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.group("v1") { api in
        let events = api.grouped("events")
        let eventsAuth = events.grouped(JWTMiddleware())
        try eventsAuth.register(collection: EventController() )
    }
}
