from datetime import date

from espn_fantasy_matchup_stats.fantasy import MyTeam
from espn_fantasy_matchup_stats.fantasy import my_league
from flask import render_template

from app import app

START_DATE = date(2021, 12, 28)
END_DATE = date(2021, 12, 28)


@app.route("/")
@app.route("/index")
def index():
    my_team = MyTeam(my_league, "Drip Bayless")
    comparison = my_team.get_matchup_comparison(START_DATE, END_DATE)
    decimals = 2
    items = [
        {
            "stat": k,
            "my_score": round(v[0], decimals),
            "opp_score": round(v[1], decimals),
        }
        for k, v in comparison.T.to_dict("list").items()
    ]
    return render_template("index.html", items=items)
