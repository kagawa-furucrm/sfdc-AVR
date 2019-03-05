/**
 * @author      nsuhara <na010210dv@gmail.com>
 * @version     1.0
 * @since       2019/01/01
 * @description
 * Support for Salesforce Classic and Lightning Experience.
 */
public without sharing class AVR_Attachment_Helper {

    @TestVisible
    AVR_Attachment_Helper() {
    }

    @TestVisible
    private class CurrentUserInfo {
        @TestVisible String         strProfileAssignment;
        @TestVisible List<String>   lstGroupAssignment;
        @TestVisible String         strUserName;
        CurrentUserInfo() {
            this.lstGroupAssignment = new List<String>();
        }
    }

    static public Map<String, AVR_Attachment_Validation_Rules__c> getValidationRules() {
        Map<String, AVR_Attachment_Validation_Rules__c> mapRules = new Map<String, AVR_Attachment_Validation_Rules__c>();
        for (List<AVR_Attachment_Validation_Rules__c> lstRules : [SELECT Id, SObject__c, SOQL_WHERE_Clause__c, Excluded_Profile__c, Excluded_Public_Group__c, Excluded_User__c, Error_Message__c FROM AVR_Attachment_Validation_Rules__c WHERE IsActive__c = TRUE]) {
            for (AVR_Attachment_Validation_Rules__c r : lstRules) {
                mapRules.put(r.SObject__c, r);
            }
        }
        return mapRules;
    }

    static public Map<String, Map<Id, List<SObject>>> filterAttachments(Map<String, AVR_Attachment_Validation_Rules__c> mapRules, List<SObject> lstObjs, String parentKey) {
        final Set<String> SOBJECTS = new Set<String>(mapRules.keySet());
        Map<String, Map<Id, List<SObject>>> mapObjs = new Map<String, Map<Id, List<SObject>>>();

        for (SObject o : lstObjs) {
            Id parentId = (Id)o.get(parentKey);
            String SObjectName = parentId.getSObjectType().getDescribe().getName();
            if (SOBJECTS.contains(SObjectName)) {
                if (mapObjs.containsKey(SObjectName)) {
                    if (mapObjs.get(SObjectName).containsKey(parentId)) {
                        mapObjs.get(SObjectName).get(parentId).add(o);
                    } else {
                        mapObjs.get(SObjectName).put(parentId, new List<SObject>{o});
                    }
                } else {
                    mapObjs.put(SObjectName, new Map<Id, List<SObject>>{parentId => new List<SObject>{o}});
                }
            }
        }
        return mapObjs;
    }

    static public Void triggerEvent(Map<String, AVR_Attachment_Validation_Rules__c> mapRules, Map<String, Map<Id, List<SObject>>> mapObjs) {
        CurrentUserInfo objCurrentUserInfo = getCurrentUserInfo();
        for (String SObjectName : mapObjs.keySet()) {
            validate(mapRules.get(SObjectName), objCurrentUserInfo, mapObjs.get(SObjectName));
        }
    }

    @TestVisible
    static private CurrentUserInfo getCurrentUserInfo() {
        List<User> lstUsers = [SELECT Id, Username, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        List<GroupMember> lstMembers = [SELECT Id, Group.DeveloperName FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId()];
        CurrentUserInfo objCurrentUserInfo = new CurrentUserInfo();

        objCurrentUserInfo.strProfileAssignment = lstUsers[0].Profile.Name;
        for (GroupMember m : lstMembers) {
            objCurrentUserInfo.lstGroupAssignment.add(m.Group.DeveloperName);
        }
        objCurrentUserInfo.strUserName = lstUsers[0].Username;
        return objCurrentUserInfo;
    }

    @TestVisible
    static private Void validate(AVR_Attachment_Validation_Rules__c objRule, CurrentUserInfo objCurrentUserInfo, Map<Id, List<SObject>> mapObjs) {
        if (!validateUser(objRule, objCurrentUserInfo)) {
            validateAttachment(objRule, mapObjs);
        }
    }

    @TestVisible
    static private Boolean validateUser(AVR_Attachment_Validation_Rules__c objRule, CurrentUserInfo objCurrentUserInfo) {
        Set<String> setExcludedProfiles = new Set<String>(objRule.Excluded_Profile__c.split(';'));
        Set<String> setExcludedGroups = new Set<String>(objRule.Excluded_Public_Group__c.split(';'));
        Set<String> setExcludedUsers = new Set<String>(objRule.Excluded_User__c.split(';'));

        if (setExcludedProfiles.contains(objCurrentUserInfo.strProfileAssignment)) {
            return true;
        }
        for (String g : objCurrentUserInfo.lstGroupAssignment) {
            if (setExcludedGroups.contains(g)) {
                return true;
            }
        }
        if (setExcludedUsers.contains(objCurrentUserInfo.strUserName)) {
            return true;
        }
        return false;
    }

    @TestVisible
    static private Void validateAttachment(AVR_Attachment_Validation_Rules__c objRule, Map<Id, List<SObject>> mapObjs) {
        Set<Id> setRecIds = mapObjs.keySet();
        String strSoql = 'SELECT Id FROM ' + objRule.SObject__c + ' WHERE Id IN :setRecIds';
        if (!String.isEmpty(objRule.SOQL_WHERE_Clause__c)) {
            strSoql += ' AND ' + objRule.SOQL_WHERE_Clause__c;
        }

        for (List<SObject> lstErrs : Database.query(strSoql)) {
            for (SObject e : lstErrs) {
                for (SObject o : mapObjs.get(e.Id)) {
                    o.addError(objRule.Error_Message__c);
                }
            }
        }
    }

}
