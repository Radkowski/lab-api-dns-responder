import ipaddress
import boto3
import pprint
import json



def read_config():
    with open('./config.json', 'r') as openfile:
        json_object = json.load(openfile)
    return(json_object)



def am_i_in_the_pool (ip_addr, ip_pool):
    return (ipaddress.ip_address(ip_addr) in ipaddress.ip_network(ip_pool))


def return_closest_record(source_ip,config):
        for x in config:
            for y in x['Data']['ip_range']:
                if am_i_in_the_pool(source_ip,y):
                    return {
                        "Source IP": source_ip,
                        "Region": x['Region'],
                        "DNS": x['Data']['dns']
                        }
        return (-1)


def return_idle_record(source_ip,config):
        load = 100
        for x in config:
            if int(x['Data']['load'])<=load:
                winner = x
                load = int(x['Data']['load'])
        return {
                "Source IP": source_ip,
                "Region": winner['Region'],
                 "DNS": winner['Data']['dns']
                }



def lambda_handler(event,context):

    if event['ip_addr'] == 'test-invoke-source-ip':
        ip = '127.0.0.1'
    else:
        ip = event['ip_addr']
    if event['action'] == 'idle':
        return return_idle_record(ip,read_config())
    else:
        return return_closest_record(ip,read_config())
