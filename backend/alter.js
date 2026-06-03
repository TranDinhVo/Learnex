const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5433,
  user: 'learnex_user',
  password: 'learnex_pass',
  database: 'learnex_db'
});

async function run() {
  try {
    await client.connect();
    console.log('Connected to DB');
    await client.query('ALTER TABLE comments ADD COLUMN IF NOT EXISTS reply_to_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE;');
    console.log('Column added');
  } catch (err) {
    console.error('Error', err);
  } finally {
    await client.end();
  }
}

run();
