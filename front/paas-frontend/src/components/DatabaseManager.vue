<template>
  <div class="stackit-db-manager">
    <header class="main-header">Postgresql Database Manager</header>
    <h2>Databases</h2>
    <div class="actions">
      <button class="refresh-btn" @click="fetchDatabases">⟳ Refresh</button>
      <form class="create-form" @submit.prevent="createDatabase">
        <input v-model="newDb" placeholder="New database name" />
        <button type="submit" class="create-btn">＋ Create</button>
      </form>
    </div>
    <ul class="db-list">
      <li v-for="db in databases" :key="db" class="db-item">
        <span>{{ db }}</span>
        <button class="delete-btn" @click="deleteDatabase(db)">Delete</button>
      </li>
    </ul>
    <div v-if="error" class="error-msg">{{ error }}</div>
    <div v-if="success" class="success-msg">{{ success }}</div>
  </div>
</template>

<script>
import api from '../services/api';

export default {
  data() {
    return {
      databases: [],
      newDb: '',
      error: '',
      success: ''
    };
  },
  methods: {
    async fetchDatabases() {
      this.error = '';
      try {
        const res = await api.get('/api/v1/databases');
        this.databases = res.data;
      } catch (e) {
        this.error = e.response?.data?.error || 'Failed to fetch databases';
      }
    },
    async createDatabase() {
      this.error = '';
      this.success = '';
      try {
        await api.post('/api/v1/databases', { name: this.newDb });
        this.success = 'Database created!';
        this.newDb = '';
        this.fetchDatabases();
      } catch (e) {
        this.error = e.response?.data?.error || 'Failed to create database';
      }
    },
    async deleteDatabase(name) {
      this.error = '';
      this.success = '';
      try {
        await api.delete(`/api/v1/databases/${name}`);
        this.success = 'Database deleted!';
        this.fetchDatabases();
      } catch (e) {
        this.error = e.response?.data?.error || 'Failed to delete database';
      }
    }
  },
  mounted() {
    this.fetchDatabases();
  }
};
</script>

<style scoped>
.stackit-db-manager {
  background: #FBFBFB;
  border-radius: 16px;
  box-shadow: 0 2px 16px rgba(0, 78, 90, 0.08);
  padding: 2rem 2.5rem;
  max-width: 420px;
  margin: 2rem auto;
  font-family: 'Segoe UI', 'Avenir', Helvetica, Arial, sans-serif;
  color: #004E5A;
}

.main-header {
  font-size: 1.3rem;
  font-weight: 800;
  letter-spacing: 2px;
  color: #FBFBFB;
  background: #004E5A;
  border-radius: 10px;
  padding: 0.7rem 1.2rem;
  margin-bottom: 2rem;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0, 78, 90, 0.10);
}

h2 {
  color: #004E5A;
  margin-bottom: 1.5rem;
  font-weight: 700;
  letter-spacing: 1px;
}

.actions {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.refresh-btn, .create-btn, .delete-btn {
  background: #004E5A;
  color: #FBFBFB;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1.1rem;
  font-size: 1rem;
  cursor: pointer;
  transition: background 0.15s;
}

.refresh-btn:hover, .create-btn:hover, .delete-btn:hover {
  background: #00707e;
}

.create-form {
  display: flex;
  gap: 0.5rem;
}

.create-form input {
  border: 1px solid #004E5A;
  border-radius: 6px;
  padding: 0.5rem 0.8rem;
  font-size: 1rem;
  background: #FBFBFB;
  color: #004E5A;
  outline: none;
  transition: border 0.15s;
}

.create-form input:focus {
  border: 1.5px solid #00707e;
}

.db-list {
  list-style: none;
  padding: 0;
  margin: 0 0 1.5rem 0;
}

.db-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #e6f3f5;
  border-radius: 6px;
  padding: 0.6rem 1rem;
  margin-bottom: 0.7rem;
  font-size: 1.05rem;
}

.delete-btn {
  background: #004E5A;
  color: #FBFBFB;
  border: none;
  border-radius: 4px;
  padding: 0.3rem 0.8rem;
  font-size: 0.95rem;
  margin-left: 1rem;
}

.error-msg {
  color: #b00020;
  background: #fff0f0;
  border: 1px solid #b00020;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  margin-top: 1rem;
  font-weight: 500;
}

.success-msg {
  color: #00695c;
  background: #e0f7fa;
  border: 1px solid #00695c;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  margin-top: 1rem;
  font-weight: 500;
}
</style>