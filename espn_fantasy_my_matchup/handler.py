from espn_fantasy_matchup_stats.auth import my_league
from espn_fantasy_matchup_stats.my_team import MyTeam
from .helper_io import fantasy_comparison_response_transformer
import boto3
import os
import logging

logging.basicConfig(level = logging.INFO)


def write_outputs(payload):

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('espn_my_fantasy_outputs')
    table.put_item(Item=payload)


def handle(event, context):
    
    # get stats
    my_team = MyTeam(my_league, "Drip Bayless")
    comparison = my_team.get_current_matchup_comparison()
    logging.info(f"\n{comparison.to_json()}")
    
    # transform payload and write to dynamoDB
    payload = fantasy_comparison_response_transformer(comparison)
    if not os.environ.get("DEBUG"):
        logging.info("posted")
        write_outputs(payload)
    else:
        logging.info("not posted")