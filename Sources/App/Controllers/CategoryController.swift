//
//  File.swift
//  
//
//  Created by Saroar Khandoker on 17.07.2022.
//

import Vapor
import MongoKitten
import Fluent
import JWT
import AddaSharedModels

//extension CategoryController: RouteCollection {
//    func boot(routes: RoutesBuilder) throws {
//        routes.post(use: create)
//        routes.get(use: list)
//        routes.put(use: update)
//        routes.delete(":categoriesId", use: delete)
//    }
//}

//final class CategoryController {
//    func create(_ req: Request) async throws -> CategoryResponse {
//        if req.loggedIn == false { throw Abort(.unauthorized) }
//        let input = try req.content.decode(CreateCategory.self)
//        let category = Category(name: input.name)
//        try await category.save(on: req.db)
//        return category.response
//    }
//
//    func list(_ req: Request) async throws -> CategoriesResponse {
//        if req.loggedIn == false { throw Abort(.unauthorized) }
//        let categories = try await Category.query(on: req.db).all()
//        let response = categories.map { $0.response }
//        return CategoriesResponse(
//            categories: response,
//            url: .init(string: "http://127.0.0.1:9090/categories") ?? .empty
//        )
//    }
//
//    func update(_ req: Request) async throws -> CategoryResponse {
//        if req.loggedIn == false { throw Abort(.unauthorized) }
//        let originalCatrgory = try req.content.decode(Category.self)
//        guard
//            let id = originalCatrgory.id
//        else {
//            throw Abort(.notFound, reason: "no category id is missing")
//        }
//
//        let category = try await Category.query(on: req.db)
//            .filter(\.$id == id)
//            .first()
//            .unwrap(or: Abort(.notFound, reason: "No Category. found! by ID: \(id)"))
//            .get()
//
//        originalCatrgory.id = category.id
//        originalCatrgory.name = category.name
//        originalCatrgory._$id.exists = true
//        try await originalCatrgory.update(on: req.db)
//        return originalCatrgory.response
//    }
//
//    func delete(_ req: Request) async throws -> HTTPStatus {
//        if req.loggedIn == false { throw Abort(.unauthorized) }
//        guard let _id = req.parameters.get("\(AddaSharedModels.Category.schema)Id"), let id = ObjectId(_id) else {
//            throw Abort(.notFound)
//        }
//
//        let category = try await Category.find(id, on: req.db)
//            .unwrap(or: Abort(.notFound, reason: "Cant find Category by id: \(id) for delete"))
//            .get()
//        try await category.delete(force: true, on: req.db)
//        return HTTPStatus.ok
//    }
//
//}

public func categoriesHandler(request: Request, route: CategoriesRoute) async throws -> AsyncResponseEncodable {
    switch route {
    case .create:
//        if request.loggedIn == false { throw Abort(.unauthorized) }
        let input = try request.content.decode(CreateCategory.self)
        let category = Category(name: input.name)
        try await category.save(on: request.db)
        return category.response

    case .list:
//        if request.loggedIn == false { throw Abort(.unauthorized) }
        let categories = try await Category.query(on: request.db).all()
        let response = categories.map { $0.response }
        return CategoriesResponse(
            categories: response,
            url: request.application.router.url(for: .eventEngine(.categories(.list)))
        )
        
    case .update:
        if request.loggedIn == false { throw Abort(.unauthorized) }
        let originalCatrgory = try request.content.decode(Category.self)
        guard
            let id = originalCatrgory.id
        else {
            throw Abort(.notFound, reason: "no category id is missing")
        }
        
        let category = try await Category.query(on: request.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No Category. found! by ID: \(id)"))
            .get()
        
        originalCatrgory.id = category.id
        originalCatrgory.name = category.name
        originalCatrgory._$id.exists = true
        try await originalCatrgory.update(on: request.db)
        return originalCatrgory.response
        
    case .delete(id: let id):
        if request.loggedIn == false { throw Abort(.unauthorized) }
        guard let id = ObjectId(id) else {
            throw Abort(.notFound)
        }
        
        let category = try await Category.find(id, on: request.db)
            .unwrap(or: Abort(.notFound, reason: "Cant find Category by id: \(id) for delete"))
            .get()
        try await category.delete(force: true, on: request.db)
        return HTTPStatus.ok
    }
}
