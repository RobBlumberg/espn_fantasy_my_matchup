from datetime import date

from espn_fantasy_matchup_stats.fantasy import MyTeam
from espn_fantasy_matchup_stats.fantasy.league_auth import league_from_env
from flask import render_template

from app import app
from app.forms import MatchupForm

START_DATE = date(2021, 12, 29)
END_DATE = date(2022, 1, 2)


@app.route("/", methods=["GET", "POST"])
@app.route("/index", methods=["GET", "POST"])
def index():
    form = MatchupForm()

    my_league = league_from_env()
    team1 = MyTeam(my_league, "Drip Bayless")
    team2 = team1.get_opponents_team()
    comparison = MyTeam.matchup_comparison(
        team1, team2, START_DATE, END_DATE, stat_type="total"
    )
    decimals = 2
    items = [
        {
            "stat": k,
            "my_score": round(v[0], decimals),
            "opp_score": round(v[1], decimals),
        }
        for k, v in comparison.T.to_dict("list").items()
    ]
    return render_template("index.html", form=form, items=items)
