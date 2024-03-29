//
//  ProfileWorker.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 3/9/24.
//

import UIKit

final class ProfileWorker {
    // MARK: - Private Properties
}

// MARK: - WorkerLogic
extension ProfileWorker: ProfileWorkerLogic {
    func clearUserData() {
        AuthManager.shared.deleteRefreshTokenLastUpdateDate()
        AuthManager.shared.deleteToken(tokenType: .access)
        AuthManager.shared.deleteToken(tokenType: .refresh)
    }
}
