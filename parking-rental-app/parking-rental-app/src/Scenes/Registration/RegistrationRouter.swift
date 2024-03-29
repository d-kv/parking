//
//  RegistrationRouter.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 2/14/24.
//

import UIKit

final class RegistrationRouter {
    // MARK: - Properties
    weak var view: UIViewController?
}

// MARK: - RoutingLogic
extension RegistrationRouter: RegistrationRoutingLogic {
    func routeToRegistrationCar() {
        view?.navigationController?.pushViewController(RegistrationCarAssembly.build(), animated: true)
    }
    
    func routeToLogin() {
        view?.navigationController?.popViewController(animated: true)
    }
}
