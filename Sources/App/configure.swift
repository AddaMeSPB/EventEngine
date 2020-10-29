import Fluent
import FluentMongoDriver
import Vapor
import APNS
import JWTKit

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder

    var connectionString: String
    switch app.environment {
    case .production:
        guard let mongoURL = Environment.get("MONGO_DB_PRO") else {
            fatalError("No MongoDB connection string is available in .env_production")
        }
        connectionString = mongoURL
    case .development:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("No MongoDB connection string is available in .env_development")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
    default:
        guard let mongoURL = Environment.get("MONGO_DB_DEV") else {
            fatalError("No MongoDB connection string is available in .env_development")
        }
        connectionString = mongoURL
        print("mongoURL: \(connectionString)")
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
    if app.environment == .production {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 9090
    } else if app.environment == .development {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 9090
    }

    try routes(app)

}
