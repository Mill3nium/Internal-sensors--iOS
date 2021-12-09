//
//  GraphsView.swift
//  InternalSensors
//
//  Created by Milan Languric on 2021-12-09.
//

import SwiftUI
import SwiftUICharts

struct GraphsView: View {
    var body: some View{
        NavigationView{
        
                VStack{
                    MultiLineChartView(data: [([8,32,11,23,40,28], GradientColors.green), ([90,99,78,111,70,60,77], GradientColors.purple)], title: "Slow move")
                    
                    MultiLineChartView(data: [([8,32,11,23,40,28], GradientColors.green), ([90,99,78,111,70,60,77], GradientColors.purple)], title: "Fast move")
                }.navigationTitle("Graphs")
        }
    }
}
