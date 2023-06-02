//
//  FirstScreen.swift
//  Terrafic_RTiOS_UIKit
//
//  Created by Bryan Tan on 02/06/2023.
//

import UIKit
import SwiftUI
import TerraRTiOS

public struct TokenPayload: Decodable{
    let token: String
}

public func generateSDKToken(devId: String, xAPIKey: String) -> TokenPayload?{
    
        let url = URL(string: "https://api.tryterra.co/v2/auth/generateAuthToken")
        
        guard let requestUrl = url else {fatalError()}
        var request = URLRequest(url: requestUrl)
        var result: TokenPayload? = nil
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "terra.token.generation")
        request.httpMethod = "POST"
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue(devId, forHTTPHeaderField: "dev-id")
        request.setValue(xAPIKey, forHTTPHeaderField: "x-api-key")
        
        let task = URLSession.shared.dataTask(with: request){(data, response, error) in
            if let data = data{
                let decoder = JSONDecoder()
                do{
                    result = try decoder.decode(TokenPayload.self, from: data)
                    group.leave()
                }
                catch{
                    print(error)
                    group.leave()
                }
            }
        }
        group.enter()
        queue.async(group: group) {
            task.resume()
        }
        group.wait()
        return result
}

class FirstScreen: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButton()
        let terraRT = TerraRT(devId: DEVID, referenceId: XAPIKEY) { succ in
            print("TerraRT init: \(succ)")
        }

        let tokenPayload = generateSDKToken(devId: DEVID, xAPIKey: XAPIKEY)
        print("TerraSDK token: \(tokenPayload!.token)")

        terraRT.initConnection(token: tokenPayload!.token) { succ in
            print("Connection formed: \(succ)")
        }
        
        let terraBLEWidget = terraRT.startBluetoothScan(type: Connections.BLE, bluetoothLowEnergyFromCache: false) { succ in
            print("Device Connected!")
        }
        
        let hostingController = UIHostingController(rootView: terraBLEWidget)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
}

