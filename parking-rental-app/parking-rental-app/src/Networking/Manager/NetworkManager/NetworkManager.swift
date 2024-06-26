//
//  NetworkManager.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 2/20/24.
//

import Foundation
import UIKit

enum NetworkEnvironment {
    case production
}

final class NetworkManager: NetworkManagerProtocol {
    static let environment: NetworkEnvironment = .production
    private var authManager: AuthManagerProtocol!
    private var accessToken: String {
        get {
            self.authManager.getAccessToken() ?? ""
        }
    }
    private let carsRouter = Router<CarsApi>()
    private let authRouter = Router<AuthApi>()
    private let reservationsRouter = Router<ReservationsApi>()
    private let parkingSpotsRouter = Router<ParkingSpotsApi>()
    private let parkingLevelsRouter = Router<ParkingLevelsApi>()
    private let buildingsRouter = Router<BuildingsApi>()
    private let emplyeesRouter = Router<EmployeesApi>()
    
    enum Result<String> {
        case success
        case failure(String)
    }
    
    init(authManager: AuthManagerProtocol = AuthManager()) {
        self.authManager = authManager
    }
    
    fileprivate func handleNetworkResponse(_ response: HTTPURLResponse) -> Result<NetworkResponse> {
        switch response.statusCode {
        case 200...299: return .success
        case 401...499: return .failure(NetworkResponse.authenticationError)
        case 500...599: return .failure(NetworkResponse.badRequest)
        case 600: return .failure(NetworkResponse.outdated)
        default: return .failure(NetworkResponse.failed)
        }
    }
    
    // MARK: - Generic Functions
    private func responseDataDecoder<T: Decodable>(data: Data?, dataType: T.Type, response: URLResponse?, error: Error?) -> (data: T?, error: NetworkResponse?) {
        if error != nil {
            return (nil, NetworkResponse.connectionFailure)
        }
        if let response = response as? HTTPURLResponse {
            let result = self.handleNetworkResponse(response)
            switch result {
            case .success:
                guard let responseData = data else {
                    return (nil, NetworkResponse.noData)
                }
                do {
                    let apiResponse = try JSONDecoder().decode(dataType, from: responseData)
                    return (apiResponse.self, nil)
                } catch {
                    return (nil, NetworkResponse.unableToDecode)
                }
            case .failure(let networkFailureError):
                return (nil, networkFailureError)
            }
        } else {
            return (nil, NetworkResponse.noResponse)
        }
    }
    
    private func responseNoDataDecoder(response: URLResponse?, error: Error?) -> (NetworkResponse?) {
        if error != nil {
            return NetworkResponse.connectionFailure
        }
        if let response = response as? HTTPURLResponse {
            let result = self.handleNetworkResponse(response)
            switch result {
            case .success:
                return nil
            case .failure(let networkFailureError):
                return networkFailureError
            }
        } else {
            return NetworkResponse.noResponse
        }
    }
    
    private func authRequestDataResponse<TRouter: NetworkRouter, TResponse: Decodable>(router: TRouter, task: TRouter.EndPoint, responseType: TResponse.Type, completion: @escaping (_ data: TResponse?, _ error: NetworkResponse?) -> ()) {
        router.request(task, with: self.accessToken) { [weak self] data, response, error in
            let responseDecoder = self?.responseDataDecoder(data: data, dataType: responseType, response: response, error: error)
            if responseDecoder?.error == nil {
                completion(responseDecoder?.data as? TResponse, nil)
            } else if responseDecoder?.error == NetworkResponse.authenticationError {
                self?.updateAccessToken(completion: { [weak self] authData, error in
                    if error != nil {
                        completion(nil, error)
                    } else {
                        guard let newAccessToken = authData?.accessToken else {
                            completion(nil, NetworkResponse.getTokenFailure)
                            return
                        }
                        if !(self?.authManager.updateToken(token: newAccessToken, tokenType: .access) ?? false) {
                            completion(nil, NetworkResponse.updateTokenFailure)
                            return
                        }
                        router.request(task, with: self?.accessToken) { [weak self] data, response, error in
                            let responseDecoder = self?.responseDataDecoder(data: data, dataType: responseType, response: response, error: error)
                            completion(responseDecoder?.data as? TResponse, responseDecoder?.error)
                        }
                    }
                })
            } else {
                completion(nil, responseDecoder?.error)
            }
        }
    }
    
