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
        
        let geoLocations = api.grouped("geo_locations")
        let geoLocationsAuth = geoLocations.grouped(JWTMiddleware())
        try geoLocations.register(collection: GeoLocationController())
    }
}
