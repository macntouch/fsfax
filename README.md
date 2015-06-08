
# Overview

FreeSWITCH Fax is a group of scripts to send, recieve, and manage faxes on FreeSWITCH.


# Install

First, you need to clone a copy of the fsfax repository.
You may need to adjust the below path to match your environment.

```bash
cd /usr/share/freeswitch/scripts/
git clone https://github.com/bwmarrin/fsfax.git fsfax
```

The configuration file (*cfgfax.lua*) must be created manually.
In future versions I will try to have this created on first run.
There are currently only two settings.  Edit the below values
to match your needs.

Copy the below contents into a file named *cfgfax.lua* and place that in
the same folder ad the rest of the fsfax files.

```lua
-- Configuration variable for the *fax commands.
-- this will probably change once a formal schema is
-- created.

-- FROM: domain of emails sent by server
domain     = "fax.mydomain.tld"

-- Administrative / Logging E-Mail address
admin      = "myadminedmail@mydomain.tld"
```

Now, you can access the fsfax from the FreeSWITCH Console.
From ```fs_cli``` run the below to view help.

```
lua fsfax/faxctl.lua
```

Use the below commaind to set up aliases and autocomplete commands
for fsfax.

```
lua fsfax/ctlfax.lua init all
```


# Usage
TODO: Write this section :)


