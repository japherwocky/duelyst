# OpenDuelyst

![Duelyst Logo](app/resources/ui/brand_duelyst.png)

This is the source code for Duelyst, a digital collectible card game and
turn-based strategy hybrid developed by Counterplay Games and released in 2016.

## Production Deployment

Work is underway to deploy OpenDuelyst as "Duelyst Classic": a version of the
game exactly as it was in v1.96.17, before the servers were shut down. This is
being tracked in [issue #3](https://github.com/open-duelyst/duelyst/issues/3).

## Staging Deployment

The staging deployment is up and running at https://staging.duelyst.org. Both
single-player and multi-player games are available.

## Downloading the Desktop Clients

Desktop clients for Windows, Mac, and Linux can be downloaded on the
[Releases](https://github.com/open-duelyst/duelyst/releases) page.

Desktop clients currently use the staging environment. They'll use the
production environment once it's available.

## Playing on Android or iOS

We have basic support for playing on mobile web currently. From your phone's
browser, head to https://staging.duelyst.org to try it out.

To hide the status/navigation bar in Chrome or Safari, open the game and select
"Add to Home Screen". When you open the game from the home screen, the status
bar will be hidden.

## Contributing to OpenDuelyst

If you'd like to contribute to OpenDuelyst, check out our
[Documentation](docs/README.md), especially the [Roadmap](docs/ROADMAP.md) and
[Contributor Guide](docs/CONTRIBUTING.md).

You can also join the OpenDuelyst developer Discord server
[here](https://discord.gg/HhUWfZ9cxe). This Discord server is focused on the
development of OpenDuelyst, and has channels for frontend, backend, and
infrastructure discussions, but it is open for anyone to join.

## Filing Issues and Reporting Bugs

If you encounter a bug and would like to report it, first check the
[Open Issues](https://github.com/open-duelyst/duelyst/issues/) to see if the
bug has already been reported. If not, feel free to create a new issue with the
`bug` label.

If you would like to request a technical feature or enhancement to the code,
you can create a new issue with the `enhancement` label.

Since OpenDuelyst is currently focused on recreating the game as it last
existed in v1.96.17, please avoid creating feature requests related to balance
changes.

## Localization

The game currently includes English and German localization. If you'd like to
contribute translations for another language, take a look at the
`app/localization/locales` directory. You can copy the `en` folder and start
updating strings for the new language, then submit a Pull Request with your
contribution.

There are about 4,500 localized strings, so this can also be done a little bit
at a time. Once the translations are in, we can help get the language included
in the game.

## Quick Start (Docker)

The fastest way to get OpenDuelyst running locally:

```bash
# One-command setup (installs dependencies, builds, and starts everything)
./scripts/setup-docker-dev.sh
```

This will:
- ✅ Install all dependencies
- ✅ Build the game
- ✅ Start Firebase Emulator (no Google account needed)
- ✅ Start all game services
- ✅ Open the game at http://localhost:3000

## Local Development with Firebase Emulator

For developers who want to avoid setting up a Google Firebase account, you can use the Firebase Emulator Suite to run a local Firebase Realtime Database. **The Docker setup now includes Firebase Emulator automatically!**

### Option 1: Docker Integration (Recommended)

The easiest way is to use the integrated Docker setup:

1. **Build and run everything with Docker:**
   ```bash
   # Install dependencies (if not already done)
   yarn install --dev
   yarn tsc:chroma-js
   
   # Build the game
   yarn build
   
   # Start all services including Firebase Emulator
   docker compose up
   ```

2. **Access the services:**
   - **Game**: http://localhost:3000
   - **Firebase Emulator UI**: http://localhost:4001
   - **Firebase Database**: http://localhost:9000

The Docker setup automatically:
- ✅ Installs Firebase CLI tools
- ✅ Creates firebase.json configuration
- ✅ Starts Firebase Emulator with persistent data
- ✅ Configures all services to use the local emulator
- ✅ Provides data persistence between restarts

### Option 2: Manual Setup (Alternative)

If you prefer to run Firebase Emulator outside Docker:

1. **Use the automated setup script:**
   ```bash
   ./scripts/setup-firebase-emulator.sh
   ./start-emulator.sh
   ```

2. **Or install manually:**
   ```bash
   npm install -g firebase-tools
   firebase emulators:start --only database
   ```

3. **Configure environment:**
   Create a `.env` file:
   ```bash
   FIREBASE_URL=http://localhost:9000/?ns=duelyst-local
   FIREBASE_LEGACY_TOKEN=fake-token-for-local-development
   ```

4. **Build and run:**
   ```bash
   cross-env FIREBASE_URL=http://localhost:9000/?ns=duelyst-local yarn build
   docker compose up
   ```

### Firebase Emulator Features

The Firebase Emulator provides:
- **Web UI** at http://localhost:4001 for debugging
- **Real-time database** at http://localhost:9000
- **Data persistence** - data survives container restarts
- **No Google account required** - completely local development

### Notes

- Docker setup uses persistent volumes for Firebase data
- All services automatically connect to the local emulator
- The fake legacy token works for local development but won't work with real Firebase
- If you need to reset Firebase data, remove the `firebase-data` Docker volume

## License

OpenDuelyst is licensed under the Creative Commons Zero v1.0 Universal license.
You can see a copy of the license [here](LICENSE).
