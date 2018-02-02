import Foundation


///==------------------- StringMap Main Algorithm ------------------==


/// This Class provides faster basic string matching from Arrays of String [String]
/// For very large arrays we want to check if any item matches a certain criteria
/// This class does a better job picking the matching elements at minimal time
/// This class defeats hasPrefix or hasSuffix implementations in large comparisons cases
/// So one would use this instead in case we are searching for files in system for example
///
/// Example
///
/// var countries = ["egypt🇪🇬", "germany🇩🇪", "france🇫🇷", "united states🇺🇸", "spain🇪🇸"]
///
/// countries.search { map in
///     print("e".matches(map: &map, at: .start)) // returns ["egypt🇪🇬"]
///     print("🇫🇷".matches(map: &map, at: .end)) // returns ["france🇫🇷"]
///     print("a".matches(map: &map, at: .somewhere)) // returns ["germany🇩🇪", "france🇫🇷", "united states🇺🇸", "spain🇪🇸"]
///     print("germany🇩🇪".matches(map: &map, at: .everywhere)) // returns ["germany🇩🇪"]
/// }





/// This extension allows a string to find all matches from a String array [String]
/// One can directly invoke this function on any string
/// Just make sure you call this function only when you are inside the [String].search callback function
/// See the tests for examples on how to use this function
public extension String {
    
    /// Matches a string from any other string inside an array of strings
    /// You pass a StringPyramidCache reference which is only found once you call [String].search
    /// You need to pass a location at which you want to match (.start, .end, .anywhere, .everywhere)
    public func matches(map: inout StringPyramidCache, at: StringPyramidLocation) -> [String] {
        
        let encoder = StringPyramidEncoder()
        return encoder.complete(str: self, using: &map, at: at)
        
    }
    
}




/// Applies on Arrays of Strings only
/// This is an extension for quick search on arrays of strings
/// This is only trying to represent an array of strings in a different way
/// Just for the purpose of quick search
/// This design ensures that we won't have memory allocated without being really used
/// RAII, the encoder and the cache instances are only temporary
/// They shouldn't live longer after finishing the matching jobs
/// They need memory, that's a disadvantage but extremely short & simple implementation
public extension BidirectionalCollection where Iterator.Element == String {
    
    /// The Search function takes a callback function as a paramater
    /// The callback is going to be called once the array strings are being analyzed and organized in pyramid levels
    /// Use the pyramid cache when you call `String.matches` function
    /// Check StringPyramidCache and String.matches for more details
    public func search(_ map: (_ pyramids: inout StringPyramidCache) -> Void) {
        
        let encoder = StringPyramidEncoder()
        var cache = StringPyramidCache(name: "default")
        encoder.encode(words: self as! [String], cache: &cache)
        map(&cache)
        
    }
    
}





/// This Enum defines the location at which we want to match
public enum StringPyramidLocation {
    
    case start
    case somewhere
    case end
    case everywhere
    
}


/// Now this is the interesting part :D
/// A String is represented by its characters
/// We have to represent a string using the chaining order of that string
/// And We want to end up representing a string as a single Float number
/// So we basically blur the string and only show the average values of all the characters
/// But we also want to keep the order !!!
/// So we gain the performance by checking only once instead of n number of characters ...
/// We want to make every single word or even sentence given as a single float number ...
/// So we start by averaging every 2 neighboured characters ...
/// This way we get n/2 number of characters for each pyramid level we jump
/// We start from the base till up .. the coarse ! where we have a single float number ...
/// Each detail level is called a Pyramid Level
/// Just like images if you've worked on multiresolution analysis ...
class StringPyramidLevel {
    
    var depth: Int
    var data: [Float]
    var stringValue: String
    var previous: StringPyramidLevel? = nil
    weak var next: StringPyramidLevel? = nil
    
    init(stringValue: String, data: [Float], depth: Int = 0) {
        self.data = data
        self.depth = depth
        self.stringValue = stringValue
    }
    
