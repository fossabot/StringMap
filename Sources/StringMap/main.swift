import Foundation


//==------------------------- Example Code -------------------------==
var countries = ["egypt🇪🇬", "germany🇩🇪", "france🇫🇷", "united states🇺🇸", "spain🇪🇸"]

countries.search { map in
    print("e".matches(map: &map, at: .start)) // ["egypt🇪🇬"]
    print("🇫🇷".matches(map: &map, at: .end)) // ["france🇫🇷"]
    print("a".matches(map: &map, at: .somewhere)) // ["germany🇩🇪", "france🇫🇷", "united states🇺🇸", "spain🇪🇸"]
    print("germany🇩🇪".matches(map: &map, at: .everywhere)) // ["germany🇩🇪"]
    print("an".matches(map: &map, at: .somewhere)) // ["germany🇩🇪", "france🇫🇷"]
}
//==----------------------------------------------------------------==