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

class ServerDemo: ServerDelegate {
    private struct User {
        var connection: ServerConnection
        var name = ""
    }

    private var users: [Descriptor: User] = [:]

    private func broadcast(message: String) {
        for (_, user) in users {
            user.connection.sendLine(message)
        }
    }

    func connectionOpened(connection: ServerConnection) {
        print("\(connection) opened")
        connection.sendLine("Greetings! What's your name?")
    }

    func connectionClosed(connection: ServerConnection) {
        print("\(connection) closed")
    }

    func dataReceived(connection: ServerConnection, numberOfBytes: Int) {
        let data = connection.readString().trimmed
        guard !data.isEmpty else {
            return
        }

        print("Received \(numberOfBytes) bytes over \(connection): \(data)")

        if let user = users[connection.descriptor] {
            broadcast("<\(user.name)> \(data)")
        } else {
            users[connection.descriptor] = User(connection: connection, name: data)
            broadcast("\(data) joined the chat")
        }
    }

    func canSendData(connection: ServerConnection, numberOfBytes: Int) {
        print("Can send \(numberOfBytes) bytes over \(connection)")
    }

    func run() throws {
        let port: Port = 12345
        let localhost4 = Address.fromHostname("127.0.0.1")!
        let endpoint4 = Endpoint(address: localhost4, port: port)

        if let server = try? Server(endpoint: endpoint4) {
            // Also add the local IPv6 address as an endpoint.
            if let localhost6 = Address.fromHostname("::1") {
                let endpoint6 = Endpoint(address: localhost6, port: port)
                do {
                    try server.addLocalEndpoint(endpoint6)
                } catch {
                    print("Unable to add IPv6 endpoint")
                }
            }

            server.delegate = self
            print("Server started")

            while true {
                try server.handleEvents()
            }
        }
    }
}

let serverDemo = ServerDemo()
try serverDemo.run()
