global class GetSessionID_LWC {
    global static String getSessionIdFromVFPage(PageReference visualforcePage){
        String content;
        if(!Test.isRunningTest()){
        content = visualforcePage.getContent().toString();
        }
        if(Test.isRunningTest()){
            String sessionId = '123456789';
            content = 'Start_Of_Session_Id'+sessionid+'End_Of_Session_Id';
        }
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                e = content.indexOf('End_Of_Session_Id');
        return content.substring(s, e);
    }
}