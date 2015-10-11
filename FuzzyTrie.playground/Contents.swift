//
//  DictionaryDataSource.swift
//  Levenshtein
//
//  Created by Seth Howard on 10/6/15.
//  Copyright © 2015 Seth Howard. All rights reserved.
//

import Foundation

////////////////////// LEVENSHTEIN

// https://gist.github.com/natecook1000/add0e5ce654bab231987
func memoize<T1: Hashable, T2: Hashable, U>(body: ((T1, T2) -> U, T1, T2) -> U) -> ((T1, T2) -> U) {
    var memo = [T1: [T2: U]]()
    var result: ((T1, T2) -> U)!
    result = {
        (value1: T1, value2: T2) -> U in
        if let cached = memo[value1]?[value2]{
            return cached
        }
        
        let toCache = body(result, value1, value2)
        if memo[value1] == nil { memo[value1] = [:] }
        memo[value1]![value2] = toCache
        
        return toCache
    }
    
    return result
}

let levenshteinDistance = memoize {
    (levenshteinDistance: (String, String) -> Int, s1: String, s2: String) -> Int in
    guard s1 != "" else { return s2.characters.count }
    guard s2 != "" else { return s1.characters.count }
    
    // drop first letter of each string
    let s1Crop = s1[s1.startIndex.successor()..<s1.endIndex]
    let s2Crop = s2[s2.startIndex.successor()..<s2.endIndex]
    
    // if first characters are equal, continue with both cropped
    if s1[s1.startIndex] == s2[s2.startIndex] {
        return levenshteinDistance(s1Crop, s2Crop)
    }
    
    // otherwise find smallest of the three options
    let (c1, c2, c3) = (levenshteinDistance(s1Crop, s2), levenshteinDistance(s1, s2Crop), levenshteinDistance(s1Crop, s2Crop))
    
    return 1 + min(min(c1, c2), c3)
}

///////////// TRIE

func buildStringTrie(words: [String]) -> Trie<Character> {
    let emptyTrie = Trie<Character>()
    
    return words.reduce(emptyTrie) {
        trie, word in
        trie.insert(Array(word.characters))
    }
}

func autoCompleteString(knownWords: Trie<Character>, word: String) -> [String] {
    let chars = Array(word.characters)
    let completed = knownWords.autocomplete(chars)
    
    return completed.map { chars in
        word + String(chars)
    }
}

struct Trie<T: Hashable> {
    let isElement: Bool
    let children: [T: Trie<T>]
}

extension Trie {
    init() {
        isElement = false
        children = [:]
    }
    
    init(_ key: [T]) {
        if let (head, tail) = key.decompose {
            let children = [head: Trie(tail)]
            self = Trie(isElement: false, children: children)
        }
        else {
            self = Trie(isElement: true, children: [:])
        }
    }
    
    var elements: [[T]] {
        var result: [[T]] = isElement ? [[]] : []
        for(key, value) in children {
            result += value.elements.map { [key] + $0 }
        }
        
        return result
    }
}

extension Trie {
    func insert(key: [T]) -> Trie<T> {
        guard let (head, tail) = key.decompose else {
            return Trie(isElement: true, children: children)
        }
        
        var newChildren = children
        
        if let nextTrie = children[head] {
            newChildren[head] = nextTrie.insert(tail)
        }
        else {
            newChildren[head] = Trie(tail)
        }
        
        return Trie(isElement: isElement, children: newChildren)
    }
}

extension Trie {
    private func withPrefix(prefix: [T]) -> Trie<T>? {
        guard let (head, tail) = prefix.decompose else { return self }
        guard let remainder = children[head] else { return nil }
        return remainder.withPrefix(tail)
    }
    
    func autocomplete(key: [T]) -> [[T]] {
        return withPrefix(key)?.elements ?? []
    }
}

extension Array {
    var decompose: (head: Element, tail: [Element])? {
        return isEmpty ? nil : (self[0], Array(self[1..<count]))
    }
}


/// IMPLEMENTATION


let words = ["wood", "woof", "banana", "ban", "wooden", "bent", "big", "ben", "baby", "burp", "banter"]
let trie: Trie<Character> = buildStringTrie(words)


struct WordResult {
    let str: String
    let rank: Int
}

func search(word: String, trie: Trie<Character>) -> [WordResult] {
    let size = word.characters.count
    var results = [WordResult]()
    
    if  size > 0 {
        // for each letter in ther oot map which matches with a letter in the word, we must call search
        for var i = 0; i < /*size*/ 1; ++i {
            let matches = autoCompleteString(trie, word:String([word.characters.first!]))
            
            for match in matches {
                if match.characters.count < size || match.characters.count > size + 1 {
                    continue
                }

                let endIndex = match.startIndex.advancedBy(size)
                let trimmedw = match.substringToIndex(endIndex)

                let d = levenshteinDistance(word, trimmedw)
                if d  < 2 {
                    results.append(WordResult(str: match, rank: d))
                }
            }
            
        }
    }
    
    return results.sort ({ $0.rank < $1.rank })
}

/// FIRE

let r = search("bantna", trie: trie).map { $0.str }
r
