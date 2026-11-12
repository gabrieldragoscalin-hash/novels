// Mount only a complete, verified project pack, before calling Godot's main.
async function startVerifiedGame(options) {
    const filename = GODOT_CONFIG.executable + '.pck';
    const expected = GODOT_CONFIG.fileSizes[filename];
    const loadPack = async () => {
        const response = await fetch(filename, {cache: 'no-store'});
        if (response.status !== 200) throw new Error('Project download failed (' + response.status + '). Please reload to retry.');
        const buffer = await response.arrayBuffer();
        if (buffer.byteLength !== expected) throw new Error('Project download was incomplete. Please reload to retry. Your save is unchanged.');
        const digest = await crypto.subtle.digest('SHA-256', buffer);
        const hash = Array.from(new Uint8Array(digest), b => b.toString(16).padStart(2, '0')).join('');
        if (hash !== '__PACK_SHA256__') throw new Error('Project download failed verification. Please reload to retry. Your save is unchanged.');
        return buffer;
    };
    const [buffer] = await Promise.all([loadPack(), engine.init(GODOT_CONFIG.executable)]);
    await engine.preloadFile(buffer, filename);
    return engine.start({...options, args: ['--main-pack', filename, ...GODOT_CONFIG.args]});
}
