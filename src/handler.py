#from espn_fantasy_matchup_stats.auth import my_league
#from espn_fantasy_matchup_stats.my_team import MyTeam
import logging
from src.secret_manager import get_secret
import os

logging.basicConfig(level = logging.INFO)

# Get stats
def handle(event, context):

    response = [
        os.environ["LEAGUE_SWID"],
        os.environ["LEAGUE_ID"],
        os.environ["LEAGUE_ESPN_S2"]
    ]
        
    #my_team = MyTeam(my_league, "Drip Bayless")
    #comparison = my_team.get_current_matchup_comparison()
    #logging.info(comparison)
    print(response)
    return response