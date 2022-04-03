import subprocess
from metaflow import Metaflow, namespace
from espn_fantasy_my_matchup.helper_io import remove_files

def handle(event, context):

    # print()

    # namespace(None)

    # mf = Metaflow()
    # flow = mf.flows
    # print(flow)
    
    # print(event)
    # print(context)
    #from espn_fantasy_my_matchup.helper_io import fantasy_comparison_response_transformer, remove_files
    remove_files("/tmp/.metaflow")
    subprocess.run(["python", "-m", "espn_fantasy_my_matchup.flow", "--no-pylint", "run"])
