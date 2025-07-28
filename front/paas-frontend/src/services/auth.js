import { UserManager } from "oidc-client-ts";

const oidcConfig = {
  authority: "https://first0cloud-shf5wf.us1.zitadel.cloud",
  client_id: "330412500052946224",
  redirect_uri: "http://localhost:8086/callback",
  response_type: "code",
  scope: "openid profile email",
  post_logout_redirect_uri: "http://localhost:8086/",
};

export const userManager = new UserManager(oidcConfig);