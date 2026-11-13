"""Run release browser checks and expose useful errors in GitHub job annotations."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
parser=argparse.ArgumentParser()
parser.add_argument('--directory',required=True)
args=parser.parse_args()
for name in ['browser_release_boot.py','browser_room_lab.py','browser_isometric_lab.py']:
    command=[sys.executable,str(Path('tests')/name),'--directory',args.directory]
    try:
        result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=360)
        output=result.stdout
        failed=result.returncode!=0
    except subprocess.TimeoutExpired as error:
        output=(error.stdout or b'').decode(errors='replace') if isinstance(error.stdout,bytes) else (error.stdout or '')
        output+='\nBrowser check exceeded six minutes.'
        failed=True
    print(output,flush=True)
    if failed:
        message=name+' failed:\n'+'\n'.join(output.splitlines()[-40:])
        escaped=message.replace('%','%25').replace('\r','%0D').replace('\n','%0A')
        print('::error title=Browser validation failed::'+escaped,flush=True)
        summary=os.environ.get('GITHUB_STEP_SUMMARY')
        if summary:
            with open(summary,'a') as report:
                report.write('## Browser validation failed: '+name+'\n\n```text\n'+output[-20000:].replace('```',"'''")+'\n```\n')
        raise SystemExit(1)
