//
//  UpdateCarAssembly.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 3/15/24.
//

import UIKit

enum UpdateCarAssembly {
    static func build() -> UIViewController {
        let router: UpdateCarRouter = UpdateCarRouter()
        let presenter: UpdateCarPresenter = UpdateCarPresenter()
        let worker: UpdateCarWorker = UpdateCarWorker()
        let interactor: UpdateCarInteractor = UpdateCarInteractor(presenter: presenter, worker: worker)
        let viewController: UpdateCarViewController = UpdateCarViewController(
            router: router,
            interactor: interactor
        )
        
        router.view = viewController
        presenter.view = viewController
        
        return viewController
    }
}
