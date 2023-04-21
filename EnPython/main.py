from functions import *
import time

if __name__ == "__main__":

    while True:
        config = get_config()
        peers = get_peers()

        for x in peers:
            print(x['name'])
            ##---------------------IFRun-Probe----------------------##
            ifstatus = check_if(x['ifname'])
            print("Estado de interfaz: " + str(ifstatus))
            ##---------------------Gateway-Probe----------------------##
            gateway = set_check_gw(x['gateway'])
            print("Estado de gateway: " + str(gateway))
            ##---------------------Traffic-Probe----------------------##
            print("Haciendo prueba de trafico ...")
            traffic = check_traffic(x['ifname'], x['minthroughput'])
            print("Estado de traffic: " + str(traffic))
            ##---------------------Ping-Probe----------------------##
            if not traffic:
                print("Haciendo prueba de ping ...")
                ping = check_ping()
                print("Estado de ping: " + str(ping))

        time.sleep(config['delay'])