from espn_fantasy_matchup_stats.auth import my_league
from espn_fantasy_matchup_stats.my_team import MyTeam
import logging
import os

logging.basicConfig(level = logging.INFO)

# Get stats
def handle(event, context):
        
    my_team = MyTeam(my_league, "Drip Bayless")
    comparison = my_team.get_current_matchup_comparison()
    logging.info(f"\n{comparison}")

    return comparison.to_json()