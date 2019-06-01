import json
import boto3
import logging
import os

ec2_client = boto3.client('ec2')


def handler(event, context):
    """

    :param event: CloudWatch Event
    :param context:
    :return:
    """
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    logger.info("Received an event")
    if event["detail"]:
        return detective_control(event["detail"])
    else:
        return {'statusCode': 405, 'body': '{"error": "Method not allowed."}'}


def revoke_rules(event_name, sg_id, region):
    """

    :param event_name: AuthorizeSecurityGroupIngress or AuthorizeSecurityGroupIngress
    :param sg_id: security_group id
    :param region: region of SG_Id
    :return:
    """

    ec2_resource = boto3.resource('ec2', region_name=region)
    security_group = ec2_resource.SecurityGroup(sg_id)
    if event_name == "AuthorizeSecurityGroupIngress":
        rules = security_group.ip_permissions
        for index, rule in enumerate(rules):
            rules[index]['IpRanges'] = [x for x in rule["IpRanges"] if x['CidrIp'] == '0.0.0.0/0']
            if rule["IpRanges"] and rule["IpRanges"][0]["CidrIp"] == "0.0.0.0/0":
                logging.info(f"Found an inbound rule in {sg_id} as wide open, Proceeding to remove it")
                security_group.revoke_ingress(IpPermissions=[rules[index]])

    elif event_name == "AuthorizeSecurityGroupEgress":
        rules = security_group.ip_permissions_egress
        for index, rule in enumerate(rules):
            rules[index]['IpRanges'] = [x for x in rule["IpRanges"] if x['CidrIp'] == '0.0.0.0/0']
            if rule["IpRanges"] and rule["IpRanges"][0]["CidrIp"] == "0.0.0.0/0":
                logging.info(f"Found an outbound rule in {sg_id} as wide open, Proceeding to remove it")
                security_group.revoke_egress(IpPermissions=[rules[index]])


def responsive_control(sg_id,region):
    """

    :param sg_id: security_group id
    :param region: region of SG_Id
    :return:
    """
    logging.info(f"Proceeding on to deleting the rules from default SGs")
    ec2_resource = boto3.resource ('ec2', region_name=region)
    logging.info(f"Deleting rules from security_group:{sg_id} in Region:{region}")
    security_group = ec2_resource.SecurityGroup(sg_id)

    if security_group.ip_permissions:
        logging.info(f"Deleting the Ingress rules from default SG: {sg_id}")
        security_group.revoke_ingress(IpPermissions=security_group.ip_permissions)

    if security_group.ip_permissions_egress:
        logging.info (f"Deleting the Egress rules from default SG: {sg_id}")
        security_group.revoke_egress(IpPermissions=security_group.ip_permissions_egress)


def detective_control(detail):
    """

    :param detail: event in detail
    :return:
    """
    sns_client = boto3.client('sns')
    event_name = detail["eventName"]
    awsRegion  = detail["awsRegion"]
    groupId    = detail["requestParameters"]["groupId"]
    group_name = ec2_client.describe_security_groups(GroupIds=[groupId])['SecurityGroups'][0]['GroupName']
    rules = detail['requestParameters']['ipPermissions']['items']

    response = sns_client.publish(
        TopicArn=os.environ["TOPIC"],
        Message=f"Anomalous rules are being detected under: {groupId} and also removed to comply with security rules",
    )

    if group_name == 'default':
        logging.info("Found rules under Default Security Group: " + json.dumps(rules,indent=2))
        responsive_control(groupId, awsRegion)
        return response
    else:
        revoke_rules(event_name,groupId, awsRegion)
        return response
