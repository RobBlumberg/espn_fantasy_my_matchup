from datetime import datetime
from decimal import Decimal
from uuid import uuid1
import os

HOME_TEAM_NAME = "Drip Bayless"


def fantasy_comparison_response_transformer(comparison):

    home_team_stats = comparison[HOME_TEAM_NAME]
    away_team_name = list(comparison.keys())[-1]
    away_team_stats = comparison[away_team_name]

    return {
        "id": str(uuid1()),
        "inserted_at": str(datetime.utcnow()),
        "home_team_name": HOME_TEAM_NAME,
        "home_team_stats": {k: Decimal(str(v)) for k, v in home_team_stats.items()},
        "away_team_name": away_team_name,
        "away_team_stats": {k: Decimal(str(v)) for k, v in away_team_stats.items()},
    }

def remove_files(dir_path):
    if not os.path.exists(dir_path):
        return

    for file_ in os.listdir(dir_path):
        try:
            file_path = f"{dir_path}/{file_}"
            os.remove(file_path)
            print(f"Removed file {file_path}")
        except (PermissionError, FileNotFoundError, IsADirectoryError):
            subdir = f"{dir_path}/{file_}"
            remove_files(subdir)
            os.rmdir(subdir)
            print(f"Removed directory {subdir}")
