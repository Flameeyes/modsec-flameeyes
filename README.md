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
ModSecurity 2.5.13, as of March 2011.

Some of the rules make use of global collections and other
configuration directives that are provided by the ModSecurity Core
Rule Set. The file `optional/flameeyes_init.conf` contains the
required directives, in case you explicitly don't want to use CRS.

If you do have CRS installed, there are also a few rules that re-use
its tests.

**Note:** as of ModSecurity CRS 2.1.1, the IP global collection is
hashed on remote address _and_ User-Agent value, to discriminate
between different sessions from the same computer or NAT-routed
network. This might not be desirable for the antispam measures, and
might require creating a different collection for this rule set in the
future.

A few rules require you to enable forward-confirmed hostname
lookups, to do so you need to set `HostnameLookups double` in your
configuration files.

For both the rules requiring FcRNDS and those using DNSBL, it is
recommended that your server has access to some namecache, either in
form of caching resolver or a nscd (Name Service Cache Daemon)
instance, to avoid repeating the same requests for long times.

Asked Questions
---------------
 * My website/browser is not a spammer, where do I complain?

   The ruleset is, for the most part, hand-compiled, so mistakes may
   happen. Most of the data is gathered through my websites, which
   receive about 30MB of traffic per day, and which I analyse over
   time. In case I made a mistake, please let me know by sending an
   email to flameeyes@gmail.com

 * Are you trying to stop all the crawlers? Don't you want to be found
   on search engines?

   I'm not; this ruleset is designed to stop the “bad” crawlers. There
   are a number of companies and individuals out there that are using
   crawlers for shady (or simply useless) business. We range from
   email address harvester (which will be used by spammers) to
   companies doing “marketing research” searching for mentions of
   their clients' products, brands or logos.

 * So are you trying to inconvenience marketeers?

   Again, no. I'm asking them to play by the rules. I have no problem
   with search companies doing marketing work on the side; or using
   the indexes of other search engines like Google, Yahoo or
   Bing. Fetching pages just for the sake of marketing is, though, a
   waste of our network bandwidth.

 * Some legit crawler is getting a 406 “Not Acceptable” reply; what's that?

   Even if your crawler is totally legit and doing a good job, you
   should abide to rules; one of these is “request (and accept)
   compressed responses”. If a crawler is not sending
   `Accept-Encoding: gzip,deflate`, then it is not requesting
   compressed responses, which can use even over three times the
   bandwidth. While a single client requesting non-compressed data is
   not much of an issue, a crawler requesting multiple pages without
   it, is wasted effort.

 * Can you add a rule to validate a specific crawler?

   It depends; most search engines use a pre-defined network range to
   run their crawlers; Google does it, Yahoo does it; Microsoft does
   it. To verify the veracity of their crawlers, you just have to
   apply a FcRDNS check, to ensure that the bot is in the correct
   domain range. Unfortunately, well-intentioned crawlers, especially
   coming from start-ups, not always have a way to set their reverse
   DNS, for instance when using Amazon EC2 services. We don't
   currently have a standardised way to otherwise ensure the
   provenience of crawlers.

 * I'm anonymising myself by replacing my browser's User-Agent with a
   funny string, why are you banning me?

   People seem to think they are pretty smart by trying to hide behind
   User-Agent strings reporting Windows 3.1, DOS, or a Commodore 64 as
   the system used, but not only these can be easily used by spammers
   to go around most veracity checks on User-Agent strings, they also
   they work _against_ anonymity. [EFF's
   Panopticlick](https://panopticlick.eff.org/) will show how your
   unique User-Agent is going to make you much more easily trackable,
   as it provides a very high entropy for browser fingerprinting. So
   stop trying to be smart, and be smart.

 * Why does Munin stop monitoring Apache after setting up the Ruleset?

   Up to March 2011, Munin doesn't present itself with a specific
   User-Agent string, using instead the default libwww-perl
   header. This behaviour, though, conforms to that of a number of
   unknown scanners, and is thus blocked by the ruleset.

   You can work around this limitation by adding a specific rule
   allowing access from localhost only:

    SecRule REMOTE_ADDR "@eq 127.0.0.1" "ctl:ruleEngine=Off"


Debugging rules
---------------

While the ruleset strive to avoid false positives whenever possible,
it can happen that legit requests are denied reply when using these
rules. It can thus be quite important to debug the encountered issues.

The quickest way is to define a debug entrypoint, which can be
something like http://yourhost/modsec-debug and then set it up so that
the requests coming to that address are logged in full into the audit
log.

Enabling the audit log on all denied requests is definitely a bad
idea, since it could easily fill up the logs directory; to solve the
issue, you should add `noauditlog` to the SecDefaultAction list and
then configure it as follows:

    SecAuditEngine RelevantOnly
    SecAuditLog /var/log/apache2/modsec_audit.log
    SecAuditLogType serial
    SecAuditLogParts ABCFHZ

    <Location /modsec-debug>
        SecAction "auditlog"
    </Location>

License
-------

The rules are released under CreativeCommons Attribution-ShareAlike
license (CC-BY-SA). If you're interested in making use of these rules
on commercial products where CC-BY-SA is not acceptable, you can
contact me at flameeyes@gmail.com
