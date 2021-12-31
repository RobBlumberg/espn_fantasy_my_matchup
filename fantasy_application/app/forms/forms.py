from flask_wtf import FlaskForm
from wtforms import SelectField
from wtforms import StringField
from wtforms import SubmitField
from wtforms.validators import DataRequired

from .constants import STAT_CHOICES


class MatchupForm(FlaskForm):
    your_team = StringField("Your Team Name", validators=[DataRequired()])
    opp_team = StringField("Your Opponent's Team Name", validators=[DataRequired()])
    stat_type = SelectField(
        "Stat Type", choices=STAT_CHOICES, validators=[DataRequired()]
    )
    start_date = StringField("Start Date", validators=[DataRequired()])
    end_date = StringField("End Date", validators=[DataRequired()])
    submit = SubmitField("Submit")
