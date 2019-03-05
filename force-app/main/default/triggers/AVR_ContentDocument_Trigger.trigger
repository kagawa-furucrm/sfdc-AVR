/**
 * @author      nsuhara <na010210dv@gmail.com>
 * @version     1.0
 * @since       2019/01/01
 * @description
 * Support for Lightning Experience.
 */
trigger AVR_ContentDocument_Trigger on ContentDocument (before update, before delete) {
    /*
     * Get Validation Rule
     */
    private Map<String, AVR_Attachment_Validation_Rules__c> mapRules = AVR_Attachment_Helper.getValidationRules();
    if (mapRules.isEmpty()) return;

    /*
     * Filter Object
     */
    private final Set<String> SOBJECTS = new Set<String>(mapRules.keySet());
    private Map<String, Map<Id, List<ContentDocument>>> mapObjs = new Map<String, Map<Id, List<ContentDocument>>>();

    private Map<Id, ContentDocument> mapDocs = new Map<Id, ContentDocument>(Trigger.isDelete ? Trigger.old : Trigger.new);
    private Set<Id> setDocIds = mapDocs.keySet();

    for (ContentDocumentLink a : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :setDocIds]) {
        String SObjectName = a.LinkedEntityId.getSObjectType().getDescribe().getName();
        if (SOBJECTS.contains(SObjectName)) {
            if (mapObjs.containsKey(SObjectName)) {
                if (mapObjs.get(SObjectName).containsKey(a.LinkedEntityId)) {
                    mapObjs.get(SObjectName).get(a.LinkedEntityId).add(mapDocs.get(a.ContentDocumentId));
                } else {
                    mapObjs.get(SObjectName).put(a.LinkedEntityId, new List<ContentDocument>{mapDocs.get(a.ContentDocumentId)});
                }
            } else {
                mapObjs.put(SObjectName, new Map<Id, List<ContentDocument>>{a.LinkedEntityId => new List<ContentDocument>{mapDocs.get(a.ContentDocumentId)}});
            }
        }
    }
    if (mapObjs.isEmpty()) return;

    /*
     * Trigger Event
     */
    AVR_Attachment_Helper.triggerEvent(mapRules, mapObjs);
}
