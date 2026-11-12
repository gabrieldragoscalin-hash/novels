"""Smoke-test the exact exported release, including its downloaded project pack."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import shutil
import threading
import time
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--directory')
parser.add_argument('--url')
parser.add_argument('--screenshots', default='build/release-checks')
args = parser.parse_args()
assert bool(args.directory) != bool(args.url), 'Specify directory or URL'
server = None
if args.directory:
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(SimpleHTTPRequestHandler, directory=args.directory))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f'http://127.0.0.1:{server.server_port}/'
else:
    url = args.url.rstrip('/') + '/'
output = Path(args.screenshots)
output.mkdir(parents=True, exist_ok=True)
try:
    with sync_playwright() as p:
        executable = next((shutil.which(x) for x in ('chromium', 'google-chrome', 'google-chrome-stable') if shutil.which(x)), None)
        browser = p.chromium.launch(executable_path=executable, args=['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        for name, query in [('hub', ''), ('lab', '?animation_lab=1')]:
            context = browser.new_context(viewport={'width': 390, 'height': 844})
            page = context.new_page()
            # Fail the first chunk once, then require automatic recovery.
            attempts = []
            def interrupted(route):
                attempts.append(route.request.url)
                if len(attempts) == 1:
                    route.fulfill(status=200, body=b'GDPC')
                else:
                    route.continue_()
            page.route('**/*.pck.part0000*', interrupted)
            errors = []
            page.on('pageerror', lambda error: errors.append(str(error)))
            def dialog(message):
                errors.append(message.message)
                message.dismiss()
            page.on('dialog', dialog)
            try:
                page.goto(url + ('?release-check=' + str(time.time_ns()) + ('&' + query[1:] if query else '')), wait_until='domcontentloaded', timeout=120000)
                page.wait_for_function('(name) => window.__dungeonReady === name', arg=name, timeout=120000)
                page.wait_for_timeout(1000)
                assert not errors, errors
                assert len(attempts) == 2, attempts
                print(f'{name}: application ready, no browser errors', flush=True)
            finally:
                page.screenshot(path=str(output / f'{name}.png'))
                context.close()
        # A partial download must show a recoverable message, never call Godot main.
        context = browser.new_context()
        page = context.new_page()
        dialogs = []
        def failed_dialog(dialog):
            dialogs.append(dialog.message)
            dialog.dismiss()
        page.on('dialog', failed_dialog)
        page.route('**/*.pck.part*', lambda route: route.fulfill(status=200, body=b'GDPC'))
        page.goto(url + '?release-check=partial', wait_until='domcontentloaded', timeout=120000)
        page.wait_for_function("document.getElementById('status-notice').textContent.includes('received 4 of')", timeout=120000)
        assert not dialogs, dialogs
        assert not page.evaluate('Boolean(window.__dungeonReady)')
        print('partial download: safely rejected before engine startup', flush=True)
        context.close()
        browser.close()
finally:
    if server:
        server.shutdown()
