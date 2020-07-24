# scds-solace-kdb

An implementation that consumes data from a normalized SWIM Data Feed over Solace, inserts it into a kdb+ table and uses the [haversine formula](https://www.movable-type.co.uk/scripts/latlong.html) to calculate, in near real-time, the distance travelled per airline. 

## Scripts

 * [src/fdps-consume.q](src/fdps-consume.q) - Script that consumes from a solace messaging bus, inserts into a `fdps table and pulses out distance travelled per airline
 * [common/haversine.q](/common/haversine.q) - Script that contains functions to calculate the distance in km using the haversine formula. Credit goes to [Andy Mans](https://github.com/andymans) for developing [kdb-haversine](https://github.com/andymans/kdb-haversine)
 * [common/solace_init.q](common/solace_init.q) - Solace init function

## Setup instructions

1. Install kdb+ 64 bit edition from [kx.com](https://kx.com/connect-with-us/download/)
2. Install the kdb+ Solace interface using the instructions on the [kxSystems Solace Fusion Interface Repo](https://github.com/KxSystems/solace) or by following this [video](https://www.youtube.com/watch?v=_cGnkrim4K8)
3. Copy the scripts [common/haversine.q](/common/haversine.q) and [common/solace_init.q](common/solace_init.q) into your Q_HOME directory
4. Fill in the connection details for your Solace PubSub+ Broker (Cloud or Docker) into the relevant section in [src/fdps-consume.q]
5. Start the [SWIM FeedHandler](https://github.com/solacese/swim-feed-handler) or the SWIM FeedHandler Simulator to start publishing data 
6. (Optional) Start the solace-swim-feed-handlers-map UI to consume and visualize the data
7. Start the fdps-consume process by running `q fdps-consume.q -p 5011` on port 5011 (or any port of your choosing) and you should see the following output: 
   ```...
       ### Initializing session
       [21728] Solace session event 0: Session up
   ```
   To see if data is being consumed, simply run the follow command in the command promps:
   ```
    q)fdps
   ```
