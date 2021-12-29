from espn_fantasy_matchup_stats.fantasy import my_league
from espn_fantasy_matchup_stats.fantasy import MyTeam
from .helper_io import fantasy_comparison_response_transformer
import boto3
import os
import logging

from datetime import date

logging.basicConfig(level=logging.INFO)


START_DATE = date(2021, 12, 28)
END_DATE = date(2021, 12, 29)


def write_outputs(payload):

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("espn_my_fantasy_outputs")
    table.put_item(Item=payload)


def handle(event, context):

    # get stats
    my_team = MyTeam(my_league, "Drip Bayless")
    comparison = my_team.get_matchup_comparison(START_DATE, END_DATE).to_dict()
    logging.info(f"\n{comparison}")

    # transform payload and write to dynamoDB
    payload = fantasy_comparison_response_transformer(comparison)
    if not os.environ.get("DEBUG"):
        write_outputs(payload)
        logging.info("Posted outputs")
