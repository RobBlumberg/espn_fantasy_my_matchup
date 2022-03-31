import subprocess
from metaflow import Metaflow, namespace

def handle(event, context):

    print()

    namespace(None)

    mf = Metaflow()
    flow = mf.flows
    print(flow)
    
    print(event)
    print(context)

    #subprocess.run(["python", "-m", "espn_fantasy_my_matchup.flow", "run"])
