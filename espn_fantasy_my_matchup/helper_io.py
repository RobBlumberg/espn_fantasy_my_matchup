from datetime import datetime
from uuid import uuid1

HOME_TEAM_NAME = "Drip Bayless"

def fantasy_comparison_response_transformer(comparison_json):
    
    home_team_stats = comparison_json[HOME_TEAM_NAME]
    away_team_name = list(comparison_json.keys())[-1]
    away_team_stats = comparison_json[away_team_name]
    
    return {
        "id": uuid1(),
        "inserted_at": datetime.utcnow(),
        "home_team_name": HOME_TEAM_NAME,
        "home_team_stats": home_team_stats,
        "away_team_name": away_team_name,
        "away_team_stats": away_team_stats,
    }

