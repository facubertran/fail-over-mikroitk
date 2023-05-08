import json
import requests
import time
import datetime
requests.packages.urllib3.disable_warnings()

def script_fail(functionName, e):
    chat_id = "-516271910"
    token = "1956001821:AAGGRFve_Guv-qLA6-ke4PDHYWzHh-SCx9o"
    now = datetime.datetime.now()

    try:
        message = "Exception-Script-FailOver - "+functionName
        #response = requests.post("https://api.telegram.org/bot"+token+"/sendMessage", json = {'chat_id': chat_id, 'text': message})
        #with open('error.txt', 'a', encoding='utf-8') as log:
        #    log.write(str(now) + " script_fail " + repr(e) + '\n')
    except:
        with open('error.txt', 'a', encoding='utf-8') as log:
            log.write(str(now) + " script_fail " + repr(e) + '\n')

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
    except Exception as e:
        script_fail("check_if", e)
        return "Except"

def check_traffic(interface, minthroughput):
    config = get_config()

    try:
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
    except Exception as e:
        script_fail("check_traffic", e)
        return "Except"

def check_gw(peer):
    config = get_config()

    try:
        get_gw_id = requests.get(
            get_base_url()+"/ip/route?comment="+peer['name'], 
            auth=(config['router_user'], config['router_password']), 
            verify=False)
        get_gw_id = get_gw_id.json()
        
        if get_gw_id[0]['inactive'] == "true" and get_gw_id[0]['disabled'] == "false":
            return False
        else:
            return True
    except Exception as e:
        script_fail("check_gw", e)
        return "Except"

def set_gw(gateway):
    config = get_config()

    try:
        get_gw_id = requests.get(
            get_base_url()+"/ip/route?comment=FailOverControl", 
            auth=(config['router_user'], config['router_password']), 
            verify=False)
        get_gw_id = get_gw_id.json()

        if get_gw_id[0]['gateway'] != gateway:
            response = requests.patch(get_base_url()+"/ip/route/"+get_gw_id[0]['.id'], json = {"gateway": gateway}, auth=(config['router_user'], config['router_password']), verify=False)
        return True

    except Exception as e:
        script_fail("set_gw", e)
        return "Except"

def check_ping():
    config = get_config()
    
    try:
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
    except Exception as e:
        script_fail("check_ping", e)
        return "Except"

def send_notificaiont(peer, estado):
    config = get_config()
    chat_id = config['telegram_chat_id']
    token = config['telegram_token']

    message = "El peer "+peer+" esta: "+estado

    try:
        response = requests.post("https://api.telegram.org/bot"+token+"/sendMessage", json = {'chat_id': chat_id, 'text': message})
    except Exception as e:
        script_fail("send_notificaiont", e)
        return "Except"

def disable_routes(peer):
    config = get_config()

    try:
        get_routes = requests.get(
            get_base_url()+"/ip/route?comment="+peer['name'], 
            auth=(config['router_user'], config['router_password']), 
            verify=False)
        get_routes = get_routes.json()

        for route in get_routes:
            response = requests.patch(get_base_url()+"/ip/route/"+route['.id'], json = {"disabled": "true"}, auth=(config['router_user'], config['router_password']), verify=False)
    except Exception as e:
        script_fail("disable_routes", e)
        return "Except"

def enable_routes(peer):
    config = get_config()

    try:
        get_routes = requests.get(
            get_base_url()+"/ip/route?comment="+peer['name'], 
            auth=(config['router_user'], config['router_password']), 
            verify=False)
        get_routes = get_routes.json()

        for route in get_routes:
            response = requests.patch(get_base_url()+"/ip/route/"+route['.id'], json = {"disabled": "false"}, auth=(config['router_user'], config['router_password']), verify=False)
    except Exception as e:
        script_fail("enable_routes", e)
        return "Except"

def fail_action(peer):
    print(peer['name'] + " CON FALLAS")
    disable_routes(peer)
    time.sleep(1)
    send_notificaiont(peer['name'], " CON FALLAS")

def recover_action(peer):
    print(peer['name']+ " NUEVAMENTE ACTIVO")
    enable_routes(peer)
    time.sleep(1)
    send_notificaiont(peer['name'], " NUEVAMENTE ACTIVO")

def validate_status(peer):
    if peer['counts'] >= 2:
        fail_action(peer)
    
    if peer['counts'] == 0:
        recover_action(peer)