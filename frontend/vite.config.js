import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      "/": "http://localhost:5000",
      "/login": "http://localhost:5000",
      "/register": "http://localhost:5000",
      "/api": "http://localhost:5000",
      "/healthz": "http://localhost:5000",
      "/logout": "http://localhost:5000",
    },
  },
});
