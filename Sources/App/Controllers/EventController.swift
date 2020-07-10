//
//  EventController.swift
//  
//
//  Created by Alif on 9/7/20.
//

import Vapor
import MongoKitten
import JWT

extension EventController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("create", use: create)
    }


}

final class EventController {
    private func create(_ req: Request) throws -> EventLoopFuture<Event> {
        
    }

}
