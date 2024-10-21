//
//  DatabaseError.swift
//  Browser
//
//  Created by Florian Kugler on 16.10.24.
//
import SQLite3
import Foundation


struct DatabaseError: Error {
    var code: Int32
    var message: String
}

actor Database {
    var connection: OpaquePointer?
    
    init(url: URL) throws {
        var connection: OpaquePointer?
        try checkError {
            url.absoluteString.withCString { str in
                sqlite3_open(str, &connection)
            }
        }
        self.connection = connection
    }
    
    func setup() throws {
        let query = """
        CREATE TABLE PageData (
            id TEXT PRIMARY KEY NOT NULL,
            lastUpdated INTEGER NOT NULL,
            url TEXT NOT NULL,
            title TEXT NOT NULL,
            fullText TEXT,
            snapshot BLOB
        );
        """
        var statement: OpaquePointer?
        try checkError {
            query.withCString { cStr in
                sqlite3_prepare_v3(connection, cStr, -1, 0, &statement, nil)
            }
        }
        let code = sqlite3_step(statement)
        guard code == SQLITE_DONE else {
            try checkError { code }
            return // todo throw an error as well?
        }
        try checkError { sqlite3_finalize(statement) }
        print("DONE")
    }
}

func checkError(_ fn: () -> Int32) throws {
    let code = fn()
    guard code == SQLITE_OK else {
        let str = String(cString: sqlite3_errstr(code))
        throw DatabaseError(code: code, message: str)
    }
}


func test() {
    Task {
        do {
            let url = URL.downloadsDirectory.appending(path: "db.sqlite")
            let db = try Database(url: url)
        } catch {
            print("Error", error)
        }
    }
}
