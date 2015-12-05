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

enum ServerError: ErrorType {
    case UnableToCreateKQueue, UnableToCreateSocket, UnableToAcceptConnection
}

protocol ServerDelegate {
    func connectionOpened(connection: ServerConnection)
    func connectionClosed(connection: ServerConnection)
    func dataReceived(connection: ServerConnection, numberOfBytes: Int)
    func canSendData(connection: ServerConnection, numberOfBytes: Int)
}

class Server {
    var delegate: ServerDelegate?

    private var kqueueDescriptor: Descriptor
    private var events: [kevent] = []

    private var localEndpoints: [Descriptor: Endpoint] = [:]
    private var connections: [Descriptor: ServerConnection] = [:]

    init(endpoint: Endpoint) throws {
        kqueueDescriptor = kqueue()
        guard kqueueDescriptor != -1 else {
            throw ServerError.UnableToCreateKQueue
        }

        for _ in 0..<100 {
            events.append(kevent())
        }

        try addLocalEndpoint(endpoint)
    }

    deinit {
        close(kqueueDescriptor)
    }

    func addLocalEndpoint(endpoint: Endpoint) throws {
        if let socketDescriptor = ServerUtil.createSocket(endpoint) {
            localEndpoints[socketDescriptor] = endpoint
            ServerUtil.addKEvent(kqueueDescriptor, socketDescriptor: socketDescriptor)
        } else {
            throw ServerError.UnableToCreateSocket
        }
    }

    private func handleConnection(descriptor: Descriptor, localEndpoint: Endpoint) throws {
        let pair = ServerUtil.acceptConnection(descriptor, localEndpoint: localEndpoint)
        guard pair != nil else {
            throw ServerError.UnableToAcceptConnection
        }

        let (remoteDescriptor, remoteEndpoint) = pair!
        let connection = ServerConnection(descriptor: remoteDescriptor, localEndpoint: localEndpoint, remoteEndpoint: remoteEndpoint)
        connections[remoteDescriptor] = connection
        ServerUtil.addKEvent(kqueueDescriptor, socketDescriptor: remoteDescriptor, readOnly: false)

        delegate?.connectionOpened(connection)
    }

    private func closeConnection(connection: ServerConnection) {
        close(connection.descriptor)
        connections[connection.descriptor] = nil
        delegate?.connectionClosed(connection)
    }

    private func handleReadEvent(event: kevent, connection: ServerConnection) {
        if event.data == 0 {
            closeConnection(connection)
            return
        }

        delegate?.dataReceived(connection, numberOfBytes: event.data)

        if connection.shouldClose {
            closeConnection(connection)
        }
    }

    private func handleEvent(event: kevent) throws {
        let descriptor = Descriptor(event.ident)

        if let endpoint = localEndpoints[descriptor] {
            try handleConnection(descriptor, localEndpoint: endpoint)
            return
        }

        if let connection = connections[descriptor] {
            switch Int32(event.filter) {
                case EVFILT_READ:
                    handleReadEvent(event, connection: connection)

                case EVFILT_WRITE:
                    delegate?.canSendData(connection, numberOfBytes: event.data)

                default:
                    break
            }
        }
    }

    func handleEvents() throws {
        let numEvents = Int(kevent(kqueueDescriptor, nil, 0, &events, Int32(events.count), nil))
        for i in 0..<numEvents {
            let event = self.events[i]
            try handleEvent(event)
        }
    }
}
