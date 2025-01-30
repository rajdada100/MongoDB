https://jira.saba.com/browse/CCR-19354
CCR for EU2_POD2 Prod SC Cluster -MongoDB upgrade to 7.x

Task#	Comment
1	Make sure the arbiter vm is compatible with 5.0, 6.0, 7.0.5
2	All the required binaries are installed on Temp Secondary Server
3	All the required binaries are installed on Arbiter Server
4	All the required binaries are installed on Actual Secondary Server
5	All the required binaries are installed on Actual Primary Server
6	The Non-Prod and PROD cluster are not sharing the same server
7	All the cronjobs on Arbiter, Temp_secondary, Secondary and Primary are disabled before startng the upgrade
8	CheckMK monitoring is completely disabled for all the server/cluster services
9	All the replica members are in sync.
10	Upgrade MongoDB from 4.2 to 4.4 version.
11	Upgrade MongoDB from 4.4 to 5.0 version.
12	Upgrade MongoDB from 5.0 to 6.0 version.
13	Upgrade MongoDB from 6.0 to 7.0.5 version.
14	In case of any issue while upgrading the replica member, Stop the upgrade. Do not move on upgrading other replica members.
15	While moving services on the secondary perform app sanity before upgrading the actual primary
16	After upgrading the replica member on a server, Make sure Sabatools and mongoops has the execute permission on mongosh/required binaries.
17	While moving services on the actual primary perform app sanity
18	Enable all cron jobs on server
19	Enable checkMK monitoring.
20	Validate the internal cronjob monitoring is working fine and attac the evidance to the cases.
***************************************
Take Backup before starting activity
***************************************
e1pp02spcmon03	PRIMARY:17000
e1pp99spcmon03 Temp_secondary:17000
e1pp01spcmon05	SECONDARY:17000
e1pv03spcmon01	ARBITER:17000


e1pv03spcmon01	ARBITER:17000

[mongouser@n1nv01spcmon01 ~]$ ps -ef|grep mongod

/saba/mongouser/mongo_4.2/bin/mongod --config /saba/mongouser/config/eu2_pod2_mongo_arbtr.cfg
/saba/mongouser/mongo_4.2/bin/mongo --port 17000



e1pp01spcmon05	SECONDARY:17000

[mongouser@e1pp01spcmon05 ~]$ ps -ef|grep mongod

 /saba/mongouser/mongo_4.2/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl2.cfg
/saba/mongouser/mongo_4.2/bin/mongo --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin

e1pp99spcmon03 Temp_secondary:17000
 /saba/mongouser/mongo_4.2/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/EU2_POD2_TEMP_SEC.cfg
/saba/mongouser/mongo_4.2/bin/mongo --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


e1pp02spcmon03	PRIMARY:17000

/saba/mongouser/mongo_4.2/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl1.cfg
/saba/mongouser/mongo_4.2/bin/mongo --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin



crontab -e
press colon ":" then paste the below
%s/^/#RD-->/g
and remove your comment, use below.
%s/^#RD-->//g 

