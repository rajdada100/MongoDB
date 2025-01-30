-----------------------------------------
Plan to Upgrade Mongo from 6.0 to 7.0.5
-----------------------------------------


e1pp02spcmon03	PRIMARY:17000
e1pp99spcmon03 Temp_secondary:17000
e1pp01spcmon05	SECONDARY:17000
e1pv03spcmon01	ARBITER:17000


1)
All the required binaries are installed on Arbiter Server  (done)
All the required binaries are installed on Actual Secondary Server (done)
All the required binaries are installed on Actual Primary Server (done)



2)
All the cronjobs on Arbiter, Secondary and Primary are disabled before startng the upgrade 
CheckMK monitoring is completely disabled for all the server/cluster services


3)
All the replica members are in sync.


db.printSlaveReplicationInfo()

4) Upgrade arbiter Server (e1pv03spcmon01)

/saba/mongouser/mongo_6.0/bin/mongosh --port 17000

----------------------
take service down:
----------------------

use admin
db.shutdownServer()

--------------------------------------------
start mongo service with 7.0.5 binaries
--------------------------------------------

/saba/mongouser/mongo_7.0.5/bin/mongod --config /saba/mongouser/config/eu2_pod2_mongo_arbtr.cfg
/saba/mongouser/mongo_7.0.5/bin/mongosh --port 17000

5) Upgrade Temp_secondary server

-----------------------------------------
connect to Temp_secondary: (e1pp99spcmon03)
-----------------------------------------
/saba/mongouser/mongo_6.0/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


------------------------------------
perform sync check:
------------------------------------

db.printSecondaryReplicationInfo()

----------------------
take service down:
----------------------
use admin
db.shutdownServer()


--------------------------------------------
start mongo service with mongo_7.0.5 binaries
--------------------------------------------

/saba/mongouser/mongo_7.0.5/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/EU2_POD2_TEMP_SEC.cfg


[mongouser@e1pp99spcmon03 ~]$ /saba/mongouser/mongo_7.0.5/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin
Current Mongosh Log ID: 66aeeeae492023000bc934dc
Connecting to:          mongodb://<credentials>@127.0.0.1:17000/?directConnection=true&serverSelectionTimeoutMS=2000&authSource=admin&appName=mongosh+2.2.4
Using MongoDB:          7.0.5
Using Mongosh:          2.2.4

For mongosh info see: https://docs.mongodb.com/mongodb-shell/

------
   The server generated these startup warnings when booting
   2024-08-04T02:59:43.759+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
------


Deprecation warnings:
  - Using mongosh on the current operating system is deprecated, and support may be removed in a future release.
See https://www.mongodb.com/docs/mongodb-shell/install/#supported-operating-systems for documentation on supported platforms.
eu2_pod2 [direct: secondary] test>

/saba/mongouser/mongo_7.0.5/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin

------------------------------------
perform sync check:
------------------------------------



db.printSecondaryReplicationInfo()



6) Upgrade Secondary server

-----------------------------------------
connect to secondary: (e1pp01spcmon05)
-----------------------------------------
/saba/mongouser/mongo_6.0/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl2.cfg

/saba/mongouser/mongo_6.0/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


------------------------------------
perform sync check:
------------------------------------

db.printSecondaryReplicationInfo()


----------------------
take service down:
----------------------
use admin
db.shutdownServer()


--------------------------------------------
start mongo service with mongo_7.0.5 binaries
--------------------------------------------

 /saba/mongouser/mongo_7.0.5/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl2.cfg
 
/saba/mongouser/mongo_7.0.5/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin

------------------------------------
perform sync check:
------------------------------------



db.printSecondaryReplicationInfo()


7) Now move  primary services to secondary and perform app sanity

------------------------------------
connect to primary:(e1pp02spcmon03)
------------------------------------

/saba/mongouser/mongo_6.0/bin/mongo --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


------------------------------------
perform sync check:
------------------------------------

db.printSecondaryReplicationInfo()

------------------------------------------------------------------------
--> Check the configuration (Priorities value)
------------------------------------------------------------------------
rs.config()

--------------------------------------------------
perform switchover and confirm app sanity
--------------------------------------------------
rs.stepDown()



--------------------------------------------------
once sanity looks good then take service down:
--------------------------------------------------
use admin
db.shutdownServer()

--------------------------------------------
start mongo service with mongo_7.0.5 binaries
--------------------------------------------

/saba/mongouser/mongo_7.0.5/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl1.cfg
/saba/mongouser/mongo_7.0.5/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin




***************************************************************************************************
as now all services upgraded to 7.0.5 we need to switch back primary service to original Secondary
***************************************************************************************************



---------------------------------------
connect to primary: (e1pp02spcmon03)
---------------------------------------

/saba/mongouser/mongo_7.0.5/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin

------------------------------------
perform sync check:
------------------------------------

db.printSecondaryReplicationInfo()


db.adminCommand({setFeatureCompatibilityVersion:"7.0",confirm: true})

db.adminCommand( { getParameter: 1, featureCompatibilityVersion: 1 } )

use admin
db.grantRolesToUser("sabaadmin", ["__system"]);

