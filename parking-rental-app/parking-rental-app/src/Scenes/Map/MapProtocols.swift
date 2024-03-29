//
//  MapProtocols.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 3/9/24.
//

// MARK: - DisplayLogic
protocol MapDisplayLogic: AnyObject {
    typealias Model = MapModel
    func displayStart(_ viewModel: Model.Start.ViewModel)
    func displayParkingMap(_ viewModel: Model.ParkingMap.ViewModel)
    func displayHome(_ viewModel: Model.Home.ViewModel)
    func displayMore(_ viewModel: Model.More.ViewModel)
    func displayPreviousScene(_ viewModel: Model.PreviousScene.ViewModel)
}

// MARK: - BusinessLogic
protocol MapBusinessLogic {
    typealias Model = MapModel
    func loadStart(_ request: Model.Start.Request)
    func loadParkingMap(_ request: Model.ParkingMap.Request)
    func loadHome(_ request: Model.Home.Request)
    func loadMore(_ request: Model.More.Request)
    func loadPreviousScene(_ request: Model.PreviousScene.Request)
}

// MARK: - PresentationLogic
protocol MapPresentationLogic {
    typealias Model = MapModel
    func presentStart(_ response: Model.Start.Response)
    func presentParkingMap(_ response: Model.ParkingMap.Response)
    func presentHome(_ response: Model.Home.Response)
    func presentMore(_ response: Model.More.Response)
    func presentPreviousScene(_ response: Model.PreviousScene.Response)
}

// MARK: - RoutingLogic
protocol MapRoutingLogic {
    func routeToHome()
    func routeToMore()
    func routeToPreviousScene()
}

// MARK: - WorkerLogic
protocol MapWorkerLogic {
    typealias Model = MapModel
    func getAllBuildingLevels(buildingID: String, completion: @escaping (_ levelsData: [ParkingLevel]?, _ error: String?) -> ())
    func getAllLevelSpots(parkingLevelID: String, completion: @escaping (_ parkingSpotsData: [ParkingSpot]?, _ error: String?) -> ())
}
