//
//  CarsEndPoint.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 2/20/24.
//

import Foundation

public enum CarsApi {
    case getAllCars
    case addNewCar(model: String, lengthMeters: Double, weightTons: Double, registryNumber: String)
    case updateCar(id: String, model: String, lengthMeters: Double, weightTons: Double, registryNumber: String)
    case deleteCar(id: String)
}

extension CarsApi: EndPointType {
    var environmentBaseURL: String {
        switch NetworkManager.environment {
        case .production: return "http://localhost:8080/cars/"
        }
    }
    
    var baseURL: URL {
        guard let url = URL(string: environmentBaseURL) else { fatalError("baseURL could not be configured.") }
        return url
    }
    
    var path: String {
        switch self {
        case .getAllCars:
            return "employee"
        case .addNewCar:
            return "employee"
        case .updateCar(let id, _, _, _, _):
            return "\(id)/employee"
        case .deleteCar(let id):
            return "\(id)/employee"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .getAllCars:
            return .get
        case .addNewCar:
            return .post
        case .updateCar:
            return .put
        case .deleteCar:
            return .delete
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .getAllCars:
            return .requestParametersAndHeaders(bodyParameters: nil, urlParameters: nil, additionHeaders: self.headers)
        case .addNewCar(let model, let lengthMeters, let weightTons, let registryNumber):
            return .requestParametersAndHeaders(bodyParameters: ["model": model, "lengthMeters": lengthMeters, "weightTons": weightTons, "registryNumber": registryNumber], urlParameters: nil, additionHeaders: self.headers)
        case .updateCar(_, let model, let lengthMeters, let weightTons, let registryNumber):
            return .requestParametersAndHeaders(bodyParameters: ["model": model, "lengthMeters": lengthMeters, "weightTons": weightTons, "registryNumber": registryNumber], urlParameters: nil, additionHeaders: self.headers)
        case .deleteCar:
            return .requestParametersAndHeaders(bodyParameters: nil, urlParameters: nil, additionHeaders: self.headers)
        }
    }
    
    var headers: HTTPHeaders? {
        return ["Authorization": "Bearer \(AuthManager.shared.getAccessToken() ?? "")"]
    }
}
