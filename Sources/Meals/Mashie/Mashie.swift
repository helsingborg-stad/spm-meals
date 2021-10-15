import Foundation
import Combine
import SwiftSoup

public struct MashieEaterie : MealService {
    enum MashieEaterieError : Error {
        case dataFailure(URL)
    }
    struct Info : Codable {
        let score:Double?
        let kgCo2E:Double?
        let imageUrl:URL?
    }
    public struct Parameter {
        public let occation:Meal.Occasion
        public let foodType:Meal.FoodType
        public let tags:Set<Meal.Tag>
        public let title:String
        public let info:[String]
        public init(occation:Meal.Occasion, foodType:Meal.FoodType = .undecided, title:String, tags:Set<Meal.Tag> = [],info:[String] = []) {
            self.occation = occation
            self.foodType = foodType
            self.tags = tags
            self.title = title
            self.info = info
        }
    }
    public let parameters:[Parameter]
    public let url:URL
    public let orgId:String
    public let fetchInfo:Bool
    public init(url:URL, orgId:String, parameters:[Parameter], fetchInfo:Bool = false) {
        self.url = url
        self.orgId = orgId
        self.parameters = parameters
        self.fetchInfo = true
    }
    public func fetchMealsPublisher() -> AnyPublisher<[Meal], Error> {
        let s = PassthroughSubject<[Meal],Error>()
        DispatchQueue.global().async {
            var arr = [Meal]()
            do {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let mashie = try Data(contentsOf: url)
                guard let mashieHTML = String(data: mashie, encoding: .utf8) else {
                    s.send(completion: .failure(MashieEaterieError.dataFailure(url)))
                    return
                }
                let doc = try SwiftSoup.parse(mashieHTML)
                let weeks = try doc.getElementsByClass("container-week")
                for week in weeks.prefix(1) {
                    let dayElements = try week.getElementsByClass("container-fluid no-print")
                    for dayElement in dayElements {
                        guard let dateString = try dayElement.getElementById("dayMenuDate")?.attr("js-date"), let date = formatter.date(from: dateString) else {
                            debugPrint("cannot format date for \(url.absoluteString)")
                            continue
                        }
                        let menuItems = try dayElement.getElementsByClass("day-alternative-wrapper")
                        for menuItem in menuItems {
                            
                            let id = try menuItem.getElementsByClass("modal").first()?.attr("id").replacingOccurrences(of: "modal-", with: "")
                            let container = try menuItem.getElementsByClass("day-alternative")
                            var info:Info? = nil
                            if fetchInfo, let id = id {
                                if let infoData = try? Data(contentsOf: URL(string:"https://mpi.mashie.com/public/internal/meals/\(id)/rating?orgId=\(orgId)")!) {
                                    info = try? JSONDecoder().decode(Info.self, from: infoData)
                                }
                            }
                            let foodItemTitle = try container.select("strong")
                            let foodItemContents = try foodItemTitle.select("span")
                            
                            let title = try foodItemTitle.html()
                            let removeFromTitle = try foodItemContents.outerHtml()
                            let cleanedTitle = title.replacingOccurrences(of: removeFromTitle, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            let foodItem = try foodItemContents.text()
                            
                            guard let p = parameters.first(where: { $0.title == cleanedTitle }) else {
                                continue
                            }
                            arr.append(
                                Meal(
                                    id:id,
                                    description: foodItem,
                                    title: p.title,
                                    date: date,
                                    occasion: p.occation,
                                    type: p.foodType,
                                    tags: p.tags,
                                    imageUrl:info?.imageUrl,
                                    carbonFootprint:info?.kgCo2E,
                                    rating:info?.score
                                )
                            )
                        }
                    }
                }
                s.send(arr)
            } catch {
                s.send(completion: .failure(error))
            }
        }
        return s.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
}
