import Vapor
import JWT
import VaporRouting
import AddaSharedModels

func routes(_ app: Application) throws {
    app.get { req in
        return "EventEngine works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

//    try app.group("v1") { api in
//        let events = api.grouped("events")
//        let eventsAuth = events.grouped(JWTMiddleware())
//        try eventsAuth.register(collection: EventController() )
//    }
}


public func siteHandler(
    request: Request,
    route: SiteRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .aboutUs:
        return [String: String]()
    case .contactUs:
        return [String: String]()
    case .home:
        return [String: String]()
    case .eventEngine(let route):
        return try await eventEngineHandler(request: request, route: route)
    }
}

public func eventEngineHandler(
    request: Request,
    route: EventEngineRoute
) async throws -> AsyncResponseEncodable {
    switch route {
    case .categories(let route):
        return try await categoriesHandler(request: request, route: route)
    case let .events(route):
        return try await eventsHandler(request: request, route: route)
    }
}
