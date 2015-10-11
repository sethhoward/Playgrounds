//: Playground - noun: a place where people can play

import UIKit
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely()

// old way

do {
    func divide(number: CGFloat, by: CGFloat, error: NSErrorPointer) -> CGFloat {
        guard by != 0 else {
            // return what?
            error.memory = NSError(domain: "domain", code: 123, userInfo: nil)
            return -1
        }
        
        return number/by
    }

    var error: NSError? = nil
    let result = divide(100, by: 0, error: &error)
    error
}


// 1.2

do {
    enum Result<T, U> {
        case Success(T)
        case Failure(U)
    }
    
    func divide(number: CGFloat, by: CGFloat) -> Result<CGFloat, String> {
        guard by != 0 else {
            return .Failure("Cannot divide by zero")
        }
        
        return .Success(number/by)
    }
    
    let result = divide(20, by: 0)
    
    switch result {
    case .Success(let quotient):
        quotient
    case .Failure(let errString):
        errString
    }
}

// 2.0

do {
    enum Result<T: Any, U: ErrorType> {
        case Success(T)
        case Failure(U)
    }
    
    enum DivisionError: ErrorType {
        case DivideByZero
        case Unknown(String)
    }
    
    func divide(number: Float, by: Float) -> Result<Float, DivisionError> {
        guard by != 0 else {
            return .Failure(.DivideByZero)
        }
        
        return .Success(number/by)
    }
    
    let result = divide(20, by: 10)
    
    switch result {
    case .Success(let quotient):
        quotient
    case .Failure(let divisionError):
        switch divisionError {
        case .DivideByZero:
            "dividing by zero"
        case .Unknown(let errString):
            errString
        }
    }
}

// 2.0 with chaining

do {
    enum Result<T, U: ErrorType> {
        case Success(T)
        case Failure(U)
        
        func errThen<V>(nextOperation:T -> Result<V, U>) -> Result<V, U> {
            switch self {
            case let .Failure(error): return .Failure(error)
            case let .Success(value): return nextOperation(value)
            }
        }
        
        func then<V>(nextOperation: T -> V) -> Result<V, U> {
            switch self {
            case let .Failure(error): return .Failure(error)
            case let .Success(value): return .Success(nextOperation(value))
            }
        }
    }
    
    enum MathError: ErrorType {
        case DivideByZero
        case Other(String)
    }
    
    func divide(number: CGFloat, by: CGFloat) -> Result<CGFloat, MathError> {
        guard by != 0 else {
            return .Failure(.DivideByZero)
        }
        
        return .Success(number/by)
    }
    
    func magicNumber(quotient: Float) -> Result<Float, MathError> {   // then requires a failure type
        guard quotient != 0 else {
            return .Failure(.Other("log 0"))
        }
        
        return .Success(log(quotient))
    }
    
    func magicNumber2(quotient: Float) -> Float {   // then requires a failure type
        return log(quotient)
    }
    
    let result = divide(0, by: 10).errThen{ quotient in
        magicNumber(Float(quotient))
    }.then(magicNumber2)
}

// 2.0 with try

do {
    enum MathError: ErrorType {
        case DivideByZero
        case Other(String)
    }
    
    func divide(number: CGFloat, by: CGFloat) throws -> CGFloat {
        guard by != 0 else {
            throw MathError.DivideByZero
        }
        
        return number/by
    }
    
    func magicNumber(quotient: Float) throws -> Float {   // then requires a failure type
        guard quotient != 0 else {
            throw MathError.Other("log 0")
        }
        
        return log(quotient)
    }
    
    do {
        let result = try Float(divide(0, by: 20))
        let mResult = try magicNumber(result)
    }
    catch MathError.Other(let errString) {
        errString
    }
    catch {
        "foo"
    }
    
    // in b6 we can also say
    if let result = try? Float(divide(20, by: 0)), let mResult = try? magicNumber(result) {
        result
        mResult
    }
    else {
        "foo"
    }
    
    // divide(20, by: 10) // cannot be run without try
}


// issue async calls

/*

The general concern about Result types is that they are too easy to ignore, and in the space of error handling we wanted the error of omission (i.e., forgetting to think about error handling) to result in a build error.

There is nothing in our model that prevents a Result type from being used, and in fact, it would be very natural to use the Swift 2 error handling model along with a Result type for async and other functions that want to propagate "result|error" values across threads or other boundaries.  What we need is a function to transform an function that throws (which would typically be a closure expr in practice) into a Result, and turn a Result into an value or a thrown error. - Lattner
*/

do {
    enum Result<T, U> {
        case Success(T)
        case Failure(U)
    }
    
    enum MathError: ErrorType {
        case DivideByZero
        case Other(String)
    }
    
    // easy to do but also easy to ignore, much like
    func myAsyncJob(completion: Result<Any, MathError> -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            completion(Result.Failure(MathError.Other("foo error")))
        }
    }
    
    typealias DivideTaskResult = () throws -> CGFloat
    func divide(number: CGFloat, by: CGFloat, completion: DivideTaskResult -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            guard by != 0 else {
                completion { throw MathError.DivideByZero }
                return
            }

            completion{ number/by }
        }
    }
    
    typealias MagicNumberTaskResult = () throws -> Float
    func magicNumber(quotient: Float, completion: MagicNumberTaskResult -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            guard quotient != 0 else {
                completion { throw MathError.Other("log 0") }
                return
            }
            
            completion{ log(quotient) }
        }
    }
    
    divide(20, by: 0) {
        (result: DivideTaskResult) -> Void in
        
        do{
            let r = try result()
        }
        catch (let err) {
            err
        }
    }
    
    // alt
    divide(20, by: 10) {
        do {
            let r = try $0()
            magicNumber(Float(r)) {
                do {
                    let mr = try $0()
                }
                catch(let err) {
                    err
                }
            }
        }
        catch (let err) {
            err
        }
    }
}

