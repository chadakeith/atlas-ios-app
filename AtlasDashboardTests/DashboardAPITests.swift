import Foundation
import Testing
@testable import AtlasDashboard

struct DashboardAPITests {
    private let base = URL(string: "https://dashboard.atlassolutions.tech")!

    @Test func buildsEndpointURLs() {
        let plain = DashboardAPI.makeURL(base: base, path: "/overview", query: [])
        #expect(plain?.absoluteString == "https://dashboard.atlassolutions.tech/overview")

        let forced = DashboardAPI.makeURL(base: base, path: "overview", query: [URLQueryItem(name: "force", value: "true")])
        #expect(forced?.absoluteString == "https://dashboard.atlassolutions.tech/overview?force=true")

        let nested = DashboardAPI.makeURL(base: base, path: "/productivity/api/summary", query: [])
        #expect(nested?.path() == "/productivity/api/summary")
    }

    @Test func normalizesServerInput() {
        #expect(AppModel.normalizeServer("dashboard.atlassolutions.tech")?.absoluteString == "https://dashboard.atlassolutions.tech")
        #expect(AppModel.normalizeServer("  https://dashboard.atlassolutions.tech/  ")?.absoluteString == "https://dashboard.atlassolutions.tech")
        #expect(AppModel.normalizeServer("http://192.168.1.20:8088/")?.absoluteString == "http://192.168.1.20:8088")
        #expect(AppModel.normalizeServer("") == nil)
        #expect(AppModel.normalizeServer("https://") == nil)
    }

    @Test func jsonResponseOnSameHostPasses() throws {
        let response = HTTPURLResponse(url: base.appending(path: "overview"), statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        try DashboardAPI.checkForLoginWall(response, expectedHost: "dashboard.atlassolutions.tech")
    }

    @Test func htmlResponseMeansLoginWall() {
        let response = HTTPURLResponse(url: base.appending(path: "overview"), statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "text/html; charset=utf-8"])!
        #expect(throws: APIError.self) {
            try DashboardAPI.checkForLoginWall(response, expectedHost: "dashboard.atlassolutions.tech")
        }
    }

    @Test func redirectToAnotherHostMeansLoginWall() {
        let google = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        let response = HTTPURLResponse(url: google, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        #expect(throws: APIError.self) {
            try DashboardAPI.checkForLoginWall(response, expectedHost: "dashboard.atlassolutions.tech")
        }
    }

    @Test func forbiddenMeansLoginWall() {
        let response = HTTPURLResponse(url: base, statusCode: 403, httpVersion: nil, headerFields: nil)!
        #expect(throws: APIError.self) {
            try DashboardAPI.checkForLoginWall(response, expectedHost: "dashboard.atlassolutions.tech")
        }
    }

    @Test func hostComparisonIgnoresCase() throws {
        let response = HTTPURLResponse(url: URL(string: "https://Dashboard.AtlasSolutions.tech/overview")!, statusCode: 200,
                                       httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        try DashboardAPI.checkForLoginWall(response, expectedHost: "dashboard.atlassolutions.tech")
    }
}
