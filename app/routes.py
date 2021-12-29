from app import app

from espn_fantasy_matchup_stats.fantasy import my_league
from espn_fantasy_matchup_stats.fantasy import MyTeam

from datetime import date

START_DATE = date(2021, 12, 28)
END_DATE = date(2021, 12, 29)

@app.route('/')
@app.route('/index')
def index():
    my_team = MyTeam(my_league, "Drip Bayless")
    comparison = my_team.get_matchup_comparison(START_DATE, END_DATE).to_dict()
    return comparison