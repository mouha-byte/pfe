from __future__ import annotations

import json
import random
import time
from datetime import datetime, timezone
from typing import Generator

from flask import Flask, Response, jsonify, render_template, stream_with_context

app = Flask(__name__)

DEFECTS = [
    'Capteur position',
    'Surchauffe moteur',
    'Erreur vision',
    'Pression hydraulique',
    'Derive temperature',
    'Calibration robot',
]

PRIORITIES = ['A', 'B']
STATUSES = ['OPEN', 'CLOSED']


def generate_status() -> dict[str, str | int]:
    flash = random.randint(0, 6)
    priority = random.choices(PRIORITIES, weights=(0.35, 0.65), k=1)[0]
    status = random.choices(STATUSES, weights=(0.55, 0.45), k=1)[0]
    defect = random.choice(DEFECTS)

    if status == 'CLOSED' and flash == 0:
        defect = 'Aucun defaut'

    return {
        'flash': flash,
        'defect': defect,
        'priority': priority,
        'status': status,
        'timestamp': datetime.now(timezone.utc).isoformat(),
    }


@app.get('/')
def index() -> str:
    return render_template('index.html')


@app.get('/status')
def get_status() -> Response:
    return jsonify(generate_status())


def event_stream() -> Generator[str, None, None]:
    while True:
        payload = generate_status()
        yield 'event: status\n'
        yield f'data: {json.dumps(payload)}\n\n'
        time.sleep(2)


@app.get('/stream')
def stream() -> Response:
    headers = {
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
    }
    return Response(
        stream_with_context(event_stream()),
        mimetype='text/event-stream',
        headers=headers,
    )


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
