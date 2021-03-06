from espn_api.basketball import League
from espn_fantasy_matchup_stats.auth import Auth
from espn_fantasy_matchup_stats.player_stats import matchup_comparison

# Authenticate
auth = Auth()

# League object
league = League(
    league_id=auth.LEAGUE_ID,
    year=auth.LEAGUE_YEAR,
    espn_s2=auth.LEAGUE_ESPN_S2,
    swid=auth.LEAGUE_SWID,
)

# Find my team and opponent's team
my_team = next((x for x in league.teams if x.team_name == "Drip Bayless"), None)
matchup = my_team.schedule[-1]   
opp_team = matchup.home_team if matchup.home_team.team_name != "Drip Bayless" else matchup.away_team

# Get stats
comparison = matchup_comparison(my_team, opp_team)
print(comparison)
