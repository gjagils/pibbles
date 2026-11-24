// D1 for tests (same helper as Hoeveelishet): the real migrations on an
// in-memory SQLite, behind the part of the D1 API the Worker uses
// (prepare/bind/all/first/run, batch).
import { DatabaseSync } from "node:sqlite";
import { readdirSync, readFileSync } from "node:fs";

export function testDb() {
  const db = new DatabaseSync(":memory:");
  const dir = new URL("../../migrations/", import.meta.url);
  for (const file of readdirSync(dir).sort()) db.exec(readFileSync(new URL(file, dir), "utf8"));
  const prepare = (sql) => {
    let args = [];
    const statement = {
      bind(...values) {
        args = values;
        return statement;
      },
      async all() {
        return { results: db.prepare(sql).all(...args) };
      },
      async first() {
        return db.prepare(sql).get(...args) ?? null;
      },
      async run() {
        return { meta: { changes: db.prepare(sql).run(...args).changes } };
      },
      // As in D1, a batch gives each statement's rows (results) and changes (meta)
      async inBatch() {
        if (/^\s*SELECT|RETURNING/i.test(sql)) return { results: db.prepare(sql).all(...args), meta: { changes: 0 } };
        return { results: [], ...(await statement.run()) };
      },
    };
    return statement;
  };
  return {
    prepare,
    async batch(statements) {
      db.exec("BEGIN");
      try {
        const results = [];
        for (const statement of statements) results.push(await statement.inBatch());
        db.exec("COMMIT");
        return results;
      } catch (error) {
        db.exec("ROLLBACK");
        throw error;
      }
    },
  };
}
