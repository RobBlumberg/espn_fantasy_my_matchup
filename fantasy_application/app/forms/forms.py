from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField
from wtforms.validators import DataRequired


class MatchupForm(FlaskForm):
    your_team = StringField('Your Team Name', validators=[DataRequired()])
    opp_team = StringField("Your Opponent's Team Name", validators=[DataRequired()])
    stat_type = StringField('Stat Type', validators=[DataRequired()])
    start_date = StringField('Start Date', validators=[DataRequired()])
    end_date = StringField('End Date', validators=[DataRequired()])
    submit = SubmitField('Submit')