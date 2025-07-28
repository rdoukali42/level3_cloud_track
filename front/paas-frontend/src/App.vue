<template>
  <div id="app">
    <button v-if="!isAuthenticated" @click="login" class="stackit-login-btn">Login with Zitadel</button>
    <DatabaseManager v-if="isAuthenticated" />
  </div>
</template>

<script>
import DatabaseManager from './components/DatabaseManager.vue';
import { userManager } from "@/services/auth";

export default {
  components: { DatabaseManager },
  data() {
    return {
      isAuthenticated: !!localStorage.getItem("jwt")
    };
  },
  methods: {
    login() {
      userManager.signinRedirect();
    },
    async handleCallback() {
      const user = await userManager.signinRedirectCallback();
      console.log("OIDC user object:", user);
      localStorage.setItem("jwt", user.access_token);
      this.isAuthenticated = true;
      // Optionally redirect to home or update UI
    }
  },
  mounted() {
    if (window.location.pathname === "/callback") {
      this.handleCallback();
    }
  }
};
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

.stackit-login-btn {
  background: #004E5A;
  color: #FBFBFB;
  border: none;
  border-radius: 10px;
  padding: 0.7rem 2.2rem;
  font-size: 1.15rem;
  font-weight: 700;
  letter-spacing: 1px;
  cursor: pointer;
  margin-bottom: 2.5rem;
  box-shadow: 0 2px 8px rgba(0, 78, 90, 0.10);
  transition: background 0.15s;
}
.stackit-login-btn:hover {
  background: #00707e;
}
</style>
