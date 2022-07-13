import Fluent
import FluentMongoDriver
import Vapor
import APNS
import JWTKit

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

    // Configure custom hostname.
    switch app.environment {
    case .production:
      app.http.server.configuration.hostname = "0.0.0.0"
      app.http.server.configuration.port = 9090
    case .staging:
      app.http.server.configuration.port = 9091
      app.http.server.configuration.hostname = "0.0.0.0"
    case .development:
      app.http.server.configuration.port = 9090
      app.http.server.configuration.hostname = "0.0.0.0"
    case .testing:
      app.http.server.configuration.port = 9092
      app.http.server.configuration.hostname = "0.0.0.0"
    default:
      app.http.server.configuration.port = 9090
      app.http.server.configuration.hostname = "0.0.0.0"
    }

    try routes(app)

}
