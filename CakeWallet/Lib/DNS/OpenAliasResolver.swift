//
//  OpenAliasResolver.swift
//  CakeWalletLib
//
//  Created by Tanner Silva on 2/7/20.
//  Copyright © 2020 Mykola Misiura. All rights reserved.
//

import Foundation
import Socket
import SSLService

fileprivate let oaQueue = DispatchQueue(label: "com.cakewallet.openaliasResolver", attributes:[.concurrent])

public class OpenAlias {
    public enum ResolutionError: Error {
        case unexpectedResponse
        case queryTimeout
        case invalidTimeout
    }
    
    private static let defaultSSLConfig = SSLService.Configuration.init(withCipherSuite: "ALL", clientAllowsSelfSignedCertificates: false, embeddedServerCertPaths: nil)
    
    private class func getSerializedTCPDNSRequest(query inputQueryName:String) throws -> Data {
        var newRequest = Message(type:.query, questions:[Question(name:inputQueryName, type:.text)])
        newRequest.recursionAvailable = true
        newRequest.recursionDesired = true
        return try newRequest.serializeTCP()
    }
    
    private class func resolveOverTLS(request:Data, endpoint:String="1.1.1.1", port:Int32=853, timeoutSeconds:TimeInterval) throws -> (name:String?, address:String) {
        guard timeoutSeconds > 0 else {
            throw OpenAlias.ResolutionError.invalidTimeout
        }
        
        let socket = try Socket.create(family:.inet, type:Socket.SocketType.stream, proto:Socket.SocketProtocol.tcp)
        socket.delegate = try SSLService(usingConfiguration:SSLService.Configuration.init(withCipherSuite: "ALL", clientAllowsSelfSignedCertificates: false, embeddedServerCertPaths: nil))
        try socket.connect(to:endpoint, port:port, timeout:UInt(timeoutSeconds*1000))
        var readData = Data()
        try socket.write(from:request)
        try socket.setReadTimeout(value: UInt(timeoutSeconds*1000))
        repeat {
            do {
                usleep(100000)
                try socket.read(into:&readData)
            } catch _ {
                socket.close()
                throw OpenAlias.ResolutionError.queryTimeout
            }
        } while (readData.count == 0)
        let response = try Message.init(deserializeTCP: readData)
        for (_, curAnswer) in response.answers.enumerated() {
            if let textResponse = curAnswer as? TextRecord, let openaliasXMRAddress = textResponse.attributes["oa1:xmr recipient_address"] {
                if let hasRecipientName = textResponse.attributes["recipient_name"] {
                    socket.close()
                    return (name:hasRecipientName, address:openaliasXMRAddress)
                } else {
                    socket.close()
                    return (name:nil, address:openaliasXMRAddress)
                }
            }
        }
        socket.close()
        throw OpenAlias.ResolutionError.unexpectedResponse
    }

    public class func resolve(jobID:UInt64, query:String, _ success:@escaping (UInt64, String, String?) -> Void) {
        oaQueue.async {
            do {
                let requestData = try Self.getSerializedTCPDNSRequest(query: query)
                let resolvedAddress = try Self.resolveOverTLS(request: requestData, timeoutSeconds: 5)
                success(jobID, resolvedAddress.address, resolvedAddress.name)
            } catch _ {
                print("[OPENALIAS] failed to resolve job id: \(jobID)")
            }
        }
    }
}
