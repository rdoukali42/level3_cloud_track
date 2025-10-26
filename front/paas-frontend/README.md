# PaaS Frontend - Database Management UI

Modern Vue.js application for managing PostgreSQL databases with OAuth authentication.

## Features

- **OAuth Authentication**: Secure login via ZITADEL
- **Database Management**: Intuitive UI for database operations
- **Real-time Updates**: Dynamic database listing
- **Responsive Design**: Works on desktop and mobile

## Setup

```bash
# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
```

## Development

```bash
# Run development server
npm run serve

# Build for production
npm run build

# Lint and fix files
npm run lint
```

## Environment Variables

Create a `.env` file:

```bash
VUE_APP_ZITADEL_ISSUER=https://your-instance.zitadel.cloud
VUE_APP_ZITADEL_CLIENT_ID=your-frontend-client-id
VUE_APP_REDIRECT_URI=http://localhost:8086/callback
VUE_APP_POST_LOGOUT_URI=http://localhost:8086/
VUE_APP_API_BASE_URL=http://localhost:30081
```

## ZITADEL Configuration

1. Create a new **Web Application** in ZITADEL
2. Set redirect URIs:
   - `http://localhost:8086/callback`
   - `https://your-production-domain.com/callback`
3. Enable **Authorization Code** flow
4. Add `openid`, `profile`, and `email` scopes
5. Copy the Client ID to your `.env` file

## Deployment

### Production Build

```bash
npm run build
```

The `dist/` folder contains the production-ready files.

### Deploy to Kubernetes

```bash
# Build Docker image
docker build -t your-registry/paas-frontend:latest .

# Push to registry
docker push your-registry/paas-frontend:latest

# Deploy with kubectl
kubectl apply -f k8s/frontend-deployment.yaml
```

### Deploy to Static Hosting

Upload the `dist/` folder to:
- Netlify
- Vercel
- AWS S3 + CloudFront
- GitHub Pages

## Project Structure

```
src/
├── App.vue              # Main application component
├── main.js              # Application entry point
├── components/
│   └── DatabaseManager.vue  # Database management UI
└── services/
    ├── auth.js          # OIDC authentication service
    └── api.js           # API client with JWT interceptor
```

## Troubleshooting

### Login Redirect Issues

- Verify redirect URIs match in ZITADEL and `.env`
- Check browser console for CORS errors
- Ensure API CORS is configured correctly

### API Connection Fails

- Verify `VUE_APP_API_BASE_URL` is correct
- Check that backend is running
- Verify JWT token is being sent in requests
