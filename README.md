# StringMap
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fo-micron%2FStringMap.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fo-micron%2FStringMap?ref=badge_shield)


StringMap is a string extension only that allows efficient sequential search queries.

# Example Snippet
```swift
var countries = ["egypt🇪🇬", "germany🇩🇪", "france🇫🇷", "united states🇺🇸", "spain🇪🇸"]

countries.search { map in
    print("e".matches(map: &map, at: .start)) // ["egypt🇪🇬"]
    print("🇫🇷".matches(map: &map, at: .end)) // ["france🇫🇷"]
    print("a".matches(map: &map, at: .somewhere)) // ["germany🇩🇪", "france🇫🇷", "united states🇺🇸", "spain🇪🇸"]
    print("germany🇩🇪".matches(map: &map, at: .everywhere)) // ["germany🇩🇪"]
    print("an".matches(map: &map, at: .somewhere)) // ["germany🇩🇪", "france🇫🇷"]
}
```

# Install
```bash
$ git clone https://github.com/o-micron/StringMap.git
$ cd StringMap
$ swift build
$ swift run
```

# License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fo-micron%2FStringMap.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fo-micron%2FStringMap?ref=badge_large)
