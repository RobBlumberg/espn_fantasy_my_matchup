import logging
import os
from datetime import date

import boto3
from espn_fantasy_matchup_stats.fantasy import MyTeam
from espn_fantasy_matchup_stats.fantasy.league_auth import league_from_env

from .helper_io import fantasy_comparison_response_transformer

logging.basicConfig(level=logging.INFO)


START_DATE = date(2021, 12, 28)
END_DATE = date(2021, 12, 29)


def write_outputs(payload):

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("espn_my_fantasy_outputs")
    table.put_item(Item=payload)


def handle(event, context):

    # get stats
    my_league = league_from_env()
    my_team = MyTeam(my_league, "Drip Bayless")
    opp_team = my_team.get_opponents_team()
    comparison = my_team.matchup_comparison(
        my_team, opp_team, START_DATE, END_DATE
    ).to_dict()
    logging.info(f"\n{comparison}")

    # transform payload and write to dynamoDB
    payload = fantasy_comparison_response_transformer(comparison)
    if not os.environ.get("DEBUG"):
        write_outputs(payload)
        logging.info("Posted outputs")
