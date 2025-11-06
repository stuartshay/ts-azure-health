import { PublicClientApplication, type Configuration } from "@azure/msal-browser";

const config: Configuration = {
  auth: {
    clientId: process.env.NEXT_PUBLIC_AAD_CLIENT_ID!,
    authority: `https://login.microsoftonline.com/${process.env.NEXT_PUBLIC_AAD_TENANT_ID}`,
    redirectUri: process.env.NEXT_PUBLIC_REDIRECT_URI,
  },
  cache: { cacheLocation: "sessionStorage" },
};

export const msal = new PublicClientApplication(config);
