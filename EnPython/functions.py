import json
import requests
import time
import datetime
requests.packages.urllib3.disable_warnings()

def scriptfail():
    chat_id = "-839401002"
    token = "5099932733:AAErXYmrql8e-F8RdHRf2NKU3dQ_rCs2Nyw"

    requests.get("https://api.telegram.org/bot5099932733:AAErXYmrql8e-F8RdHRf2NKU3dQ_rCs2Nyw/sendMessage\?chat_id=-839401002&text=Exception-Script-FailOver")

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

    try:
        response = requests.get(get_base_url()+'/interface/'+interface, auth=(config['router_user'], config['router_password']), verify=False)
        status = response.json()['running']

        if status == "true":
            return True
        else:
            return False
    except:
        with open('error.txt', 'a', encoding='utf-8') as log:
            now = datetime.datetime.now()
            log.write(str(now) + " check_if " + repr(e) + '\n')
        return "Except"

def check_traffic(interface, minthroughput):
    config = get_config()

    response = requests.get(get_base_url()+'/interface/'+interface, auth=(config['router_user'], config['router_password']), verify=False)
    rxi = response.json()['rx-byte']
    time.sleep(1)
    response = requests.get(get_base_url()+'/interface/'+interface, auth=(config['router_user'], config['router_password']), verify=False)
    rxf = response.json()['rx-byte']

    dif = int(rxf)-int(rxi)

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
    time.sleep(2)
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

def send_notificaiont(peer, estado):
    config = get_config()
    chat_id = config['telegram_chat_id']
    token = config['telegram_token']

    message = "El peer "+peer+" se encuentra en estado: "+estado

    try:
        response = requests.post("https://api.telegram.org/bot"+token+"/sendMessage", json = {'chat_id': chat_id, 'text': message})
    except:
        with open('error.txt', 'a', encoding='utf-8') as log:
            now = datetime.datetime.now()
            log.write(str(now) + " send_notification " + repr(e) + '\n')
        return "Except"

def disable_routes(peer):
    config = get_config()

    get_routes = requests.get(
        get_base_url()+"/ip/route?comment="+peer['name'], 
        auth=(config['router_user'], config['router_password']), 
        verify=False)
    get_routes = get_routes.json()

    for route in get_routes:
        response = requests.patch(get_base_url()+"/ip/route/"+route['.id'], json = {"disabled": "true"}, auth=(config['router_user'], config['router_password']), verify=False)

def enable_routes(peer):
    config = get_config()

    get_routes = requests.get(
        get_base_url()+"/ip/route?comment="+peer['name'], 
        auth=(config['router_user'], config['router_password']), 
        verify=False)
    get_routes = get_routes.json()

    for route in get_routes:
        response = requests.patch(get_base_url()+"/ip/route/"+route['.id'], json = {"disabled": "false"}, auth=(config['router_user'], config['router_password']), verify=False)

def fail_action(peer):
    print(peer['name'] + "CON FALLAS")
    send_notificaiont(peer['name'], "CON FALLAS")
    disable_routes(peer)

def recover_action(peer):
    print(peer['name']+ "ACTIVO")
    send_notificaiont(peer['name'], "ACTIVO")
    enable_routes(peer)

def validate_status(peer):
    if peer['counts'] >= 2:
        fail_action(peer)
    
    if peer['counts'] == 0:
        recover_action(peer)