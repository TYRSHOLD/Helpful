//
//  HelpfulWidgetsBundle.swift
//  HelpfulWidgets
//
//  Created by CAIT on 2/20/26.
//

import WidgetKit
import SwiftUI

@main
struct HelpfulWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BudgetWidget()
        SpendingWidget()
        GoalWidget()
    }
}
