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
// UUID: B9D34CC5-5241-4E88-9B29-2C66C555E039

import Foundation

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        self.write(data)
    }
}

// End of file

// Local Variables:
// indent-tabs-mode: nil
// swift-mode:basic-offset: 4
// End:
