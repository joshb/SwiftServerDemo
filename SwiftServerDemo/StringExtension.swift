/*
 * Copyright (C) 2015 Josh A. Beam
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

extension String {
    /// The string's character count.
    var length: Int {
        return self.characters.count
    }
    
    /// Gets a substring of the string.
    ///
    /// - parameter startIndex: The starting index to create the substring from.
    /// - parameter length: The length of the substring.
    /// - returns: A substring from the starting index and with the given length.
    func substring(startIndex: Int, length: Int) -> String {
        return self.substringWithRange(Range<String.Index>(start: self.startIndex.advancedBy(startIndex),
            end: self.startIndex.advancedBy(startIndex + length)))
    }

    /// Gets a substring of the string.
    ///
    /// - parameter startIndex: The starting index to create the substring from.
    /// - returns: A substring from the starting index up to the end of the string.
    func substring(startIndex: Int) -> String {
        return self.substringWithRange(Range<String.Index>(start: self.startIndex.advancedBy(startIndex),
            end: self.endIndex))
    }

    /// Checks whether or not the given character is a whitespace character.
    ///
    /// - parameter c: The character to check.
    /// - returns: true if the character is a whitespace character, false otherwise.
    static func isWhitespace(c: Character) -> Bool {
        return c == " " || c == "\r" || c == "\n" || c == "\r\n" || c == "\t"
    }

    /// A copy of the string with all beginning and trailing whitespace characters removed.
    var trimmed: String {
        var s = self

        while !s.isEmpty && String.isWhitespace(s.characters[s.startIndex]) {
            s = s.substring(1)
        }

        while !s.isEmpty && String.isWhitespace(s.characters[s.endIndex.predecessor()]) {
            s = s.substring(0, length: s.length - 1)
        }

        return s
    }
}