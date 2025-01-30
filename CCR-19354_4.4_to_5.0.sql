-------------------------------------
Plan to Upgrade Mongo from 4.4 to 5.0
-------------------------------------

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
 
/saba/mongouser/mongo_4.4/bin/mongo --port 17000

----------------------
take service down:
----------------------

use admin
db.shutdownServer()

--------------------------------------------
start mongo service with mongo_5.0 binaries
--------------------------------------------

/saba/mongouser/mongo_5.0/bin/mongod --config /saba/mongouser/config/eu2_pod2_mongo_arbtr.cfg
/saba/mongouser/mongo_5.0/bin/mongosh --port 17000

5) Upgrade Temp_secondary server

-----------------------------------------
connect to Temp_secondary: (e1pp99spcmon03)
-----------------------------------------
/saba/mongouser/mongo_5.0/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


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
start mongo service with mongo_5.0 binaries
--------------------------------------------

/saba/mongouser/mongo_5.0/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/EU2_POD2_TEMP_SEC.cfg

/saba/mongouser/mongo_5.0/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin

------------------------------------
perform sync check:
------------------------------------



db.printSecondaryReplicationInfo()



6) Upgrade Secondary server

-----------------------------------------
connect to secondary: (e1pp01spcmon05)
-----------------------------------------
/saba/mongouser/mongo_4.4/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl2.cfg

/saba/mongouser/mongo_4.4/bin/mongo --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


------------------------------------
perform sync check:
------------------------------------

db.printSlaveReplicationInfo()

----------------------
take service down:
----------------------
use admin
db.shutdownServer()


--------------------------------------------
start mongo service with mongo_5.0 binaries
--------------------------------------------

 /saba/mongouser/mongo_5.0/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl2.cfg
 
/saba/mongouser/mongo_5.0/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin

------------------------------------
perform sync check:
------------------------------------



db.printSecondaryReplicationInfo()


7) Now move  primary services to secondary and perform app sanity

------------------------------------
connect to primary:(e1pp02spcmon03)
------------------------------------

/saba/mongouser/mongo_4.4/bin/mongo --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


------------------------------------
perform sync check:
------------------------------------

db.printSlaveReplicationInfo()

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
start mongo service with mongo_5.0 binaries
--------------------------------------------

/saba/mongouser/mongo_5.0/bin/mongod --setParameter honorSystemUmask=true --config /saba/mongouser/config/eu2_pod2_mongo_repl1.cfg
/saba/mongouser/mongo_5.0/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin


***************************************************************************************************
as now all services upgraded to 5.0 we need to switch back primary service to original Secondary
***************************************************************************************************



---------------------------------------
connect to primary: (e1pp02spcmon03)
---------------------------------------

/saba/mongouser/mongo_5.0/bin/mongosh --port 17000 -u sabaadmin -p eu2p4you --authenticationDatabase admin

------------------------------------
perform sync check:
------------------------------------

db.printSecondaryReplicationInfo()


db.adminCommand({setFeatureCompatibilityVersion:"5.0"})

db.adminCommand( { getParameter: 1, featureCompatibilityVersion: 1 } )


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

