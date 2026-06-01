import knex from 'knex';

const db = knex({
  client: 'pg',
  connection: 'postgresql://learnex_user:learnex_pass@localhost:5433/learnex_db',
});

async function migrate() {
  try {
    const hasColumn = await db.schema.hasColumn('posts', 'visibility');
    if (!hasColumn) {
      await db.schema.alterTable('posts', (table) => {
        table.string('visibility', 20).defaultTo('public');
      });
      console.log('✅ Column visibility added!');
    } else {
      console.log('Column visibility already exists');
    }
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    process.exit(0);
  }
}

migrate();
