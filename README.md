
# Overview

FreeSWITCH Fax is a group of scripts to send, recieve, 
and manage a FreeSWITCH based email fax server. 

While inbound faxing does work well, I would still call
this project very experimental.  Outbound faxing has not 
been completed yet and most of the database and console
commands are likely to change as I work torward a stable
version.

If you do use this project please take special note to
any console, database, or configuration changes that
have been made before updating your copy of the repo.

# Install

## Clone FSFAX Repository
First, you need to clone a copy of the fsfax repository into
your FreeSWITCH scripts directory. You may need to adjust 
the below path to match your environment.

```bash
cd /usr/share/freeswitch/scripts/
git clone https://github.com/bwmarrin/fsfax.git fsfax
```

## Initial FSFAX Setup
Now, you can access the fsfax from the FreeSWITCH Console.
From ```fs_cli``` run the below to view basic help.

```
lua fsfax/ctlfax.lua
```

Use the below command to set up aliases and autocomplete for
fsfax. Once the below command is run you can use the command 
```fax``` for all future calls to fsfax. These may reset when
restarting FreeSWITCH itself.

```
lua fsfax/ctlfax.lua init all
```

Next, you **must** set two configration variables.  Adjust the domain
and email address to match your needs.  The fsfax_domain is used as
the from domain for outbound emails.  The fsfax_admin is used as the 
administrative e-mail address. 

**NOTE**: I am positive these variable names
will change in future versions.

```
fax config set * * session fsfax_domain mydomain.tld 0
fax config set * * session fsfax_admin myadmin@mydomain.tld 0
```

## FSFAX E-Mail Routes
You must define inbound routes for FSFAX before it will accept fax calls.
This can be done with the ```fax route set``` command from within the 
FreeSWITCH console. To view the existing routes type ```fax route show```.
See below for a quick reference of each field. 

Field   | Description
------- | -----------
DID     | The DID number to be routed.
EMAIL   | Comma seperated list of e-mails to send fax to.

**NOTE**: If no route is defined for a call then that call will be dropped.

## FreeSWITCH Setup

Finally, for inbound faxes you need to configure FreeSWITCH to
send calls to the rxfax.lua script.  To do this create a file rxfax.xml
in /etc/freeswitch/dialplan/public or elsewhere if you are not using
the default directories.  The below example will send all calls to rxfax.xml
for a dedicated fax install.  You can adjust this to send only calls
for specific DIDs into rxfax.xml if you wish.

```xml
<include>
  <extension name="rxfax">
    <condition field="destination_number" expression=".*">
      <action application="lua" data="fsfax/rxfax.lua"/>
    </condition>
  </extension>
</include>
```


# Usage
TODO: Write this section :)


## FSFAX Configuration
FSFAX can be configured to set variables per fax session based on 
either the DID or CID of the session.  You can use the command 
```fax config set``` to set variables and ```fax config show``` to 
view all configured variables.  See below for a basic reference
of each field.

Field        | Description
------------ | -------------------------------------
match_key    | **CID** (Caller ID Number) or **DID**
match_value  | The actual CID or DID number
type         | only **session** is currently supported
key          | variable name 
value        | the value that the variable is set to
rank         | the rank, higher numbers override smaller numbers


TODO: Create table of valid variables.
