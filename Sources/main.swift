import Kitura

import LoggerAPI
import HeliumLogger

import Credentials
import CredentialsHTTP

import PerfectCrypto
import Foundation

// MARK: NEVER DO THIS IN PRODUCTION! PRIVATE KEYS SHOULD BE KEPT SECURE!
let publicKey = "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQAB\n-----END PUBLIC KEY-----\n"
let privateKey =  "-----BEGIN RSA PRIVATE KEY-----\nMIICWwIBAAKBgQDdlatRjRjogo3WojgGHFHYLugdUWAY9iR3fy4arWNA1KoS8kVw33cJibXr8bvwUAUparCwlvdbH6dvEOfou0/gCFQsHUfQrSDv+MuSUMAe8jzKE4qW+jK+xQU9a03GUnKHkkle+Q0pX/g6jXZ7r1/xAK5Do2kQ+X5xK9cipRgEKwIDAQABAoGAD+onAtVye4ic7VR7V50DF9bOnwRwNXrARcDhq9LWNRrRGElESYYTQ6EbatXS3MCyjjX2eMhu/aF5YhXBwkppwxg+EOmXeh+MzL7Zh284OuPbkglAaGhV9bb6/5CpuGb1esyPbYW+Ty2PC0GSZfIXkXs76jXAu9TOBvD0ybc2YlkCQQDywg2R/7t3Q2OE2+yo382CLJdrlSLVROWKwb4tb2PjhY4XAwV8d1vy0RenxTB+K5Mu57uVSTHtrMK0GAtFr833AkEA6avx20OHo61Yela/4k5kQDtjEf1N0LfI+BcWZtxsS3jDM3i1Hp0KSu5rsCPb8acJo5RO26gGVrfAsDcIXKC+bQJAZZ2XIpsitLyPpuiMOvBbzPavd4gY6Z8KWrfYzJoI/Q9FuBo6rKwl4BFoToD7WIUS+hpkagwWiz+6zLoX1dbOZwJACmH5fSSjAkLRi54PKJ8TFUeOP15h9sQzydI8zJU+upvDEKZsZc/UhT/SySDOxQ4G/523Y0sz/OZtSWcol/UMgQJALesy++GdvoIDLfJX5GBQpuFgFenRiRDabxrE9MNUZ2aPFaFp+DyAe+b4nDwuJaW2LURbr8AEZga7oQj0uYxcYw==\n-----END RSA PRIVATE KEY-----\n"

// Setup logger
Log.logger = HeliumLogger(.info)

// Setup basic credentials middleware
let credentials = Credentials()
let users = ["username" : "password"]
let httpBasic = CredentialsHTTPBasic(verifyPassword: { userId, password, callback in
    if let storedPassword = users[userId], storedPassword == password {
        Log.info("\(userId) logged in")
        callback(UserProfile(id: userId, displayName: userId, provider: "HTTPBasic"))
    } else {
        Log.error("\(userId) login failed")
        callback(nil)
    }
})
credentials.register(plugin: httpBasic)

// Setup JWT middleware
class JWTMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
        func sendAuthFailed() {
            do {
                response.send("authorization failed\n")
                try response.status(.unauthorized).end()
            } catch {
                Log.error("failed to set unauthorized status: \(error)")
            }
        }

        if let authHeader = request.headers["Authorization"] {
            let signedJWTToken = authHeader.components(separatedBy: " ")[1]
            do {
                guard let jwt = JWTVerifier(signedJWTToken) else {
                    Log.error("failed to verify \(signedJWTToken)")
                    sendAuthFailed()
                    return
                }
                let publicKeyAsPem = try PEMKey(source: publicKey)
            	try jwt.verify(algo: .rs256, key: publicKeyAsPem)
                guard let issuer = jwt.payload["issuer"] as? String,
                    let issuedAtInterval = jwt.payload["issuedAt"] as? Double,
                    let expirationInterval = jwt.payload["expiration"] as? Double else {
                    Log.error("couldn't find issuer, issuedAt, and expiration in \(jwt.payload)")
                    sendAuthFailed()
                    return
                }
                Log.info("*token verified*")
                Log.info("issuer: \(issuer)")
                Log.info("issuedAt: \(Date(timeIntervalSince1970: issuedAtInterval))")
                Log.info("expiration: \(Date(timeIntervalSince1970: expirationInterval))")
                next()
                return
            } catch {
                Log.error("failed to decode or validate \(signedJWTToken): \(error)")
            }
        } else {
            Log.error("no authorization header")
        }
        sendAuthFailed()
    }
}
let jwtMiddleware = JWTMiddleware()

// Create logging middleware
class RequestLogger: RouterMiddleware {
    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.info("\(request.method) request made for \(request.originalURL)")
        next()
    }
}

// Create a new router
let router = Router()

// Setup routes
router.all("/*", middleware: RequestLogger())
router.all("/login", middleware: credentials)
router.all("/secure", middleware: jwtMiddleware)

// Route requests
router.get("/") { request, response, next in
    response.send(json: ["message": "Hello from Swift!"])
    next()
}
router.get("/login") { request, response, next in
    let jwtPayload: [String : Any] = [
        "issuer": "udacity.swift.monolith",
        "issuedAt": Date().timeIntervalSince1970,
        "expiration": Date().append(months: 1).timeIntervalSince1970
    ]
    guard let jwt = JWTCreator(payload: jwtPayload) else {
        response.send("couldn't create token\n")
        next()
        return
    }
    let privateKeyAsPem = try PEMKey(source: privateKey)
    let signedJWTToken = try jwt.sign(alg: .rs256, key: privateKeyAsPem)
    response.send(json: ["token": signedJWTToken])
    next()
}
router.get("/secure") { request, response, next in
    response.send(json: ["message": "Secure hello from Swift!"])
    next()
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
