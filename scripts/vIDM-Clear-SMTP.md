# Clearing vIDM SMTP Settings

The two REST calls needed to clear an SMTP configuration in vIDM. You're normally unable to clear vIDM's SMTP settings through the GUI because it attempts to validate the SMTP settings before letting you save the configuration. Updating the SMTP configuration through the REST API bypasses this validation step, allowing you to set the SMTP host to a blank value.

Authenticate to vIDM:

```text
POST https://vidm.sddc.lab/SAAS/API/1.0/REST/auth/system/login
Content-Type: application/json
{
    "username": "configadmin",
    "password": "PASSWORD",
    "issueToken": "true"
}
```


Clear the SMTP configuration:

```text
PUT https://vidm.sddc.lab/SAAS/jersey/manager/api/system/config/smtp
Content-Type: application/vnd.vmware.horizon.manager.system.config.smtp+json;charset=UTF-8
Bearer TOKEN

Body:
{
    "host": "",
    "port": "25",
    "user": null,
    "password": null,
    "securityType": "NONE",
    "fromAddress": "no-reply@sddc.lab"
}
```
