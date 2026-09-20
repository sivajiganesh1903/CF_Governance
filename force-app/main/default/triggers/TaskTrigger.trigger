trigger TaskTrigger on task (after update) {
    TaskTriggerHandler.handletask(trigger.new,Trigger.oldMap);
}