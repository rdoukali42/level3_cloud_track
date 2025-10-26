import { UserManager } from "oidc-client-ts";

const oidcConfig = {
  authority: process.env.VUE_APP_ZITADEL_ISSUER || "https://your-instance.zitadel.cloud",
  client_id: process.env.VUE_APP_ZITADEL_CLIENT_ID || "your-frontend-client-id",
  redirect_uri: process.env.VUE_APP_REDIRECT_URI || "http://localhost:8086/callback",
  response_type: "code",
  scope: "openid profile email",
  post_logout_redirect_uri: process.env.VUE_APP_POST_LOGOUT_URI || "http://localhost:8086/",
};

export const userManager = new UserManager(oidcConfig);