# Creator Funnel OS API

Node/Fastify API for the Creator Funnel OS iOS client.

```sh
cp .env.example .env
docker compose up -d postgres
npm install
npm run db:migrate
npm run dev
```

Requires Node 20+ and PostgreSQL 16+. Run behind TLS. Meta access tokens are encrypted with AES-256-GCM before storage.

For controlled own-account testing, webhook work runs just after the signed request is acknowledged. Before high-volume public traffic, move processing to a durable queue with retries and dead-letter monitoring. Add transactional email and App Store Server verification before public launch.

Run `npm run accounts:delete-due` from a daily scheduled job so confirmed deletion requests are completed at the disclosed date.
