import Fluent
import FluentMongoDriver
import Vapor
import APNS
import JWTKit
import VaporRouting
import AddaSharedModels

// Route
enum SiteRouterKey: StorageKey {
    typealias Value = AnyParserPrinter<URLRequestData, SiteRoute>
}

extension Application {
    var router: SiteRouterKey.Value {
        get {
            self.storage[SiteRouterKey.self]!
        }
        set {
            self.storage[SiteRouterKey.self] = newValue
        }
    }
}


// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder

    var connectionString: String
    
    debugPrint("\(app.environment)")
    debugPrint(Environment.get("MONGO_DB_\(app.environment.name.uppercased())_URL") as Any)
    
    switch app.environment {
    case .production:
        guard let mongoURL = Environment.get("MONGO_DB_PRO") else {
            fatalError("No MongoDB connection string is available in .env.production")
        }
        connectionString = mongoURL

    case .development:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("\(#line) No MongoDB connection string is available in .env.development")
        }
        connectionString = mongoURL
        print("\(#line) mongoURL: \(connectionString)")

    case .staging:
        guard let mongoURL = Environment.get("MONGO_DB_STAGING") else {
            fatalError("\(#line) No MongoDB connection string is available in .env.development")
        }
        connectionString = mongoURL
        print("\(#line) mongoURL: \(connectionString)")

    case .testing:
        guard let mongoURL = Environment.get("MONGO_DB_TEST") else {
            fatalError("\(#line) No MongoDB connection string is available in .env.development")
        }
        connectionString = mongoURL
        print("\(#line) mongoURL: \(connectionString)")

    default:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("No MongoDB connection string is available in .env.development")
        }
        connectionString = mongoURL
        print("\(#line) mongoURL: \(connectionString)")
    }

    try app.initializeMongoDB(connectionString: connectionString)
    try app.databases.use(.mongo(
        connectionString: connectionString
    ), as: .mongo)


    guard let jwksString = Environment.process.JWKS else {
        fatalError("No value was found at the given public key environment 'JWKS'")
    }
    try app.jwt.signers.use(jwksJSON: jwksString)

    // Encoder & Decoder
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    let host = "0.0.0.0"
    var port = 9090
    // Configure custom hostname.
    switch app.environment {
    case .production:
      app.http.server.configuration.hostname = "0.0.0.0"
      app.http.server.configuration.port = 9090
       port = 9090
    case .staging:
      app.http.server.configuration.port = 9091
      app.http.server.configuration.hostname = "0.0.0.0"
        port = 9091
    case .development:
      app.http.server.configuration.port = 9090
      app.http.server.configuration.hostname = "0.0.0.0"
        port = 9090
    case .testing:
      app.http.server.configuration.port = 9092
      app.http.server.configuration.hostname = "0.0.0.0"
        port = 9092
    default:
      app.http.server.configuration.port = 9090
      app.http.server.configuration.hostname = "0.0.0.0"
        port = 9090
    }

    try routes(app)
    let baseURL = "http://\(host):\(port)"
    
    app.router = router
        .baseURL(baseURL)
        .eraseToAnyParserPrinter()
    
    app.mount(app.router, use: siteHandler)

}
