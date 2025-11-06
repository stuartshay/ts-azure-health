import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "TS Azure Health - Frontend Starter",
  description: "Next.js + BFF + Key Vault + Azure Container Apps",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
