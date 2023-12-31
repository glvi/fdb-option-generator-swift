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
// UUID: 1C57FFB9-3637-4D05-B4B7-AF7B5636E778

import Foundation

class MyFDBOptionsParserDelegate: NSObject, FDBOptionsParserDelegate {

    var networkOptions: [String: FDBOption] = [:]
    var databaseOptions: [String: FDBOption] = [:]
    var transactionOptions: [String: FDBOption] = [:]

    private var scope: Scope? = nil

    func didStartScope(name: String?) {
        scope = if let name {
            switch name {
            case "NetworkOption": .network
            case "DatabaseOption": .database
            case "TransactionOption": .transaction
            default: .none
            }
        } else {
            .none
        }
    }

    func didEndScope() {
        scope = .none
    }

    func didStartOption(name: String, code: String, description desc: String? = nil, paramType: String? = nil, paramDescription: String? = nil) {
        switch scope {
        case .network: networkOption(
            name: name,
            code: code,
            desc: desc,
            paramType: paramType,
            paramDesc: paramDescription)
        case .database: databaseOption(
            name: name,
            code: code,
            desc: desc,
            paramType: paramType,
            paramDesc: paramDescription)
        case .transaction: transactionOption(
            name: name,
            code: code,
            desc: desc,
            paramType: paramType,
            paramDesc: paramDescription)
        default: break
        }
    }

    func didEndOption() {
        // Empty by design
    }

    private func networkOption(name: String, code: String, desc: String? = nil, paramType: String?, paramDesc: String?) {
        if let paramType  {
            networkOptions[name] = FDBOption(
                code: code, description: desc,
                parameter: FDBOptionParameter(type: paramType, description: paramDesc))
        } else {
            networkOptions[name] = FDBOption(code: code, description: desc)
        }
    }

    private func databaseOption(name: String, code: String, desc: String? = nil, paramType: String?, paramDesc: String?) {
        if let paramType  {
            databaseOptions[name] = FDBOption(
                code: code, description: desc,
                parameter: FDBOptionParameter(type: paramType, description: paramDesc))
        } else {
            databaseOptions[name] = FDBOption(code: code, description: desc)
        }
    }

    private func transactionOption(name: String, code: String, desc: String? = nil, paramType: String?, paramDesc: String?) {
        if let paramType  {
            transactionOptions[name] = FDBOption(
                code: code, description: desc,
                parameter: FDBOptionParameter(type: paramType, description: paramDesc))
        } else {
            transactionOptions[name] = FDBOption(code: code, description: desc)
        }
    }

}
// End of file

// Local Variables:
// indent-tabs-mode: nil
// swift-mode:basic-offset: 4
// End:
