/**
 * @author      nsuhara <na010210dv@gmail.com>
 * @version     1.0
 * @since       2019/01/01
 * @description
 * Support for Salesforce Classic.
 */
trigger AVR_Attachment_Trigger on Attachment (before insert, before update, before delete) {
    /*
     * Get Validation Rule
     */
    private Map<String, AVR_Attachment_Validation_Rules__c> mapRules = AVR_Attachment_Helper.getValidationRules();
    if (mapRules.isEmpty()) return;

    /*
     * Filter Object
     */
    private Map<String, Map<Id, List<Attachment>>> mapObjs = AVR_Attachment_Helper.filterAttachments(mapRules, (Trigger.isDelete ? Trigger.old : Trigger.new), 'ParentId');
    if (mapObjs.isEmpty()) return;

    /*
     * Trigger Event
     */
    AVR_Attachment_Helper.triggerEvent(mapRules, mapObjs);
}
