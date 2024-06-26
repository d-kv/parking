//
//  CarDetailsRouter.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 4/19/24.
//

import UIKit

final class CarDetailsRouter {
    // MARK: - Properties
    weak var view: UIViewController?
}

// MARK: - RoutingLogic
extension CarDetailsRouter: CarDetailsRoutingLogic {
    func routeToAccountCars() {
        view?.navigationController?.popViewController(animated: true)
    }
    
    func routeToUpdateCar(_ routeData: Model.UpdateCar.RouteData) {
        view?.navigationController?.pushViewController(UpdateCarAssembly.build(carID: routeData.carID), animated: true)
    }
}
