# A scalable Architecture with zeromq using nodejs
In this project, we present an scalable architecture design with zeromq using nodejs. 
The architecture contains brokers, workers, clients, and possibly db servers  

## Broker
Each broker has a local router socket that local workers can connect to.
Each broker has a limited numbr of workers that handle work locally. 
If all local workers are busy, requests are routed to other peers through cloud BE.

Each broker has a cloud FE and a cloud BE. Both are router sockets.
Requests come to cloud FE while responses are from cloud BE, if work is done remotely.

In this demo, we can have two brokers, fully connected with one's cloud BE 
connect to the other's cloud FE.
We balance load among brokers by dispatching requests to other brokers if one broker
is overloaded.

Responses available either from broker's local worker, or from remote brokers worker.  
When a local worker emits response to broker, the broker sends out the response through 
its cloud FE using the first entry in the envelop in response body as the address. 

When a broker relays message, its address will be prepended into the message body 
as the first entry in the message array automatically. 
When a broker receives the msg, the nexthop of the message is the first entry in the body array.

To start two brokers, give the name of the broker and a list of its peer brokers.

```bash
    coffee rtbroker.coffee b1 b2

    coffee rtbroker.coffee b2 b1
```

once started, each broker's cloud BE will connect to the peer's FE. 
The complete links among peers are established.

## Client
Each client is connected to one broker's cloud FE. 

```bash
    coffee wsclient b1
```

## Worker
Each worker belongs to one broker. Once worker started, it will connect to its broker's local BE.

```bash
    coffee wkserver.coffee b2
```

## Architecture that scales
On the client side, we divide clients into subsets. Each client send requests to one broker for service.
On the worker side, each worker attaches to one broker, and handle works locally.
On the broker side, each broker is responsbile for a certaion domain of problem. 

For example, we divide location data into different mongodb servers, with each server dedicated to
store and index location data and handle location related search for one certain area as well.
In our current setup, we have five of those servers, serving NE, South, MW, SW, and CA location
data services.

Each broker is configured to manage one server and handle all the requests for locations in that db.
Upon a request comes one broker can answer location requesti 
With this architecutre, we divided clients into subsets, w
