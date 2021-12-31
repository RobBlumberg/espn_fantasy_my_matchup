from datetime import datetime

from espn_fantasy_matchup_stats.fantasy import MyTeam
from espn_fantasy_matchup_stats.fantasy.league_auth import league_from_env
from flask import render_template
from flask import request

from app import app
from app.forms import MatchupForm


@app.route("/", methods=["GET", "POST"])
@app.route("/index", methods=["GET", "POST"])
def index():
    form = MatchupForm()

    if form.validate_on_submit():
        team1_name = form.your_team.data
        team2_name = form.opp_team.data
        stat_type = form.stat_type.data
        start_date = form.start_date.data
        end_date = form.end_date.data

        my_league = league_from_env()
        team1 = MyTeam(my_league, team1_name)
        team2 = MyTeam(my_league, team2_name)

        start_date = datetime.strptime(start_date, "%Y-%m-%d").date()
        end_date = datetime.strptime(end_date, "%Y-%m-%d").date()

        comparison = MyTeam.matchup_comparison(
            team1, team2, start_date, end_date, stat_type=stat_type
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
    elif request.method == "GET":
        items = [{}]
    else:
        items = [{}]

    return render_template("index.html", form=form, items=items)
