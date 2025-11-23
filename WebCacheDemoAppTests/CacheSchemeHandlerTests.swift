import XCTest
@testable import WebCacheDemoApp

final class CacheSchemeHandlerTests: XCTestCase {
    
    var handler: CacheSchemeHandler!
    
    override func setUp() {
        super.setUp()
        handler = CacheSchemeHandler()
    }
    
    override func tearDown() {
        handler = nil
        super.tearDown()
    }
    
    // MARK: - HTTP Method Tests
    
    func testIsAPICall_WithPOSTMethod_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "POST method should be detected as API call")
    }
    
    func testIsAPICall_WithPUTMethod_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "PUT method should be detected as API call")
    }
    
    func testIsAPICall_WithDELETEMethod_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "DELETE method should be detected as API call")
    }
    
    func testIsAPICall_WithPATCHMethod_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "PATCH method should be detected as API call")
    }
    
    func testIsAPICall_WithGETMethod_ReturnsFalse() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "GET method should not be detected as API call")
    }
    
    func testIsAPICall_WithLowercasePOSTMethod_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.httpMethod = "post"
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Lowercase POST method should be detected as API call")
    }
    
    // MARK: - URL Path Pattern Tests
    
    func testIsAPICall_WithAPIPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/api/users")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /api/ path should be detected as API call")
    }
    
    func testIsAPICall_WithRESTPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/rest/data")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /rest/ path should be detected as API call")
    }
    
    func testIsAPICall_WithGraphQLPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/graphql")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /graphql path should be detected as API call")
    }
    
    func testIsAPICall_WithGraphiQLPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/graphiql")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /graphiql path should be detected as API call")
    }
    
    func testIsAPICall_WithVersionedPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/v1/users")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /v1/ path should be detected as API call")
    }
    
    func testIsAPICall_WithV2Path_ReturnsTrue() {
        let url = URL(string: "https://example.com/v2/data")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /v2/ path should be detected as API call")
    }
    
    func testIsAPICall_WithEndpointPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/endpoint")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /endpoint path should be detected as API call")
    }
    
    func testIsAPICall_WithServicePath_ReturnsTrue() {
        let url = URL(string: "https://example.com/service")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /service path should be detected as API call")
    }
    
    func testIsAPICall_WithRPCPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/rpc")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /rpc path should be detected as API call")
    }
    
    func testIsAPICall_WithOAuthPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/oauth/token")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /oauth path should be detected as API call")
    }
    
    func testIsAPICall_WithAuthPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/auth/login")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /auth path should be detected as API call")
    }
    
    func testIsAPICall_WithTokenPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/token")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /token path should be detected as API call")
    }
    
    func testIsAPICall_WithWebhookPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/webhook")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /webhook path should be detected as API call")
    }
    
    func testIsAPICall_WithCallbackPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/callback")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with /callback path should be detected as API call")
    }
    
    func testIsAPICall_WithStaticResourcePath_ReturnsFalse() {
        let url = URL(string: "https://example.com/static/script.js")!
        let request = URLRequest(url: url)
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "Static resource path should not be detected as API call")
    }
    
    // MARK: - Content-Type Header Tests
    
    func testIsAPICall_WithJSONContentType_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with application/json Content-Type should be detected as API call")
    }
    
    func testIsAPICall_WithXMLContentType_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with application/xml Content-Type should be detected as API call")
    }
    
    func testIsAPICall_WithFormURLEncodedContentType_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with form-urlencoded Content-Type should be detected as API call")
    }
    
    func testIsAPICall_WithMultipartFormDataContentType_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("multipart/form-data; boundary=something", forHTTPHeaderField: "Content-Type")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with multipart/form-data Content-Type should be detected as API call")
    }
    
    func testIsAPICall_WithSOAPContentType_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/soap+xml", forHTTPHeaderField: "Content-Type")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with SOAP Content-Type should be detected as API call")
    }
    
    func testIsAPICall_WithProtobufContentType_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with protobuf Content-Type should be detected as API call")
    }
    
    func testIsAPICall_WithTextHTMLContentType_ReturnsFalse() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "Request with text/html Content-Type should not be detected as API call")
    }
    
    // MARK: - Accept Header Tests
    
    func testIsAPICall_WithJSONAcceptHeader_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with application/json Accept header should be detected as API call")
    }
    
    func testIsAPICall_WithXMLAcceptHeader_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with application/xml Accept header should be detected as API call")
    }
    
    func testIsAPICall_WithVndAPIJSONAcceptHeader_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with vnd.api+json Accept header should be detected as API call")
    }
    
    func testIsAPICall_WithHALJSONAcceptHeader_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/hal+json", forHTTPHeaderField: "Accept")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with hal+json Accept header should be detected as API call")
    }
    
    func testIsAPICall_WithProblemJSONAcceptHeader_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource")!
        var request = URLRequest(url: url)
        request.setValue("application/problem+json", forHTTPHeaderField: "Accept")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with problem+json Accept header should be detected as API call")
    }
    
    // MARK: - Query Parameter Tests
    
    func testIsAPICall_WithCallbackQueryParam_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource?callback=myFunction")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with callback query parameter should be detected as API call")
    }
    
    func testIsAPICall_WithFormatJSONQueryParam_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource?format=json")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with format=json query parameter should be detected as API call")
    }
    
    func testIsAPICall_WithFormatXMLQueryParam_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource?format=xml")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with format=xml query parameter should be detected as API call")
    }
    
    func testIsAPICall_WithAPIKeyQueryParam_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource?api_key=12345")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with api_key query parameter should be detected as API call")
    }
    
    func testIsAPICall_WithAccessTokenQueryParam_ReturnsTrue() {
        let url = URL(string: "https://example.com/resource?access_token=abc123")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with access_token query parameter should be detected as API call")
    }
    
    // MARK: - Host/Subdomain Pattern Tests
    
    func testIsAPICall_WithAPISubdomain_ReturnsTrue() {
        let url = URL(string: "https://api.example.com/resource")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with api. subdomain should be detected as API call")
    }
    
    func testIsAPICall_WithRESTSubdomain_ReturnsTrue() {
        let url = URL(string: "https://rest.example.com/resource")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with rest. subdomain should be detected as API call")
    }
    
    func testIsAPICall_WithServiceSubdomain_ReturnsTrue() {
        let url = URL(string: "https://service.example.com/resource")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with service. subdomain should be detected as API call")
    }
    
    func testIsAPICall_WithBackendSubdomain_ReturnsTrue() {
        let url = URL(string: "https://backend.example.com/resource")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with backend. subdomain should be detected as API call")
    }
    
    func testIsAPICall_WithServerSubdomain_ReturnsTrue() {
        let url = URL(string: "https://server.example.com/resource")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with server. subdomain should be detected as API call")
    }
    
    // MARK: - File Extension Tests
    
    func testIsAPICall_WithJSONExtensionAndAPIPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/api/data.json")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with .json extension and /api/ path should be detected as API call")
    }
    
    func testIsAPICall_WithXMLExtensionAndAPIPath_ReturnsTrue() {
        let url = URL(string: "https://example.com/api/data.xml")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with .xml extension and /api/ path should be detected as API call")
    }
    
    func testIsAPICall_WithJSExtension_ReturnsFalse() {
        let url = URL(string: "https://example.com/script.js")!
        let request = URLRequest(url: url)
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "URL with .js extension should not be detected as API call")
    }
    
    func testIsAPICall_WithCSSExtension_ReturnsFalse() {
        let url = URL(string: "https://example.com/style.css")!
        let request = URLRequest(url: url)
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "URL with .css extension should not be detected as API call")
    }
    
    func testIsAPICall_WithPNGExtension_ReturnsFalse() {
        let url = URL(string: "https://example.com/image.png")!
        let request = URLRequest(url: url)
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "URL with .png extension should not be detected as API call")
    }
    
    // MARK: - Combined Tests
    
    func testIsAPICall_WithMultipleAPIIndicators_ReturnsTrue() {
        let url = URL(string: "https://api.example.com/v1/users?format=json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "Request with multiple API indicators should be detected as API call")
    }
    
    func testIsAPICall_WithStaticResource_ReturnsFalse() {
        let url = URL(string: "https://example.com/static/script.js")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/javascript", forHTTPHeaderField: "Content-Type")
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "Static resource should not be detected as API call")
    }
    
    func testIsAPICall_WithHTMLPage_ReturnsFalse() {
        let url = URL(string: "https://example.com/index.html")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/html", forHTTPHeaderField: "Content-Type")
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "HTML page should not be detected as API call")
    }
    
    // MARK: - Edge Cases
    
    func testIsAPICall_WithNilHTTPMethod_ReturnsFalse() {
        let url = URL(string: "https://example.com/resource")!
        let request = URLRequest(url: url)
        // httpMethod is nil by default
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "Request with nil HTTP method should default to GET and not be detected as API call")
    }
    
    func testIsAPICall_WithEmptyPath_ReturnsFalse() {
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        XCTAssertFalse(handler.isAPICall(request: request, url: url), "URL with empty path should not be detected as API call")
    }
    
    func testIsAPICall_WithCaseInsensitivePath_ReturnsTrue() {
        let url = URL(string: "https://example.com/API/users")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with uppercase /API/ path should be detected as API call (case insensitive)")
    }
    
    func testIsAPICall_WithCaseInsensitiveSubdomain_ReturnsTrue() {
        let url = URL(string: "https://API.example.com/resource")!
        let request = URLRequest(url: url)
        
        XCTAssertTrue(handler.isAPICall(request: request, url: url), "URL with uppercase API subdomain should be detected as API call (case insensitive)")
    }
}

