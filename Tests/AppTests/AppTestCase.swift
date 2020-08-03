//
//  AppTestCase.swift
//  
//
//  Created by Alif on 10/7/20.
//

@testable import App
import XCTVapor
import Fluent
import MongoKitten

extension XCTApplicationTester { @discardableResult public func test<T>(
    _ method: HTTPMethod,
    _ path: String,
    headers: HTTPHeaders = [:], content: T,
    afterResponse: (XCTHTTPResponse) throws -> () = { _ in } ) throws -> XCTApplicationTester where T: Content {
    try test(method, path, headers: headers, beforeRequest: { req in try req.content.encode(content)
    }, afterResponse: afterResponse) }
}

open class AppTestCase: XCTestCase  {

    let connectionString = Environment.get("MONGO_DB_DEV")!

    func createTestApp() throws -> Application {
        let app = Application(.testing)
        try configure(app)
        try app.databases.use(.mongo(connectionString: connectionString ), as: .mongo)
        try app.initializeMongoDB(connectionString: connectionString)
        return app
    }

    func getToken() throws -> String {
        struct UserLoginInput: Content {
            let phone_number: String
        }

        struct UserVerificationInput: Content {
            let phone_number: String
            let code: String
        }

        struct UserLoginResponse: Content {
            let phone_number: String
            let attempt_id: String
        }

        struct RefreshResponse: Content {
            var accessToken: String
            var refreshToken: String
        }

        struct UserResponse: Content {
            let id: ObjectId?
            let firstName, lastName: String?
            let phoneNumber: String
        }

        struct LoginResponse: Content {
            var access: RefreshResponse
            let user: UserResponse
        }

        let userBody = UserLoginInput(phone_number: "+79218821217")
        var token: String?

        let app = try createTestApp()

        try app.testable(method: .running(port: 8081))
            .test(.POST, "http://localhost:8081/auth/login", beforeRequest: { req in
                do {
                    try req.content.encode(userBody)
                } catch {
                    app.shutdown()
                }
        }, afterResponse: { res in XCTAssertContent(UserLoginResponse.self, res) { content in
                app.logger.critical("\(content.attempt_id)")
            }
        })

        let verifySms = UserVerificationInput(phone_number: "+79218821217", code: "336699")

        try app.testable(method: .running(port: 8081))
            .test(.POST, "http://localhost:8081/auth/verify_sms", beforeRequest: { req in try req.content.encode(verifySms)
            }, afterResponse: { res in XCTAssertContent(LoginResponse.self, res) { content in
                token = content.access.accessToken
                }
            })

        guard let t = token else {
            XCTFail("Login failed")
            throw Abort(.unauthorized)
        }

        return t
    }
}
