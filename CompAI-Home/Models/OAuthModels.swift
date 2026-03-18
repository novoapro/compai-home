// CompAI-Home/Models/OAuthModels.swift
import Foundation

struct OAuthCredential: Codable, Identifiable, Equatable {
    let id: UUID
    let clientId: String
    let clientSecret: String
    var name: String
    let createdAt: Date
    var lastUsedAt: Date?
    var isRevoked: Bool

    init(id: UUID = UUID(), clientId: String, clientSecret: String, name: String, createdAt: Date = Date(), lastUsedAt: Date? = nil, isRevoked: Bool = false) {
        self.id = id
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.name = name
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isRevoked = isRevoked
    }
}

struct OAuthToken: Codable, Identifiable {
    let id: UUID
    let accessToken: String
    let refreshToken: String
    let credentialId: UUID
    let expiresAt: Date
    let refreshTokenExpiresAt: Date
    let scopes: Set<String>

    init(id: UUID = UUID(), accessToken: String, refreshToken: String, credentialId: UUID, expiresAt: Date, refreshTokenExpiresAt: Date, scopes: Set<String> = ["*"]) {
        self.id = id
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.credentialId = credentialId
        self.expiresAt = expiresAt
        self.refreshTokenExpiresAt = refreshTokenExpiresAt
        self.scopes = scopes
    }

    var isExpired: Bool { Date() >= expiresAt }
    var isRefreshExpired: Bool { Date() >= refreshTokenExpiresAt }
}

struct OAuthAuthorizationCode {
    let code: String
    let clientId: String
    let codeChallenge: String
    let redirectURI: String
    let scopes: Set<String>
    let state: String?
    let expiresAt: Date

    var isExpired: Bool { Date() >= expiresAt }
}
