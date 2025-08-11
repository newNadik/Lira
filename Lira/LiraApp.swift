//
//  LiraApp.swift
//  Lira
//
//  Created by Nadiia Iva on 11/08/2025.
//

import SwiftUI

@main
struct LiraApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
