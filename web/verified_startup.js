// Small independently retriable downloads avoid relying on one large transfer.
async function startVerifiedGame(options) {
    const filename = GODOT_CONFIG.executable + '.pck';
    const expected = GODOT_CONFIG.fileSizes[filename];
    const chunks = __PACK_CHUNKS__;
    const buffer = new Uint8Array(expected);
    let completed = 0;
    const sha256 = async bytes => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)), b => b.toString(16).padStart(2, '0')).join('');
    const download = async chunk => {
        let detail = '';
        for (let attempt = 0; attempt < 3; attempt++) {
            try {
                const url = new URL(chunk.file, location.href);
                if (attempt) url.searchParams.set('retry', Date.now() + '-' + attempt);
                const response = await fetch(url, {cache: 'no-store', signal: AbortSignal.timeout(30000)});
                if (response.status !== 200) throw new Error('HTTP ' + response.status);
                const bytes = await response.arrayBuffer();
                if (bytes.byteLength !== chunk.size) throw new Error('received ' + bytes.byteLength + ' of ' + chunk.size + ' bytes');
                if (await sha256(bytes) !== chunk.sha256) throw new Error('checksum mismatch');
                buffer.set(new Uint8Array(bytes), chunk.offset);
                completed += bytes.byteLength;
                options.onProgress?.(completed, expected);
                return;
            } catch (error) {
                detail = error.message;
            }
        }
        throw new Error('Could not download game data (' + chunk.file + ': ' + detail + '). Please try again later. Your save is unchanged.');
    };
    let next = 0;
    await Promise.all(Array.from({length: 3}, async () => {
        while (next < chunks.length) await download(chunks[next++]);
    }));
    if (await sha256(buffer) !== '__PACK_SHA256__') throw new Error('Game data failed verification. Your save is unchanged.');
    // Start the engine only after the project data is complete.
    await engine.init(GODOT_CONFIG.executable);
    await engine.preloadFile(buffer.buffer, filename);
    return engine.start({...options, args: ['--main-pack', filename, ...GODOT_CONFIG.args]});
}
