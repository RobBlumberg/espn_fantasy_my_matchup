import logging
import os
from datetime import date

import boto3
from espn_fantasy_matchup_stats.fantasy import MyTeam
from espn_fantasy_matchup_stats.fantasy.league_auth import league_from_env

from espn_fantasy_my_matchup.helper_io import fantasy_comparison_response_transformer

logging.basicConfig(level=logging.INFO)

from metaflow import FlowSpec, step, metadata, conda

from datetime import datetime
import pytz

START_DATE = date(2021, 12, 28)
END_DATE = date(2021, 12, 29)

class ESPNFantasyFlow(FlowSpec):

    @step
    def start(self):
        print("Starting metaflow workflow...")

        # get stats
        my_league = league_from_env()
        self.my_team = MyTeam(my_league, "Drip Bayless")
        self.opp_team = self.my_team.get_opponents_team()
        
        self.next(self.get_comparison)

    @step
    def get_comparison(self):

        self.comparison = self.my_team.matchup_comparison(
            self.my_team, self.opp_team, START_DATE, END_DATE
        ).to_dict()
        logging.info(f"\n{self.comparison}")

        self.next(self.write_outputs)

    @step
    def write_outputs(self):
        payload = fantasy_comparison_response_transformer(self.comparison)

        self.next(self.end)
    
    @step
    def end(self):
        pass

def handle(event, context):

    ESPNFantasyFlow()

if __name__ == "__main__":
    handle({}, {})
