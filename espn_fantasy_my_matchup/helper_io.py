from datetime import datetime
from uuid import uuid1
from decimal import Decimal

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