    deinit {
        
        if previous != nil {
            previous = nil
        }
        
    }
    
    func getPreviousDataRecursively() -> [[Float]] {
        
        var data = [[Float]](repeating: [], count: self.depth + 1)
        var copy: StringPyramidLevel? = self
        var i = 0
        while copy != nil {
            data[i] = copy!.data
            copy = copy!.previous
            i = i + 1
        }
        return data
        
    }
    
    func getPreviousLevelsRecursively() -> [StringPyramidLevel] {
        
        let times = self.depth + 1
        var levels = [StringPyramidLevel?](repeating: nil, count: times)
        var copy: StringPyramidLevel? = self
        var i = 0
        while copy != nil {
            levels[i] = copy!
            copy = copy!.previous
            i = i + 1
        }
        return levels.filter{ $0 != nil } as! [StringPyramidLevel]
        
    }
    
    func matchesBegin(other: StringPyramidLevel) -> Bool {
        if depth > other.depth {
            return false
        }
        return Array(other.data[0 ..< self.data.count]) == self.data
    }
    
    func matchesSomewhere(other: StringPyramidLevel) -> Bool {
        if depth > other.depth {
            return false
        }
        for i in 0 ..< (other.data.count - self.data.count) {
            if Array(other.data[i ..< i + self.data.count]) == self.data {
                return true
            }
        }
        return false
    }
    
    func matchesEnd(other: StringPyramidLevel) -> Bool {
        if depth > other.depth {
            return false
        }
        return Array(other.data[(other.data.count - self.data.count) ..< other.data.count]) == self.data
    }
    
    func matchesEverywhere(other: StringPyramidLevel) -> Bool {
        if depth > other.depth {
            return false
        }
        return self.data == other.data
    }
    
}



/// This is the encoder that we use in order to transform the string to pyramid
/// And the pyramid back to string
class StringPyramidEncoder {
    
    var evaluation: (Float, Float) -> Float = { (a, b) in
        return cos(a) - sin(b)
    }
    
    init() {
        
    }
    
    init(evaluation: ((Float, Float) -> Float)? = nil) {
        if evaluation != nil {
            self.evaluation = evaluation!
        }
    }
    
    func transform(from: String) -> [Float] {
          
         return from.unicodeScalars.map{ Float($0.hashValue) }
         
     }
     
     func transform(from: [Float]) -> String {
         
         let characterSequence = from.map{ UnicodeScalar(Int($0))! }.map{ Character($0) }
         return String.init(characterSequence)
          
      }
    
    func encode(lastLevel: inout StringPyramidLevel, cache: inout StringPyramidCache) -> StringPyramidLevel? {
        
        if lastLevel.data.count <= 1 {
            return lastLevel
        }
        var nextLevel = StringPyramidLevel(stringValue: lastLevel.stringValue, data: [], depth: lastLevel.depth + 1)
        
        var i = 0
        while i < lastLevel.data.count - Int(pow(2.0, Float(lastLevel.depth))) {
            let a = lastLevel.data[i]
            let b = lastLevel.data[i + Int(pow(2.0, Double(lastLevel.depth)))]
            
            nextLevel.data.append(evaluation(a, b))
            
            i = i + 1
        }
        if nextLevel.data.count == 0 {
            return lastLevel
        }
        nextLevel.previous = lastLevel
        lastLevel.next = nextLevel
        return encode(lastLevel: &nextLevel, cache: &cache)
        
    }
    
    func encode(word: String, cache: inout StringPyramidCache, isSaved: Bool = false) -> StringPyramidLevel? {
        
        guard word.characters.count > 0 else { return nil }
        let transformed = transform(from: word)
        var firstLevel = StringPyramidLevel(stringValue: word, data: transformed)
        let lastLevel = encode(lastLevel: &firstLevel, cache: &cache)
        if isSaved {
            cache.insertRecursive(level: lastLevel!)
        }
        return lastLevel
        
    }
    
