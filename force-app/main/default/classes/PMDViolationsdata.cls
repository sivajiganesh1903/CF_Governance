global with sharing class PMDViolationsdata implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    // Global continuous serial number across all batches
    private Integer snoGlobal = 0;

    // Small stateful structures only (not CSV content)
    private Map<String, Map<String, Integer>> violationCountsByOrg = new Map<String, Map<String, Integer>>();
    private Set<String> orgSeen = new Set<String>();
    private Map<String, List<Id>> orgToContentVersions = new Map<String, List<Id>>();
    private List<Id> allContentVersionIds = new List<Id>();

    private List<copado__Org__c> orgCreds;

    // Constructor: preload org credentials
    public PMDViolationsdata() {
        orgCreds = [
            SELECT Id, Name, Weekly_PMD_Report__c,
                (SELECT Id, Name, CreatedDate
                 FROM copado__Static_Code_Analysis_Results__r
                 ORDER BY CreatedDate DESC LIMIT 1)
            FROM copado__Org__c
            WHERE Weekly_PMD_Report__c = true
            WITH SECURITY_ENFORCED
        ];

        for (copado__Org__c oc : orgCreds) {
            if (!violationCountsByOrg.containsKey(oc.Name)) {
                violationCountsByOrg.put(oc.Name, new Map<String, Integer>{
                    'P1' => 0, 'P2' => 0, 'P3' => 0, 'P4' => 0, 'P5' => 0
                });
            }
        }
    }

    // Start: query all PMD violations for latest SCA result per org
    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<Id> resultIds = new List<Id>();
        for (copado__Org__c cred : orgCreds) {
            if (cred.copado__Static_Code_Analysis_Results__r != null &&
                !cred.copado__Static_Code_Analysis_Results__r.isEmpty()) {
                resultIds.add(cred.copado__Static_Code_Analysis_Results__r[0].Id);
            }
        }

        return Database.getQueryLocator([
            SELECT Id, copado__File__c, copado__Line__c, copado__Rule__c,
                   copado__Priority__c, copado__Message__c,
                   copado__Static_Code_Analysis_Result__r.copado__Org_Credential__r.Name
            FROM copado__Static_Code_Analysis_Violation__c
            WHERE copado__Static_Code_Analysis_Result__c IN :resultIds
            ORDER BY copado__Priority__c ASC
        ]);
    }

    // Execute: process each scope, generate CSV chunk per org, store in ContentVersion
    global void execute(Database.BatchableContext bc, List<copado__Static_Code_Analysis_Violation__c> scope) {
        Map<String, List<copado__Static_Code_Analysis_Violation__c>> violationsByOrg = new Map<String, List<copado__Static_Code_Analysis_Violation__c>>();
        for (copado__Static_Code_Analysis_Violation__c v : scope) {
            String orgName = v.copado__Static_Code_Analysis_Result__r.copado__Org_Credential__r.Name;
            if (!violationsByOrg.containsKey(orgName)) {
                violationsByOrg.put(orgName, new List<copado__Static_Code_Analysis_Violation__c>());
            }
            violationsByOrg.get(orgName).add(v);
        }

        List<ContentVersion> cvsToInsert = new List<ContentVersion>();

        for (String orgName : violationsByOrg.keySet()) {
            List<copado__Static_Code_Analysis_Violation__c> violations = violationsByOrg.get(orgName);

            Integer p1 = 0, p2 = 0, p3 = 0, p4 = 0, p5 = 0;
            List<String> lines = new List<String>();
            Boolean includeHeader = !orgSeen.contains(orgName);
            if (includeHeader) {
                lines.add('SNo,File,Line,Rule,Priority,Message');
            }

            for (copado__Static_Code_Analysis_Violation__c v : violations) {
                snoGlobal++;
                String msg = v.copado__Message__c == null ? '' : v.copado__Message__c.escapeCsv();
                String fileVal = v.copado__File__c == null ? '' : v.copado__File__c;
                String lineVal = v.copado__Line__c == null ? '' : String.valueOf(v.copado__Line__c);
                String ruleVal = v.copado__Rule__c == null ? '' : v.copado__Rule__c;
                String prioVal = v.copado__Priority__c == null ? '' : String.valueOf(v.copado__Priority__c);

                lines.add(String.valueOf(snoGlobal) + ',' + fileVal + ',' + lineVal + ',' +
                          ruleVal + ',' + prioVal + ',' + msg);

                switch on prioVal {
                    when '1' { p1++; }
                    when '2' { p2++; }
                    when '3' { p3++; }
                    when '4' { p4++; }
                    when '5' { p5++; }
                }
            }

            Map<String, Integer> agg = violationCountsByOrg.get(orgName);
            agg.put('P1', agg.get('P1') + p1);
            agg.put('P2', agg.get('P2') + p2);
            agg.put('P3', agg.get('P3') + p3);
            agg.put('P4', agg.get('P4') + p4);
            agg.put('P5', agg.get('P5') + p5);

            orgSeen.add(orgName);

            String csvContent = String.join(lines, '\n') + '\n';
            Blob csvBlob = Blob.valueOf(csvContent);

            ContentVersion cv = new ContentVersion();
            cv.Title = orgName + '_PMD_Report_part';
            cv.PathOnClient = orgName + '_PMD_Report_part_' + Datetime.now().getTime() + '.csv';
            cv.VersionData = csvBlob;
            cv.IsMajorVersion = true;
            cvsToInsert.add(cv);
        }

        if (!cvsToInsert.isEmpty()) {
            try {
                insert cvsToInsert;
                List<String> paths = new List<String>();
                for (ContentVersion c : cvsToInsert) {
                    paths.add(c.PathOnClient);
                }

                List<ContentVersion> insertedCVs = [
                    SELECT Id, Title, PathOnClient
                    FROM ContentVersion
                    WHERE PathOnClient IN :paths
                    ORDER BY CreatedDate DESC
                ];

                for (ContentVersion inserted : insertedCVs) {
                    String path = inserted.PathOnClient;
                    String orgNameFromPath;
                    if (String.isNotBlank(path)) {
                        Integer idx = path.indexOf('_PMD_Report_part_');
                        if (idx > 0) orgNameFromPath = path.substring(0, idx);
                        else orgNameFromPath = inserted.Title;
                    } else orgNameFromPath = inserted.Title;

                    if (!orgToContentVersions.containsKey(orgNameFromPath)) {
                        orgToContentVersions.put(orgNameFromPath, new List<Id>());
                    }
                    orgToContentVersions.get(orgNameFromPath).add(inserted.Id);
                    allContentVersionIds.add(inserted.Id);
                }
            } catch (Exception ex) {
                System.debug('Failed to insert ContentVersion chunk(s): ' + ex.getMessage());
            }
        }
    }

    // Finish: summarize counts, build email, attach or link files
    global void finish(Database.BatchableContext bc) {
        System.debug('Finish - building final email. Total ContentVersions: ' + allContentVersionIds.size());

        String html = '';
        html += 'Hi Team,<br/><br/>Here\'s the PMD Report generated for the following Environments:<br/><br/>';
        html += '<table border="1" style="border-collapse: collapse; text-align: center;">';
        html += '<tr>';
        html += '<th style="background-color: #f2f2f2; padding: 8px;">Environment Name</th>';
        html += '<th style="background-color: #f2f2f2; padding: 8px;">P1</th>';
        html += '<th style="background-color: #f2f2f2; padding: 8px;">P2</th>';
        html += '<th style="background-color: #f2f2f2; padding: 8px;">P3</th>';
        html += '<th style="background-color: #f2f2f2; padding: 8px;">P4</th>';
        html += '<th style="background-color: #f2f2f2; padding: 8px;">P5</th>';
        html += '</tr>';

        for (String orgName : violationCountsByOrg.keySet()) {
            Map<String, Integer> c = violationCountsByOrg.get(orgName);
            html += '<tr>';
            html += '<td style="padding:8px;">' + orgName + '</td>';
            html += '<td style="padding:8px;">' + c.get('P1') + '</td>';
            html += '<td style="padding:8px;">' + c.get('P2') + '</td>';
            html += '<td style="padding:8px;">' + c.get('P3') + '</td>';
            html += '<td style="padding:8px;">' + c.get('P4') + '</td>';
            html += '<td style="padding:8px;">' + c.get('P5') + '</td>';
            html += '</tr>';
        }
        html += '</table><br/>';

        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        List<String> fileLinks = new List<String>();
        Decimal totalAttachmentBytes = 0;

        if (!allContentVersionIds.isEmpty()) {
            List<ContentVersion> cvs = [
                SELECT Id, Title, PathOnClient, VersionData
                FROM ContentVersion
                WHERE Id IN :allContentVersionIds
                ORDER BY CreatedDate
            ];

            for (ContentVersion cv : cvs) {
                Integer sizeBytes = cv.VersionData == null ? 0 : cv.VersionData.size();
                totalAttachmentBytes += sizeBytes;

                String downloadUrl = System.URL.getOrgDomainUrl().toExternalForm() +
                                     '/sfc/servlet.shepherd/version/download/' + cv.Id;
                fileLinks.add('<a href="' + downloadUrl + '">' + cv.PathOnClient + '</a>');

                if (totalAttachmentBytes <= 25165824) {
                    try {
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setFileName(cv.PathOnClient);
                        efa.setBody(cv.VersionData);
                        attachments.add(efa);
                    } catch (Exception exA) {
                        System.debug('Failed to build EmailFileAttachment: ' + exA.getMessage());
                    }
                }
            }
        }

        Boolean usingLinks = (attachments.isEmpty() && !fileLinks.isEmpty()) ||
                             (totalAttachmentBytes > 25165824 && !fileLinks.isEmpty());

        if (usingLinks) {
            html += 'The CSV reports are too large to attach. Download them here:<br/>';
            for (String linkHtml : fileLinks) {
                html += linkHtml + '<br/>';
            }
        } else {
            html += 'CSV reports are attached.<br/>';
        }

        html += '<br/>Thanks & Regards,<br/>DevOps Team';

        List<PMD_Report__mdt> pmdMeta = [SELECT Public_Group__c, Email_Address__c, Org_Address__c
                                          FROM PMD_Report__mdt
                                          WHERE DeveloperName = 'PMD_Report_Rec' LIMIT 1];
        if (pmdMeta.isEmpty()) return;
        PMD_Report__mdt meta = pmdMeta[0];

        Set<String> toAddresses = new Set<String>();
        if (String.isNotBlank(meta.Email_Address__c))
            toAddresses.addAll(meta.Email_Address__c.split(','));

        if (String.isNotBlank(meta.Public_Group__c)) {
            List<String> groupNames = meta.Public_Group__c.split(',');
            List<Group> groups = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers)
                                  FROM Group WHERE Name IN :groupNames];
            Set<Id> userIds = new Set<Id>();
            for (Group g : groups)
                for (GroupMember gm : g.GroupMembers)
                    userIds.add(gm.UserOrGroupId);
            for (User u : [SELECT Email FROM User WHERE Id IN :userIds AND Email != null])
                toAddresses.add(u.Email);
        }

        OrgWideEmailAddress orgWide = null;
        if (String.isNotBlank(meta.Org_Address__c)) {
            List<OrgWideEmailAddress> ow = [SELECT Id, DisplayName
                                            FROM OrgWideEmailAddress
                                            WHERE DisplayName = :meta.Org_Address__c LIMIT 1];
            if (!ow.isEmpty()) orgWide = ow[0];
        }

        if (toAddresses.isEmpty()) return;

        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(toAddresses));
            mail.setSubject('PMD Scan Report - ' + Date.today().format());
            mail.setHtmlBody(html);
            if (orgWide != null) mail.setOrgWideEmailAddressId(orgWide.Id);
            if (!usingLinks && !attachments.isEmpty()) mail.setFileAttachments(attachments);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception exEmail) {
            System.debug('Failed to send email: ' + exEmail.getMessage());
        }

        System.debug('PMDViolationsReport finish completed. Total snoGlobal: ' + snoGlobal);
    }
}