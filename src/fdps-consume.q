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
fdps_distance:([]time:`datetime$();identifier:`symbol$();aircraftIdentification:`symbol$();distance:`float$());

//OnMessage callback for the Solace API
onmsg:{[dest;payload;dict]
 //Trim the payload to make it valid JSON
 p: -1_3_"c"$payload;
 j: .j.k p;
 s: `$j[`identifier];
 r: select from fdps where identifier=s;
 //if there is a record in the fdps table for an airline, then proceed to either insert or update the fdps_distance table which calculates the miles flown per airplane
 $[(count r)=1;
   [$[(exec count(identifier) from fdps_distance where identifier=s)=1;
   [(update time:.z.z,distance:haversineDistance[exec lat from r;exec lon from r;j[`lat];j[`lon]] from `fdps_distance where identifier=s)];
   [`fdps_distance insert (.z.z;s;`$j[`aircraftIdentification];haversineDistance[exec lat from r;exec lon from r;j[`lat];j[`lon]][0])]]];
   [`fdps insert (.z.z;s;`$j[`fdpsFlightStatus];`$j[`aircraftIdentification];j[`lat];j[`lon];j[`surveillance];j[`altitude];j[`trackVelocityX];j[`trackVelocityY])]];
 };


.solace.setTopicMsgCallback`onmsg;

.solace.subscribeTopic[`$"FDPS/position/>";1b];

publishDistance:{[]
 // Generate JSON payload from the fdps_distance table that calculates the distance flown per airline prefix
 j:.j.j `distance xdesc select sum distance by id:aircraftIdentification from update `$ssr[;"[0-9]";""] each string aircraftIdentification from fdps_distance;
 .solace.sendDirect[`$"SOLACE/KDB/FLIGHTS/DISTANCE";j];
 };

//Pulse out the distance updates every 30 seconds
\t 30000
.z.ts:{publishDistance[]};
