import json
import requests
import time
requests.packages.urllib3.disable_warnings()

def get_config():
    with open("config.json", "r") as j:
        config = json.load(j)
        return config

def get_peers():
    with open("peers.json", "r") as j:
        peers = json.load(j)
        return peers['peers']

def get_base_url():
    config = get_config()
    base_url = "https://"+config['router_ip']+":"+str(config['router_port'])+"/rest"
    return base_url

def check_if(interface):
    config = get_config()

    response = requests.get(get_base_url()+'/interface/'+interface, auth=(config['router_user'], config['router_password']), verify=False)
    status = response.json()['running']

    if status == "true":
        return True
    else:
        return False

def check_traffic(interface, minthroughput):
    config = get_config()

    response = requests.get(get_base_url()+'/interface/'+interface, auth=(config['router_user'], config['router_password']), verify=False)
    rxi = response.json()['rx-byte']
    time.sleep(1)
    response = requests.get(get_base_url()+'/interface/'+interface, auth=(config['router_user'], config['router_password']), verify=False)
    rxf = response.json()['rx-byte']

    dif = int(rxf)-int(rxi)
    print(dif)

    if dif >= minthroughput:
        return True
    else:
        return False

def set_check_gw(gateway):
    config = get_config()

    get_gw_id = requests.get(
        get_base_url()+"/ip/route?comment=FailOverControl", 
        auth=(config['router_user'], config['router_password']), 
        verify=False)
    get_gw_id = get_gw_id.json()

    response = requests.patch(get_base_url()+"/ip/route/"+get_gw_id[0]['.id'], json = {"gateway": gateway}, auth=(config['router_user'], config['router_password']), verify=False)

    validate_set = requests.get(
        get_base_url()+"/ip/route?comment=FailOverControl", 
        auth=(config['router_user'], config['router_password']), 
        verify=False).json()
    
    if validate_set[0]['inactive'] == "true":
        return False
    else:
        return True

def check_ping():
    config = get_config()
    
    response = requests.post(
        get_base_url()+"/ping",
        json = {"address": config['dst_ping'], "size": 64, "count": 10},
        auth=(config['router_user'], config['router_password']),
        verify=False
        )

    result = response.json()[9]['packet-loss']

    if int(result) <= config['icmp_packets_loss_percent']:
        return True
    else:
        return False
