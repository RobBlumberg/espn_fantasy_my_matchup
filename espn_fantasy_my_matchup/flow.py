import logging
import os
from datetime import date
import pandas as pd
import time

import boto3
from espn_fantasy_matchup_stats.fantasy import MyTeam
from espn_fantasy_matchup_stats.fantasy.league_auth import league_from_env

#from espn_fantasy_my_matchup.helper_io import fantasy_comparison_response_transformer, remove_files

logging.basicConfig(level=logging.INFO)

from metaflow import FlowSpec, step, metadata, conda, S3, current

from datetime import datetime
import pytz

import pickle

START_DATE = date(2021, 12, 28)
END_DATE = date(2021, 12, 29)


class ESPNFantasyFlow(FlowSpec):

    @step
    def start(self):
        remove_files(f"/tmp/.metaflow/{current.flow_name}", exclude_run_id=current.run_id)
        # get stats
        my_league = league_from_env()
        self.my_team = MyTeam(my_league, "Drip Bayless")
        self.opp_team = self.my_team.get_opponents_team()
        
        self.next(self.get_comparison)

    @step
    def get_comparison(self):
        # TODO: fix
        # self.comparison = self.my_team.matchup_comparison(
        #     self.my_team, self.opp_team, START_DATE, END_DATE
        # ).to_dict()
        # logging.info(f"\n{self.comparison}")
        # TEMP:
        self.comparison = pd.DataFrame({"a": [1, 2, 3]})

        # with S3(s3root='s3://espn-fantasy-s3-test/') as s3:
        #     comp_df_bytes = pickle.dumps(self.comparison)
        #     s3.put(f"metaflow/outputs/{current.flow_name}/{current.run_id}/{current.step_name}/comparison_df", comp_df_bytes)

        #self.next(self.write_outputs)
        self.next(self.end)

    # @step
    # def write_outputs(self):
    #     # TODO: fix
    #     # payload = fantasy_comparison_response_transformer(self.comparison)
    #     # TEMP:
    #     self.payload = pd.DataFrame({"b": [4, 5, 6]})

    #     self.next(self.end)
    
    @step
    def end(self):
        self.dummy_artifact = "here"

def remove_files(dir_path, exclude_run_id=-1):
    if exclude_run_id in dir_path:
        return

    for file_ in os.listdir(dir_path):
        try:
            file_path = f"{dir_path}/{file_}"
            os.remove(file_path)
            print(f"Removed file {file_path}")
        except (PermissionError, FileNotFoundError, IsADirectoryError):
            subdir = f"{dir_path}/{file_}"
            remove_files(subdir, exclude_run_id=exclude_run_id)
            if exclude_run_id in subdir:
                return
            os.rmdir(subdir)
            print(f"Removed directory {subdir}")


ESPNFantasyFlow()