from functions import *
import time

def exception_fail():
    return "Falla en la conexión con el router"

def peer_ok(x):
    if x['counts'] > 0:
        x['counts'] = x['counts']-1
        validate_status(x)
    return True
    #return "Peer "+x['name']+" en buen estado"

def peer_fail(x):
    if x['counts'] >= 0 and x['counts'] < 2:
        x['counts'] = x['counts']+1
        validate_status(x)
    return True
    #return "Peer "+x['name']+" presenta fallas"

if __name__ == "__main__":

    config = get_config()
    peers = get_peers()
    exception = False

    while True:
        for x in peers:
            #print(x['name'])
            ##---------------------IFRun-Probe----------------------##
            #print("Chequeando estado de interfaz ...")
            ifstatus = check_if(x['ifname'])
            if ifstatus:
                ##---------------------Gateway-Probe----------------------##
                #print("Chequeando estado de gateway ...")
                gateway = set_check_gw(x['gateway'])
                if gateway:
                    ##---------------------Traffic-Probe----------------------##
                    #print("Chequeando trafico en interfaz ...")
                    traffic = check_traffic(x['ifname'], x['minthroughput'])
                    if not traffic:
                        ##---------------------Ping-Probe----------------------##
                        #print("Haciendo prueba de ping ...")
                        ping = check_ping()
                        if ping:
                            peer_ok(x)
                        else:
                            if ping == False:
                                peer_fail(x)
                            else:
                                #print(exception_fail())
                                time.sleep(config['delay'])
                                continue
                    else:
                        if traffic == True:
                            peer_ok(x)
                        else:
                            #print(exception_fail())
                            time.sleep(config['delay'])
                            continue
                else:
                    if gateway == False:
                        peer_fail(x)
                    else:
                        #print(exception_fail())
                        time.sleep(config['delay'])
                        continue
            else:
                if ifstatus == False:
                    peer_fail(x)
                else:
                    #print(exception_fail())
                    time.sleep(config['delay'])
                    continue

        time.sleep(config['delay'])