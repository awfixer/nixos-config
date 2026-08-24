import { describe, it, expect, beforeEach } from 'vitest';
import type { Express } from 'express';
import { createApp } from '../../app.js';
import { initDb, getDb } from '../../db/index.js';
import { mintDashboardToken, isGatedApiPath } from '../helpers/auth.js';
import { ensureAllModelsInProfiles, ensureModelInProfiles } from '../../services/profile-models.js';

// Named fallback chains you build by hand (#895). Two things have to hold for
// a curated chain to survive: creating one must not dump the whole catalog
// into it, and the catalog-sync backfill must leave it alone afterwards.
let app: Express;
let dashToken = '';

async function request(method: string, path: string, body?: unknown) {
  const server = app.listen(0, '127.0.0.1');
  if (!server.listening) await new Promise<void>(resolve => server.once('listening', () => resolve()));
  const addr = server.address() as { port: number };
  const res = await fetch(`http://127.0.0.1:${addr.port}${path}`, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(isGatedApiPath(path) ? { Authorization: `Bearer ${dashToken}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => null);
  server.close();
  return { status: res.status, body: data };
}

function chainSize(profileId: number): number {
  return (getDb().prepare('SELECT COUNT(*) AS n FROM profile_models WHERE profile_id = ?')
    .get(profileId) as { n: number }).n;
}

function autoInclude(profileId: number): number {
  return (getDb().prepare('SELECT auto_include_new_models AS flag FROM profiles WHERE id = ?')
    .get(profileId) as { flag: number }).flag;
}

// A model that arrives after the chains already exist — what a catalog sync
// produces, and what the backfill would otherwise push into every chain.
function addCatalogModel(modelId: string): number {
  const db = getDb();
  const inserted = db.prepare(`
    INSERT INTO models (platform, model_id, display_name, intelligence_rank, speed_rank, size_label, enabled)
    VALUES ('groq', ?, ?, 500, 500, 'Small', 1)
  `).run(modelId, `Synced ${modelId}`);
  const id = Number(inserted.lastInsertRowid);
  db.prepare('INSERT INTO fallback_config (model_db_id, priority, enabled) VALUES (?, 500, 1)').run(id);
  return id;
}

describe('named fallback chains', () => {
  beforeEach(() => {
    process.env.ENCRYPTION_KEY = '0'.repeat(64);
    initDb(':memory:');
    app = createApp();
    dashToken = mintDashboardToken();
  });

  it('creates an empty chain that holds nothing (#895)', async () => {
    const { status, body } = await request('POST', '/api/profiles', { name: 'hand-built', empty: true });
    expect(status).toBe(201);
    expect(body.name).toBe('hand-built');
    expect(chainSize(body.id)).toBe(0);
    // An empty chain opts out of the backfill by construction — otherwise the
    // next catalog sync would undo the emptiness.
    expect(autoInclude(body.id)).toBe(0);
  });

  it('still copies the catalog when empty is not asked for', async () => {
    const { status, body } = await request('POST', '/api/profiles', { name: 'inherited' });
    expect(status).toBe(201);

    const catalogSize = (getDb().prepare('SELECT COUNT(*) AS n FROM fallback_config').get() as { n: number }).n;
    expect(catalogSize).toBeGreaterThan(0);
    expect(chainSize(body.id)).toBe(catalogSize);
    expect(autoInclude(body.id)).toBe(1);
  });

  it('lets empty win over a source chain to copy from', async () => {
    const source = await request('POST', '/api/profiles', { name: 'source' });
    expect(chainSize(source.body.id)).toBeGreaterThan(0);

    const { status, body } = await request('POST', '/api/profiles', {
      name: 'empty-clone', empty: true, sourceProfileId: source.body.id,
    });
    expect(status).toBe(201);
    expect(chainSize(body.id)).toBe(0);
  });

  it('keeps a curated chain pruned across a catalog backfill (#895)', async () => {
    const curated = (await request('POST', '/api/profiles', { name: 'curated', empty: true })).body;
    const inheriting = (await request('POST', '/api/profiles', { name: 'inheriting' })).body;
    const inheritingBefore = chainSize(inheriting.id);

    addCatalogModel('backfill-arrival');
    ensureAllModelsInProfiles(getDb());

    // The chain that opted in grew by the new model; the curated one did not.
    expect(chainSize(inheriting.id)).toBe(inheritingBefore + 1);
    expect(chainSize(curated.id)).toBe(0);
  });

  it('keeps a curated chain pruned when a single model is registered', async () => {
    const curated = (await request('POST', '/api/profiles', { name: 'curated', empty: true })).body;
    const inheriting = (await request('POST', '/api/profiles', { name: 'inheriting' })).body;
    const inheritingBefore = chainSize(inheriting.id);

    // The per-model path, used when one custom endpoint model is registered.
    const modelDbId = addCatalogModel('single-arrival');
    ensureModelInProfiles(getDb(), modelDbId);

    expect(chainSize(inheriting.id)).toBe(inheritingBefore + 1);
    expect(chainSize(curated.id)).toBe(0);
  });

  it('lets a chain opt out of the backfill after the fact', async () => {
    const chain = (await request('POST', '/api/profiles', { name: 'settled' })).body;
    expect(autoInclude(chain.id)).toBe(1);

    // Prune it by hand, then stop new models from being pushed back in.
    getDb().prepare('DELETE FROM profile_models WHERE profile_id = ?').run(chain.id);
    const updated = await request('PUT', `/api/profiles/${chain.id}`, { auto_include_new_models: false });
    expect(updated.status).toBe(200);
    expect(updated.body.auto_include_new_models).toBe(0);
    expect(autoInclude(chain.id)).toBe(0);

    addCatalogModel('after-opt-out');
    ensureAllModelsInProfiles(getDb());
    expect(chainSize(chain.id)).toBe(0);
  });

  it('reports the flag on the chain listing so the dashboard can show it', async () => {
    await request('POST', '/api/profiles', { name: 'curated', empty: true });
    const { status, body } = await request('GET', '/api/profiles');
    expect(status).toBe(200);

    const curated = body.find((p: { name: string }) => p.name === 'curated');
    expect(curated.auto_include_new_models).toBe(0);
    // The seeded Default chain keeps the old behaviour.
    const fallbackDefault = body.find((p: { type: string }) => p.type === 'default');
    expect(fallbackDefault.auto_include_new_models).toBe(1);
  });
});
