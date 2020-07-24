\l common/solace_init.q
\l common/haversine.q

//Solace connection details 
default.host :"localhost:55555";
default.vpn  :"default";
default.user :"default";
default.pass :"default";

params:.Q.def[`$1_default].Q.opt .z.x;
-1"### Initializing session";
initparams:params`SESSION_HOST`SESSION_VPN_NAME`SESSION_USERNAME`SESSION_PASSWORD!`host`vpn`user`pass;
if[0>.solace.init initparams;-2"### Initialization failed";exit 1];

//Deine the fdps table
fdps:([]time:`datetime$();identifier:`symbol$();fdpsFlightStatus:`symbol$();aircraftIdentification:`symbol$();lat:`float$();lon:`float$();surveillance:`float$();altitude:`float$();trackVelocityX:`float$();trackVelocityY:`float$());

//OnMessage callback for the Solace API
onmsg:{[dest;payload;dict]
 //Trim the payload to make it valid JSON
 p: -1_3_"c"$payload;
 //Convert the message from json into a table and structure the table appropriately to store into kdb
 j: select time,`$identifier,`$fdpsFlightStatus,`$aircraftIdentification,lat,lon,surveillance,altitude,trackVelocityX,trackVelocityY from update time:.z.z from .j.k "[",p,"]";
 `fdps insert j;
 };


.solace.setTopicMsgCallback`onmsg;

.solace.subscribeTopic[`$"FDPS/position/>";1b];

/.solace.subscribeTopic[`$"FDPS/position/*/*/AAL*/>";1b];

publishDistance:{[]
 // Generate JSON payload from the fdps table that calculates the distance flown per fdpsFlightStatus
 j:.j.j select id,distance:haversineDistance[raze lat1;raze lon1;raze lat2;raze lon2] from (select lat2:last lat,lat1:first lat,lon2:last lon,lon1:first lon  by id:aircraftIdentification from fdps);
 .solace.sendDirect[`$"SOLACE/KDB/FLIGHTS/DISTANCE";j];
 };

//Pulse out the distance updates every 30 seconds
\t 30000
.z.ts:{publishDistance[]};