    private func authRequestNoDataResponse<TRouter: NetworkRouter>(router: TRouter, task: TRouter.EndPoint, completion: @escaping (_ error: NetworkResponse?) -> ()) {
        router.request(task, with: self.accessToken) { [weak self] data, response, error in
            let responseDecoder = self?.responseNoDataDecoder(response: response, error: error)
            if responseDecoder == nil {
                completion(nil)
            } else if responseDecoder == NetworkResponse.authenticationError {
                self?.updateAccessToken(completion: { [weak self] authData, error in
                    if error != nil {
                        completion(error)
                    } else {
                        guard let newAccessToken = authData?.accessToken else {
                            completion(NetworkResponse.getTokenFailure)
                            return
                        }
                        if !(self?.authManager.updateToken(token: newAccessToken, tokenType: .access) ?? false) {
                            completion(NetworkResponse.updateTokenFailure)
                            return
                        }
                        router.request(task, with: self?.accessToken) { [weak self] data, response, error in
                            let responseDecoder = self?.responseNoDataDecoder(response: response, error: error)
                            completion(responseDecoder)
                        }
                    }
                })
            } else {
                completion(responseDecoder)
            }
        }
    }
    
    // MARK: - Tokens Processing
    public func updateRefreshToken(completion: @escaping (_ authData: AuthApiResponse?, _ error: NetworkResponse?) -> ()) {
        guard let oldRefreshToken = self.authManager.getRefreshToken() else {
            completion(nil, NetworkResponse.noRefreshToken)
            return
        }
        authRequestDataResponse(router: authRouter, task: .updateRefreshToken(refreshToken: oldRefreshToken), responseType: AuthApiResponse.self) { data, error in
            completion(data, error)
        }
    }
    
    private func updateAccessToken(completion: @escaping (_ authData: AuthApiAccessTokenResponse?, _ error: NetworkResponse?) -> ()) {
        guard let refreshToken = self.authManager.getRefreshToken() else {
            completion(nil, NetworkResponse.noRefreshToken)
            return
        }
        authRouter.request(.updateAccessToken(refreshToken: refreshToken)) { [weak self] data, response, error in
            let responseDecoder = self?.responseDataDecoder(data: data, dataType: AuthApiAccessTokenResponse.self, response: response, error: error)
            completion(responseDecoder?.data as? AuthApiAccessTokenResponse, responseDecoder?.error)
        }
    }
    
    // MARK: - Auth API
    func login(email: String, password: String, completion: @escaping (_ authData: AuthApiResponse?, _ error: NetworkResponse?) -> ()) {
        authRouter.request(.login(email: email, password: password)) { [weak self] data, response, error in
            let responseDecoder = self?.responseDataDecoder(data: data, dataType: AuthApiResponse.self, response: response, error: error)
            completion(responseDecoder?.data as? AuthApiResponse, responseDecoder?.error)
        }
    }
    
    func signup(name: String, email: String, password: String, completion: @escaping (_ authData: AuthApiResponse?, _ error: NetworkResponse?) -> ()) {
        authRouter.request(.signUp(name: name, email: email, password: password)) { [weak self] data, response, error in
            let responseDecoder = self?.responseDataDecoder(data: data, dataType: AuthApiResponse.self, response: response, error: error)
            completion(responseDecoder?.data as? AuthApiResponse, responseDecoder?.error)
        }
    }
    
    func whoami(completion: @escaping (_ authData: AuthWhoamiApiResponse?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: authRouter, task: .whoami, responseType: AuthWhoamiApiResponse.self) { data, error in
            completion(data, error)
        }
    }
    
    // MARK: - Reservations API
    func getAllReservations(completion: @escaping (_ reservationsData: [Reservation]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: reservationsRouter, task: .getAllReservations, responseType: [Reservation].self) { data, error in
            completion(data, error)
        }
    }
    
    func getReservation(reservationID: String, completion: @escaping (_ reservationData: Reservation?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: reservationsRouter, task: .getReservation(reservationID: reservationID), responseType: Reservation.self) { data, error in
            completion(data, error)
        }
    }
    
    func addNewReservation(carId: String, employeeId: String, parkingSpotId: String, startTime: String, endTime: String, completion: @escaping (_ reservationData: Reservation?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: reservationsRouter, task: .addNewReservation(carId: carId, employeeId: employeeId, parkingSpotId: parkingSpotId, startTime: startTime, endTime: endTime), responseType: Reservation.self) { data, error in
            completion(data, error)
        }
    }
    
    func deleteReservation(id: String, completion: @escaping (_ error: NetworkResponse?) -> ()) {
        authRequestNoDataResponse(router: reservationsRouter, task: .deleteReservation(id: id)) { error in
            completion(error)
        }
    }
    
