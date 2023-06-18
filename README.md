# ADScriptedDynamicGroups

Powershell Module to create maintain pseudo-dynamic groups in Active Directory

## Why?

Active Directory usually does not provide any support for dynamic security groups, as AzureAD does or Exchange works with dynamic distribution lists. To work around some scheduled automatism, scripted or other, must be applied. This are usually created from scratch for every single case.

## Available Commandlets

### `New-ADScriptedDynamicGroup -Name <string> -Path <string/DistinguishedName> -MembershipRule <string> [-SearchBase <string[]>] [-GroupScope <string>] [-GroupCategory <string>] [-TimeOutinSeconds <byte>]`

Creates a new group in Active Directory at the given `-path`. The group is populated with members matching the given `-SearchBase` and `-MembershipRule` which will both, along with a "ScriptedDynamic" mark, saved as compressed JSON into the Description field of the group.
The JSON information will be reused by the other cmdlets for maintenance.

### `Set-ADScriptedDynamicGroupFilter -InputObject <string> -MembershipRule <string> [-SearchBase <string>] [-DoNotUpdateMemberlist <switch>]`

If the `-MembershipRule` of a ScriptedDynamic group needs updating, this is the cmdlet to go with.

Provide the group's name or objectguid along with the new `-MembershipRule` and (optional) `-SearchBase`. The new rule will be save to the description field.

If not opted out using `-DoNotUpdateMemberList` the group's memberlist will be updated as well. 

### `Update-ADScriptedDynamicGroup [-Name <string>] [-ObjectGuid <guid>]`

This is the cmdlet for regularly updating the memberlists of the groups created with this module, thus mimicing the key functionality of dynamic groups. Call this cmdlet providing it with the `-Name` or `-ObjectGuid` of the group you want to update and it will take care of the rest.

A scheduled job or task calling this cmdlet should be enough to update your ScriptedDynamic-Groups without further coding.