//
//  regex.swift
//  SwiftyRegex
//
//  Created by Johannes Schriewer on 06/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import pcre2

/// internal extension to convert a string to an integer array
extension SequenceType where Generator.Element == UInt8 {
    static func fromString(string: String) -> [UInt8] {
        var temp = [UInt8]()
        for c in string.utf8 {
            temp.append(UInt8(c))
        }
        return temp
    }
}

/// Regular expression matcher based on pcre2
public class RegEx {
    private let compiled: COpaquePointer
    
    public let pattern: String
    public let namedCaptureGroups:[String:Int]
    public let numCaptureGroups:Int
    public let canMatchEmptyString:Bool
    
    /// Errors that may be thrown by initializer
    public enum Error: ErrorType {
        /// Invalid pattern, contains error offset and error message from pcre2 engine
        case InvalidPattern(errorOffset: Int, errorMessage: String)
    }
    
    /// Initialize RegEx with pattern
    ///
    /// - parameter pattern: Regular Expression pattern
    /// - throws: RegEx.Error.InvalidPattern when pattern is invalid
    public init(pattern: String) throws {
        self.pattern = pattern
        
        let tmp = [UInt8].fromString(pattern)
        
        var errorNumber:Int32 = 0
        var errorOffset:Int = 0
        compiled = pcre2_compile_8(UnsafePointer<UInt8>(tmp), tmp.count, 0, &errorNumber, &errorOffset, nil)
        if compiled == nil {
            var buffer = [UInt8](count: 256, repeatedValue: 0)
            pcre2_get_error_message_8(errorNumber, &buffer, buffer.count)
            let message = String(CString: UnsafePointer<CChar>(buffer), encoding: NSUTF8StringEncoding)!
            self.namedCaptureGroups = [String:Int]()
            self.numCaptureGroups = 0
            self.canMatchEmptyString = false
            throw RegEx.Error.InvalidPattern(errorOffset: errorOffset, errorMessage: message)
        }

        // number of capture groups
        var patternCount: Int = 0
        pcre2_pattern_info_8(self.compiled, UInt32(PCRE2_INFO_CAPTURECOUNT), &patternCount)
        self.numCaptureGroups = patternCount
        
        // named capture groups
        var named = [String:Int]()
        pcre2_pattern_info_8(self.compiled, UInt32(PCRE2_INFO_NAMECOUNT), &patternCount)
        if patternCount > 0 {
            var name_table = UnsafeMutablePointer<UInt8>()
            var name_entry_size: Int = 0
            
            pcre2_pattern_info_8(self.compiled, UInt32(PCRE2_INFO_NAMETABLE), &name_table)
            pcre2_pattern_info_8(self.compiled, UInt32(PCRE2_INFO_NAMEENTRYSIZE), &name_entry_size)
            
            for i: Int in 0..<patternCount {
                let offset = name_entry_size * i
                let num = (Int(name_table.advancedBy(offset).memory) << 8) + Int(name_table.advancedBy(offset + 1).memory)
                
                // pattern name
                var patternName = [UInt8](count: name_entry_size + 1, repeatedValue: 0)
                for idx in (name_entry_size * i + 2)..<(name_entry_size * (i + 1)) {
                    patternName[idx - (name_entry_size * i + 2)] = name_table[idx]
                }
                
                guard let patternNameString = String(CString: UnsafePointer<CChar>(patternName), encoding: NSUTF8StringEncoding) else {
                    continue
                }

                named[patternNameString] = num
            }
        }
        self.namedCaptureGroups = named
        
        var empty: Int = 0
        pcre2_pattern_info_8(self.compiled, UInt32(PCRE2_INFO_MATCHEMPTY), &empty)
        self.canMatchEmptyString = (empty != 0)
    }
    
    deinit {
        pcre2_code_free_8(self.compiled)
    }
    
    /// Match a string against the pattern
    ///
    /// - parameter string: the string to match
    /// - returns: tuple with matches, named parameters are returned as numbered matches too
    public func match(string: String) -> (numberedParams:[String], namedParams:[String:String]) {
        let match_data = pcre2_match_data_create_from_pattern_8(self.compiled, nil)
        defer {
            pcre2_match_data_free_8(match_data)
        }
        
        let subject = [UInt8].fromString(string)
        let resultCount = pcre2_match_8(self.compiled, subject, subject.count, 0, 0, match_data, nil)
        if resultCount < 0 {
            // no match or error
            return ([], [String:String]())
        }
        
        // get numbered results
        let outVector = pcre2_get_ovector_pointer_8(match_data)
        var params = [String]()
        for i: Int in 0..<Int(resultCount) {
            let startOffset = outVector.advancedBy(i * 2).memory
            let length = outVector.advancedBy(i * 2 + 1).memory
            
            if length == 0 {
                params.append("")
                continue
            }
            
            var subString = [UInt8](count: length + 1, repeatedValue: 0)
            for idx in startOffset..<length {
                subString[idx-startOffset] = subject[idx]
            }
            if let match = String(CString: UnsafePointer<CChar>(subString), encoding: NSUTF8StringEncoding) {
                params.append(match)
            }
        }
        
        // named results
        var named = [String:String]()
        for (grp, num) in self.namedCaptureGroups {
            let startOffset = outVector.advancedBy(2 * num).memory
            let length = outVector.advancedBy(2 * num + 1).memory
            
            if length == 0 {
                named[grp] = ""
                continue
            }
            
            var subString = [UInt8](count: length + 1, repeatedValue: 0)
            for idx in startOffset..<length {
                subString[idx-startOffset] = subject[idx]
            }
            
            if let match = String(CString: UnsafePointer<CChar>(subString), encoding: NSUTF8StringEncoding) {
                named[grp] = match
            }
        }
        
        return (numberedParams: params, namedParams: named)
    }
    
}