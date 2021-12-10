import SwiftUI



struct NavigationBarView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor.black
    }
    
    var body: some View{
        TabView{
            MeasureView().tabItem{
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                Text("Measure")
            }
            GraphsView().tabItem{
                Image(systemName: "slider.vertical.3")
                Text("Graphs")
            }
            SettingsView().tabItem{
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
}
