@testable import App
import XCTVapor
import AddaSharedModels

class AppTests: XCTestCase {
    var app: Application!
    public var token = """
    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdGF0dXMiOjAsImV4cCI6MTY3MDMzMTU1OSwiaWF0IjoxNjYxNzc3OTU5LCJ1c2VySWQiOiI1ZmFiYjFlYmFhNWY1Nzc0Y2NmZTQ4YzMiLCJwaG9uZU51bWJlciI6Iis3OTIxODgyMTIxNyJ9.OC2yQxD7clzY1Hz2AQG1peBtcTfgZUwUvVFpPbt6cDU
    """
    
    func createTestApp() throws -> Application {
        app = Application(.testing)
        try configure(app)
        app.databases.reinitialize()
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        return app
    }
}
