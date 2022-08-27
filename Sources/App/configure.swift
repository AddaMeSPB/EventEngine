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

public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder

    var connectionString: String = ""
    
    debugPrint("\(app.environment)")
    debugPrint(Environment.get("MONGO_DB_\(app.environment.name.uppercased())_URL") as Any)
    
    app.middleware.use(JWTMiddleware())
    
    app.setupDatabaseConnections(&connectionString)

    try app.initializeMongoDB(connectionString: connectionString)
    try app.databases.use(.mongo(
        connectionString: connectionString
    ), as: .mongo)
    
    // Add HMAC with SHA-256 signer.
    let jwtSecret = Environment.get("JWT_SECRET") ?? String.random(length: 64)
    app.jwt.signers.use(.hs256(key: jwtSecret))

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
    
    app.router = siteRouter
        .baseURL(baseURL)
        .eraseToAnyParserPrinter()
    
    app.mount(app.router, use: siteHandler)

}
