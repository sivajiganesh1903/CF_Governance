@IsTest
global class JiraCalloutMock implements HttpCalloutMock {
    private Integer statusCode;
    private String status;
    private String responseBody;
    
    public JiraCalloutMock(Integer statusCode, String status, String responseBody) {
        this.statusCode = statusCode;
        this.status = status;
        this.responseBody = responseBody;
    }
    
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setStatus(status);
        response.setBody(responseBody);
        return response;
    }
}