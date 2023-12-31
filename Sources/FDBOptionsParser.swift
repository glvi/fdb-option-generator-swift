// -*- mode: swift; coding: utf-8-unix; -*- vi:ai:et:sw=4
//
// Generate Swift bindings for FoundationDB's fdb.option file format
//
// Copyright © 2023 GLVI Gesellschaft für Luftverkehrsinformatik mbH, Hamburg, DE
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see
// <https://www.gnu.org/licenses/>.
//
// Package: fdb-option-generator-swift
//
// Author(s): Kai Lothar John
//
// UUID: CF899A64-A6FD-442A-93FC-3F892D9B6946

import Foundation

/// Event-based XML parser
/// specialised for FoundationDB's `fdb.options` XML file format
class FDBOptionsParser {

    /// Initializes an `fdb.options` parser from a given byte buffer
    ///
    /// - Parameter data: Bytes
    init(data: Data) {
        self._xmlParser = XMLParser(data: data)
    }

    /// Initializes an `fdb.options` parser from a given input stream
    ///
    /// Opens the `stream`, reads data from the `stream` while parsing.
    ///
    /// - Parameter stream: Input stream
    init(stream: InputStream) {
        self._xmlParser = XMLParser(stream: stream)
    }

    /// Initializes an `fdb.options` parser from a given URL
    ///
    /// - Parameter url: URL pointing to an `fdb.options` resource
    init?(contentsOf url: URL) {
        if let xmlParser = XMLParser(contentsOf: url) {
            self._xmlParser = xmlParser
        } else {
            return nil
        }
    }

    /// Delegate receiving parsing events
    var delegate: FDBOptionsParserDelegate? {
        get {
            self._xmlParser.delegate.flatMap{$0 as? _XmlParserDelegate}?._delegate
        }
        set {
            if let newValue {
                self._xmlDelegate = _XmlParserDelegate(delegate: newValue)
                self._xmlParser.delegate = self._xmlDelegate
            } else {
                self._xmlParser.delegate = nil
            }
        }
    }

    /// Parses `fdb.options` data
    ///
    /// If an error occurred during parsing, consult ``parserError``
    ///
    /// - Returns: `true` unless an error occurred during parsing
    func parse() -> Bool {
        _xmlParser.parse()
    }

    /// Contains error information when parsing failed
    var parserError: Error? {
        _xmlParser.parserError
    }

    private var _xmlParser: XMLParser

    private var _xmlDelegate: _XmlParserDelegate? = nil

}

/// The interface an `fdb.options` parser uses to inform its delegate about the content of the parsed document
protocol FDBOptionsParserDelegate {

    /// Invoked by the parser when encountering a `<Scope>` element
    ///
    /// - Parameters:
    ///   - name: value of the XML attribute `name`
    func didStartScope(name: String?)

    /// Invoked by the parser when encountering a `</Scope>` element
    func didEndScope()

    /// Invoked by the parser when encountering an `<Option>` element
    ///
    /// - Parameters:
    ///   - name: value of the XML attribute `name`
    ///   - code: value of the XML attribute `code`
    ///   - description: value of the XML attribute `description`
    ///   - paramType: value of the XML attribute `paramType`
    ///   - paramDescription: value of the XML attribute `paramDescription`
    func didStartOption(name: String, code: String, description desc: String?, paramType: String?, paramDescription: String?)

    /// Invoked by the parser when encountering an `</Option>` element
    func didEndOption()
}

fileprivate class _XmlParserDelegate: NSObject, XMLParserDelegate {

    var _delegate: FDBOptionsParserDelegate? = nil

    init(delegate: FDBOptionsParserDelegate? = nil) {
        self._delegate = delegate
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Scope" {
            _delegate?.didStartScope(name: attributeDict["name"])
        } else if elementName == "Option", let name = attributeDict["name"], let code = attributeDict["code"] {
            _delegate?.didStartOption(
                name: name,
                code: code,
                description: attributeDict["description"],
                paramType: attributeDict["paramType"],
                paramDescription: attributeDict["paramDescription"])
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Scope" {
            _delegate?.didEndScope()
        } else if elementName == "Option" {
            _delegate?.didEndOption()
        }
    }

}

// End of file

// Local Variables:
// indent-tabs-mode: nil
// swift-mode:basic-offset: 4
// End:
