Flameeyes's Ruleset for ModSecurity
===================================

This is a rule set for ModSecurity developed by Diego Elio Pettenò.

The primary aim of this rule set is to reduce bandwidth waste on hosts
that might even be static by disallowing certain known marketing,
broken or abusive bots from hitting the site at all.

Even if you do not pay for bandwidth and your website is not going to
suffer from the requests, keeping spammers and malicious crawlers at
bay is important for the general health of the Network, so please be
mindful.

Additionally, it provides antispam measure for active requests (HEAD
and GET are passive requests, everything else is active as it sends or
modify content). This antispam is based on what I developed for [my own
blog](http://blog.flameeyes.eu/) and employs a number of techniques,
including DNSBL and User-Agent validation.

Prerequisites
-------------

The ruleset won't work without, obviously,
[ModSecurity](https://www.modsecurity.org); it has been tested with
ModSecurity 2.5.12, as of October 2010.

Some of the rules make use of the IP collection; do to so you need the
directive
`SecAction "phase:1,t:none,pass,nolog,initcol:ip=%{remote_addr}"`
which is already executed if the ModSecurity Core Rule Set is
instaslled. If you don't wish to use the CRS you have to add the
directive explicitly.

If you have CRS installed, there are also a few rules that re-use
their tests.

A few rules require you to enable forward-confirmed hostname
lookups, to do so you need to set `HostnameLookups double` in your
configuration files.

For both the rules requiring FcRNDS and those using DNSBL, it is
recommended that your server has access to some namecache, either in
form of caching resolver or a nscd (Name Service Cache Daemon)
instance, to avoid repeating the same requests for long times.

License
-------

The rules are released under CreativeCommons Attribution-ShareAlike
license (CC-BY-SA). If you're interested in making use of these rules
on commercial products where CC-BY-SA is not acceptable, you can
contact me at flameeyes@gmail.com
