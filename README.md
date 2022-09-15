# freeswitch-bullseye-docker

docker file for bullseye with instructions

You need to create an personal access token at signalwire instructions can be found here https://freeswitch.org/confluence/display/FREESWITCH/HOWTO+Create+a+SignalWire+Personal+Access+Token

once done

$ docker build -f  dockerfile . --build-arg TOKEN=!!!!yoursignalwiretokenhere!!!

After this, grab a beer or coffee as it will be a loooong wait. (I've set up mine on a kvm machine and took ages. -like 20 minutes)
