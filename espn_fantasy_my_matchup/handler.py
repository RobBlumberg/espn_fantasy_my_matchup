import subprocess

def handle(event, context):

    subprocess.run(["python", "-m", "espn_fantasy_my_matchup.flow", "run"])
