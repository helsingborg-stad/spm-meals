# Meals

Meals provides a common interface for meal services implementing the `MealService` protocol.

## Usage 

```swift
import Meals 
import Combine
import SwiftUI

public class MyMealService : MealService {
    public func fetchMealsPublisher() -> AnyPublisher<[Meal], Error> {
        let subject = PassthroughSubject<[Meal],Error>()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            subject.send(Meals.previewData)
        }
        return subject.eraseToAnyPublisher()
    }
}

class StateManager {
    var meals:Meals
    init {
        let meals = Meals(service: MyMealService(), fetchAutomatically: true, previewData: ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1")
    }
}

struct FoodView: View {
    @EnvironmentObject var meals:Meals
    @State var items = [Meal]()
    var body: some View {
        List {
            Section(header: Text("Todays lunch")) {
                ForEach(items) { meal in
                    VStack(alignment: .leading) {
                        Text(meal.title ?? meal.occasion.rawValue).bold()
                        Text(meal.description)
                    }.frame(maxWidth:.infinity,alignment:.leading)
                }
            }
        }
        .onReceive(meals.publisher(occation:.lunch)) { val in
            items = val
        }
    }
}

@main struct ExampleAssistantApp: App {
    @StateObject var appState = StateManager()
    var body: some Scene {
        WindowGroup {
            FoodView().environmentObject(appState.meals)
        }
    }
}
```

## Skolmaten.se service
Implements MealService from the swift package `Meals`  and develivers meal information from Skolmaten.se via thier RSS-endpoint.

The `School` object implements the `MealService` protocol. You can provide the information to a school manually or by searching using either `Skolmaten.first` or `Skolmaten.filter`.
Once you have a `School`  you can us it together with a `Meals` instance or create your own implementation using `School.fetchMealsPublisher(filter:offset:limit:)` method.  

```swift 
Skolmaten.first(county:"Skåne", municipality:"Helsingborg", school:"Råå förskola").sink { completion in
    switch completion {
    case .failure(let error): debugPrint(error)
    case .finished: break
    }
} receiveValue: { school in
    // Store your school for later use to speed up your implementation and remove redundant network requests.
    meals.service = school
}
```

## TODO

- [ ] add list of available services
- [x] code-documentation
- [ ] write tests
- [ ] complete package documentation
