//
//  MapModel.swift
//  parking-rental-app
//
//  Created by Никита Лисунов on 3/9/24.
//

import UIKit

enum MapModel {
    
    enum Start {
        struct Request { }
        struct Response { }
        struct ViewModel { }
    }
    
    enum Home {
        struct Request { }
        struct Response { }
        struct ViewModel { }
    }
    
    enum More {
        struct Request { }
        struct Response { }
        struct ViewModel { }
    }
    
    enum PreviousScene {
        struct Request { }
        struct Response { }
        struct ViewModel { }
    }
    
    enum ParkingMap {
        struct Request { }
        struct Response {
            let parkingSpots: [ParkingSpot]
            let parkingLevelCanvas: Canvas
        }
        struct ViewModel {
            let parkingSpotsCoords: [OnCanvasCoords]
            let parkingSpotsCanvases: [Canvas]
            let parkingLevelCanvas: Canvas
        }
    }
}
