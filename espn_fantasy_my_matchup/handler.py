import subprocess
from metaflow import Metaflow, namespace

def handle(event, context):

    namespace(None)

    mf = Metaflow()
    flow = mf.flows[0]
    runs = flow.runs()
    r = next(runs)
    steps = [s for s in r.steps()]
    print(steps[-1].task.data)

    #subprocess.run(["python", "-m", "espn_fantasy_my_matchup.flow", "run"])
