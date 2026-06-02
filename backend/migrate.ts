import knex from 'knex';

const db = knex({
  client: 'pg',
  connection: 'postgresql://learnex_user:learnex_pass@localhost:5433/learnex_db',
});

async function migrate() {
  try {
    const hasColumn = await db.schema.hasColumn('posts', 'tagged_user_ids');
    if (!hasColumn) {
      await db.schema.alterTable('posts', (table) => {
        table.jsonb('tagged_user_ids');
      });
      console.log('✅ Column tagged_user_ids added!');
    } else {
      console.log('Column tagged_user_ids already exists');
    }
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    process.exit(0);
  }
}

migrate();