    // MARK: - ParkingSpots API
    func getAllParkingSpots(completion: @escaping (_ parkingSpotsData: [ParkingSpot]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: parkingSpotsRouter, task: .getAllParkingSpots, responseType: [ParkingSpot].self) { data, error in
            completion(data, error)
        }
    }
    
    func getParkingSpot(parkingSpotID: String, completion: @escaping (_ parkingSpotData: ParkingSpot?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: parkingSpotsRouter, task: .getParkingSpot(parkingSpotID: parkingSpotID), responseType: ParkingSpot.self) { data, error in
            completion(data, error)
        }
    }
    
    // MARK: - ParkingLevels API
    func getAllParkingLevels(completion: @escaping (_ parkingLevelsData: [ParkingLevel]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: parkingLevelsRouter, task: .getAllParkingLevels, responseType: [ParkingLevel].self) { data, error in
            completion(data, error)
        }
    }
    
    func getAllLevelSpots(parkingLevelID: String, completion: @escaping (_ parkingSpotsData: [ParkingSpot]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: parkingLevelsRouter, task: .getAllLevelSpots(parkingLevelID: parkingLevelID), responseType: [ParkingSpot].self) { data, error in
            completion(data, error)
        }
    }
    
    func getParkingLevel(parkingLevelID: String, completion: @escaping (_ parkingLevelData: ParkingLevel?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: parkingLevelsRouter, task: .getParkingLevel(parkingLevelID: parkingLevelID), responseType: ParkingLevel.self) { data, error in
            completion(data, error)
        }
    }
    
    func getAllLevelFreeSpots(parkingLevelID: String, startTime: String, endTime: String, completion: @escaping (_ parkingSpotsData: [ParkingSpot]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: parkingLevelsRouter, task: .getAllLevelFreeSpots(parkingLevelID: parkingLevelID, startTime: startTime, endTime: endTime), responseType: [ParkingSpot].self) { data, error in
            completion(data, error)
        }
    }
    
    // MARK: - Buildings API
    func getAllBuildings(completion: @escaping (_ buildingsData: [Building]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: buildingsRouter, task: .getAllBuildings, responseType: [Building].self) { data, error in
            completion(data, error)
        }
    }
    
    func getAllBuildingLevels(buildingID: String, completion: @escaping (_ levelsData: [ParkingLevel]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: buildingsRouter, task: .getAllBuildingLevels(buildingID: buildingID), responseType: [ParkingLevel].self) { data, error in
            completion(data, error)
        }
    }
    
    func getBuilding(buildingID: String, completion: @escaping (_ buildingData: Building?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: buildingsRouter, task: .getBuilding(buildingID: buildingID), responseType: Building.self) { data, error in
            completion(data, error)
        }
    }
    
    // MARK: - Cars API
    func addNewCar(model: String, registryNumber: String, completion: @escaping (_ carData: Car?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: carsRouter, task: .addNewCar(model: model, lengthMeters: 1.0, weightTons: 1.0, registryNumber: registryNumber), responseType: Car.self) { data, error in
            completion(data, error)
        }
    }
    
    func updateCar(id: String, model: String, registryNumber: String, completion: @escaping (_ carData: Car?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: carsRouter, task: .updateCar(id: id, model: model, lengthMeters: 1.0, weightTons: 1.0, registryNumber: registryNumber), responseType: Car.self) { data, error in
            completion(data, error)
        }
    }
    
    func getAllCars(completion: @escaping (_ carsData: [Car]?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: carsRouter, task: .getAllCars, responseType: [Car].self) { data, error in
            completion(data, error)
        }
    }
    
    func getCar(carID: String, completion: @escaping (_ carData: Car?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: carsRouter, task: .getCar(carID: carID), responseType: Car.self) { data, error in
            completion(data, error)
        }
    }
    
    func deleteCar(carID: String, completion: @escaping (_ error: NetworkResponse?) -> ()) {
        authRequestNoDataResponse(router: carsRouter, task: .deleteCar(id: carID)) { error in
            completion(error)
        }
    }
    
    // MARK: - Employees API
    func deleteEmployee(completion: @escaping (_ error: NetworkResponse?) -> ()) {
        authRequestNoDataResponse(router: emplyeesRouter, task: .deleteEmployee) { error in
            completion(error)
        }
    }
    
    func updateEmployee(name: String, email: String, password: String, completion: @escaping (_ authData: AuthApiResponse?, _ error: NetworkResponse?) -> ()) {
        authRequestDataResponse(router: emplyeesRouter, task: .updateEmployee(name: name, email: email, password: password), responseType: AuthApiResponse.self) { data, error in
            completion(data, error)
        }
    }
}
