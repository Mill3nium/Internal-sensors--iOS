import SwiftUI



struct NavigationBarView: View {
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
        }
    }
}