    func encode(words: [String], cache: inout StringPyramidCache) {
        
        for str in words {
            guard str.characters.count > 0 else { return }
            let transformed = transform(from: str)
            var firstLevel = StringPyramidLevel(stringValue: str, data: transformed)
            let lastLevel = encode(lastLevel: &firstLevel, cache: &cache)
            cache.insertRecursive(level: lastLevel!)
        }
        
    }
    
    func complete(str: String, using cache: inout StringPyramidCache, at: StringPyramidLocation) -> [String] {
        
        if let encoded: StringPyramidLevel = encode(word: str, cache: &cache) {
            
            let depth = encoded.depth
            var out = [String](repeating: "", count: cache.data[depth].count)
            
            var inRange = false
            
            for i in 0 ..< cache.data[depth].count {
                switch at
                {
                case .start:
                    inRange = encoded.matchesBegin(other: cache.data[depth][i]!)
                    
                case .end:
                    inRange = encoded.matchesEnd(other: cache.data[depth][i]!)
                    
                case .somewhere:
                    inRange = encoded.matchesSomewhere(other: cache.data[depth][i]!)
                    
                case .everywhere:
                    inRange = encoded.matchesEverywhere(other: cache.data[depth][i]!)
                }
                
                if inRange {
                    out[i] = cache.data[depth][i]!.stringValue
                }
            }
            
            return out.filter{ $0 != "" }
            
        }
        return []
        
    }
    
}


/// This is the cache that we use to quickly jump to the similar pyramid levels
/// We want to jump as quickly as possible to the similar strings
/// We wouldn't use a hashmap for this ...
/// The hashmap completely removes all the relations between the pyramid levels
/// So We use a level based array
/// Each level has index
/// Each index contains all words that are similar from a blurred image perspective
/// Remember we can figure out if 2 words are equal even when we blur the images
/// We only gain performance here by blurring the informations of a string
/// And still we can expand the details by going 1 level down the pyramid ;)
public class StringPyramidCache {
    
    static var static_id = 0
    var id: Int
    var name: String
    var data: [[StringPyramidLevel?]] = []
    var words: Int = 0
    
    init(name: String) {
        StringPyramidCache.static_id = StringPyramidCache.static_id + 1
        self.id = StringPyramidCache.static_id
        self.name = "\(name)_\(id)"
    }
    
    deinit {
        //        print("Deleting cache named: \(name) sized = \(data.count)")
        for d in 0 ..< data.count {
            for l in 0 ..< data[d].count {
                data[d][l] = nil
            }
            data[d].removeAll()
            //            print("")
        }
        data.removeAll()
        //        print("done")
    }
    
    func insertRecursive(level: StringPyramidLevel) {
        
        words = words + 1
        
        for singleLevel in level.getPreviousLevelsRecursively() {
            //          print("SingleLevel: \(singleLevel.data)")
            insert(level: singleLevel)
        }
        
    }
    
    func insert(level: StringPyramidLevel) {
        
        /// every word is divided in chuncks
        /// the longer the word the more we get chuncks
        /// now once we go up the pyramid we take average of each 2 neighbouring characters
        /// that leads us to the very top of the pyramid (the coarse)
        /// the final level is always going to have high depth value
        /// the first level (the base) has depth = 0
        /// so we might get words that are long
        /// and we might haven't yet initialized an array at the index
        /// corresponding to the depth of the given level
        /// so we need to check if the maximum size of the data array
        /// at least has initialzed index at the level depth
        /// if not we initialize a new array at that index
        /// check if the depth of the given level is grater than the size of data array
        /// we need to make sure we have initialized a [float] at that index
        
        while data.count <= level.depth {
            data.append([])
        }
        
        // now just append your level at the index = depth of the level itself
        data[level.depth].append(level)
        
    }
    
    func remove(level: StringPyramidLevel) {
        
        let depth = level.depth
        data[depth] = data[depth].filter { return $0?.stringValue != level.stringValue }
        
    }
    
    func remove(depth: Int) {
        
        guard depth < data.count else { return }
        data[depth].removeAll()
        
    }
    
}
